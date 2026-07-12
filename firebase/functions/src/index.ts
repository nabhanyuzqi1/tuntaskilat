/**
 * Cloud Functions — Tuntaskilat
 *
 * Safety-net layer: validasi harga, pembayaran, dan perhitungan upah
 * di sisi server. Logika utama sudah dijalankan di Firestore Transaction
 * client-side (firestore_service.dart); functions ini menjadi pertahanan
 * kedua agar data Firestore tidak bisa dimanipulasi via REST/SDK langsung.
 *
 * TA Bab IV 4.2.2 — Atomic Locking + Backend Validation.
 * AGENTS.md §2 aturan #3: "dihitung ulang & divalidasi di backend saat submit".
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ─────────────────────────────────────────────────────────── region Asia SE2
const REGION = "asia-southeast2";

/**
 * Persen komisi platform untuk sebuah layanan. Baca settings/komisi:
 * override `perLayanan[serviceId]` bila ada, jika tidak `komisiPersen` global,
 * default 20. Diklem 0–100. Sinkron dgn KonfigKomisi (Dart).
 */
async function komisiPersenUntuk(serviceId: string): Promise<number> {
  try {
    const snap = await db.collection("settings").doc("komisi").get();
    const d = snap.data() ?? {};
    const per = (d.perLayanan ?? {}) as Record<string, number>;
    const raw = serviceId in per ? per[serviceId] : (d.komisiPersen ?? 20);
    const n = Number(raw);
    if (!isFinite(n)) return 20;
    return Math.min(100, Math.max(0, n));
  } catch {
    return 20;
  }
}

// ─────────────────────────────────────── helpers
interface ServiceDoc {
  harga: number;
  namaLayanan: string;
  aktif: boolean;
  tipeHarga?: string;
  tiers?: Array<{ id: string; nama: string; hargaPerM2: number }>;
  paketOpsi?: Array<{
    id: string;
    nama: string;
    harga: number;
    addOnIds?: string[];
  }>;
  addOns?: Array<{ id: string; nama: string; harga: number }>;
}

/**
 * Hitung harga dari dokumen service.
 *
 * - Fixed pricing (TA): harga × kuantitas
 * - Dynamic pricing (produk): tergantung tipeHarga
 *
 * Mengembalikan harga yang seharusnya SEBELUM potongan voucher.
 */
function hitungHargaBackend(
  service: ServiceDoc,
  order: admin.firestore.DocumentData,
): number {
  const tipe = service.tipeHarga ?? "mulaiDari";
  const kuantitas = order.kuantitas ?? 1;

  if (tipe === "perLuas") {
    // Cari tier yang dipakai
    const rincian: unknown[] = order.rincian ?? [];
    if (rincian.length > 0 && service.tiers && service.tiers.length > 0) {
      // Tier pricing — subtotal dihitung dari tier × luas
      // Client menyimpan subtotal di field subtotal; kita hitung ulang
      const luas = order.luas ?? kuantitas;
      // Cari tier berdasarkan data rincian atau gunakan yang pertama
      const tier = service.tiers[0];
      return tier.hargaPerM2 * luas;
    }
    // Fallback ke harga dasar
    return service.harga * kuantitas;
  }

  if (tipe === "paket") {
    // Paket + add-ons
    const paketId: string = order.paketId ?? "";
    const addOnIds: string[] = order.addOnIds ?? [];
    const paket = (service.paketOpsi ?? []).find((p) => p.id === paketId);
    if (paket) {
      let total = paket.harga * kuantitas;
      for (const aoId of addOnIds) {
        const ao = (service.addOns ?? []).find((a) => a.id === aoId);
        if (ao) total += ao.harga * kuantitas;
      }
      return total;
    }
    // Fallback
    return service.harga * kuantitas;
  }

  // mulaiDari / fixed pricing (TA)
  return service.harga * kuantitas;
}

/**
 * Besar potongan MAKSIMUM yang sah dari sebuah voucher untuk sebuah subtotal —
 * mirror `VoucherModel.hitungPotongan` (Dart), TANPA gate kuota/masa-berlaku
 * (itu applicability, sudah dikunci transaction klien). Fungsi ini hanya
 * membatasi NOMINAL agar klien tak bisa mengklaim potongan lebih besar dari
 * formula voucher (mis. voucher Rp10.000 diklaim Rp89.000).
 */
function potonganFormulaVoucher(
  v: admin.firestore.DocumentData,
  subtotal: number,
): number {
  const minBelanja = Number(v.minBelanja ?? 0);
  if (subtotal < minBelanja) return 0;
  const tipe = String(v.tipe ?? "nominal");
  const nilai = Number(v.nilai ?? 0);
  let p = tipe === "persen" ? (subtotal * nilai) / 100 : nilai;
  const maxP = Number(v.maxPotongan ?? 0);
  if (tipe === "persen" && maxP > 0 && p > maxP) p = maxP;
  if (p > subtotal) p = subtotal;
  return Math.round(p);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ onOrderCreate
/**
 * Trigger: Firestore `onCreate` pada `orders/{orderId}`.
 *
 * Membaca ulang dokumen `services/{serviceId}` dan menghitung harga yang
 * benar. Jika `totalHarga` yang dikirim klien tidak cocok → dikoreksi
 * dan dicatat di log sebagai peringatan (potensi manipulasi).
 *
 * Skenario Black-Box #6: manipulasi harga → dihitung ulang backend.
 */
export const onOrderCreate = functions.firestore.onDocumentCreated(
  {
    document: "orders/{orderId}",
    region: REGION,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const order = snap.data();
    const orderId = event.params.orderId;
    const serviceId: string = order.serviceId ?? "";

    if (!serviceId) {
      functions.logger.warn(`[onOrderCreate] Order ${orderId} tanpa serviceId`);
      return;
    }

    // Baca dokumen service untuk hitung ulang harga
    const serviceSnap = await db.collection("services").doc(serviceId).get();
    if (!serviceSnap.exists) {
      functions.logger.error(
        `[onOrderCreate] Service ${serviceId} tidak ditemukan untuk ` +
          `order ${orderId}`,
      );
      return;
    }

    const service = serviceSnap.data() as ServiceDoc;
    const hargaBenar = hitungHargaBackend(service, order);

    // Hitung ulang potongan yang SAH dari dokumen voucher — jangan percaya
    // angka `potongan` dari klien. Klien tak boleh mengklaim potongan lebih
    // besar dari formula voucher, dan tanpa voucher valid tak ada potongan.
    const kode = String(order.voucherKode ?? "").trim().toUpperCase();
    const potonganKlien = Number(order.potongan ?? 0);
    let potonganBenar = 0;
    if (kode && potonganKlien > 0) {
      const vSnap = await db.collection("vouchers").doc(kode).get();
      potonganBenar = vSnap.exists ?
        Math.min(
          Math.max(0, potonganKlien),
          potonganFormulaVoucher(vSnap.data()!, hargaBenar),
        ) :
        0;
    }

    const subtotalOrder: number = order.subtotal ?? order.totalHarga ?? 0;
    const totalBenar = hargaBenar - potonganBenar;

    // Bandingkan — toleransi pembulatan 1 Rupiah
    const totalKlien: number = order.totalHarga ?? 0;
    const selisihTotal = Math.abs(totalKlien - totalBenar);
    const selisihPotongan = Math.abs(potonganKlien - potonganBenar);
    const selisihSubtotal =
      subtotalOrder > 0 ? Math.abs(subtotalOrder - hargaBenar) : 0;

    if (selisihTotal > 1 || selisihPotongan > 1 || selisihSubtotal > 1) {
      functions.logger.warn(
        `[onOrderCreate] ⚠️ NILAI TIDAK COCOK — order ${orderId}: ` +
          `total klien=${totalKlien} seharusnya=${totalBenar}, ` +
          `potongan klien=${potonganKlien} seharusnya=${potonganBenar}. ` +
          "DIKOREKSI.",
      );
      await snap.ref.update({
        totalHarga: totalBenar,
        hargaSatuan: service.harga,
        subtotal: hargaBenar,
        potongan: potonganBenar,
      });
    } else {
      functions.logger.info(
        `[onOrderCreate] ✓ Order ${orderId} nilai valid: ${totalKlien}`,
      );
    }
  },
);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ validatePayment
/**
 * Trigger: Firestore `onCreate` pada `payments/{paymentId}`.
 *
 * Memastikan `jumlah` pada dokumen pembayaran cocok dengan `totalHarga`
 * di dokumen `orders` yang direferensikan.
 */
export const validatePayment = functions.firestore.onDocumentCreated(
  {
    document: "payments/{paymentId}",
    region: REGION,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const payment = snap.data();
    const paymentId = event.params.paymentId;
    const orderId: string = payment.orderId ?? "";

    if (!orderId) {
      functions.logger.warn(
        `[validatePayment] Payment ${paymentId} tanpa orderId`,
      );
      return;
    }

    const orderSnap = await db.collection("orders").doc(orderId).get();
    if (!orderSnap.exists) {
      functions.logger.error(
        `[validatePayment] Order ${orderId} tidak ditemukan ` +
          `untuk payment ${paymentId}`,
      );
      return;
    }

    const order = orderSnap.data()!;
    const jumlahBayar: number = payment.jumlah ?? 0;
    const totalHarga: number = order.totalHarga ?? 0;
    const selisih = Math.abs(jumlahBayar - totalHarga);

    if (selisih > 1) {
      functions.logger.warn(
        `[validatePayment] ⚠️ JUMLAH BAYAR TIDAK COCOK — payment ${paymentId}: ` +
          `bayar=${jumlahBayar}, order=${totalHarga}. DIKOREKSI.`,
      );
      await snap.ref.update({jumlah: totalHarga});
    } else {
      functions.logger.info(
        `[validatePayment] ✓ Payment ${paymentId} valid: ${jumlahBayar}`,
      );
    }
  },
);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ onOrderFinalize
/**
 * Trigger: Firestore `onUpdate` pada `orders/{orderId}`.
 *
 * Saat status berubah ke `selesai` (K4 laporan kerja):
 * - Hitung payout per kru berdasarkan penugasan & peran
 * - Buat dokumen `payouts/{orderId}_{cleanerId}` jika belum ada
 *
 * Ini melengkapi logika di `submitLaporanKerja` (client-side) sebagai
 * second-pass validation: jika klien sudah membuat payout dengan benar,
 * function ini hanya memverifikasi. Jika tidak ada, function membuatnya.
 */
export const onOrderFinalize = functions.firestore.onDocumentUpdated(
  {
    document: "orders/{orderId}",
    region: REGION,
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const orderId = event.params.orderId;

    // Hanya proses jika status baru saja berubah ke 'selesai'
    if (before.status === "selesai" || after.status !== "selesai") return;

    const totalHarga: number = after.totalHarga ?? 0;
    const penugasan: Array<{
      cleanerId: string;
      nama: string;
      peran: string;
    }> = after.penugasan ?? [];
    const cleanerId: string = after.cleanerId ?? "";
    const serviceId: string = after.serviceId ?? "";

    // Konfigurasi komisi dari settings/komisi (global + override per layanan).
    const KOMISI_PERSEN = await komisiPersenUntuk(serviceId);
    const RASIO_HELPER = 0.6; // helper dapat 60% dari bagian worker

    if (penugasan.length > 0) {
      // Multi-worker: bagi upah berdasarkan peran
      const bersih = totalHarga * (1 - KOMISI_PERSEN / 100);
      const jumlahWorker = penugasan.filter((p) => p.peran === "worker").length;
      const jumlahHelper = penugasan.filter((p) => p.peran === "helper").length;
      const bobot = jumlahWorker + jumlahHelper * RASIO_HELPER;

      for (const p of penugasan) {
        const payoutId = `${orderId}_${p.cleanerId}`;
        const payoutRef = db.collection("payouts").doc(payoutId);
        const existing = await payoutRef.get();

        const rasio = p.peran === "helper" ? RASIO_HELPER : 1;
        const bagian = bobot > 0 ? Math.round((bersih * rasio) / bobot) : 0;

        if (!existing.exists) {
          functions.logger.info(
            `[onOrderFinalize] Membuat payout ${payoutId}: Rp${bagian}`,
          );
          await payoutRef.set({
            payoutId,
            orderId,
            cleanerId: p.cleanerId,
            namaKru: p.nama,
            peran: p.peran,
            jumlah: bagian,
            status: "pending",
            waktu: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          // Verifikasi jumlah existing
          const existingData = existing.data()!;
          const existingJumlah: number = existingData.jumlah ?? 0;
          if (Math.abs(existingJumlah - bagian) > 1) {
            functions.logger.warn(
              `[onOrderFinalize] ⚠️ Payout ${payoutId} jumlah dikoreksi: ` +
                `${existingJumlah} → ${bagian}`,
            );
            await payoutRef.update({jumlah: bagian});
          }
        }
      }
    } else if (cleanerId) {
      // Single cleaner (fallback TA / pesanan lama)
      const payoutId = `${orderId}_${cleanerId}`;
      const payoutRef = db.collection("payouts").doc(payoutId);
      const existing = await payoutRef.get();
      const komisi = Math.round((totalHarga * KOMISI_PERSEN) / 100);
      const bagian = totalHarga - komisi;

      if (!existing.exists) {
        functions.logger.info(
          `[onOrderFinalize] Membuat payout single ${payoutId}: Rp${bagian}`,
        );
        await payoutRef.set({
          payoutId,
          orderId,
          cleanerId,
          namaKru: after.namaKru ?? "Kru",
          peran: "worker",
          jumlah: bagian,
          status: "pending",
          waktu: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    // Pembukuan kas tunai: bila order dibayar TUNAI, komisi platform dipegang
    // kru (lead) dan wajib disetor → kasKru.saldoTunai += komisi. Idempoten:
    // hanya saat transisi masuk 'selesai' (fungsi ini fire sekali per transisi)
    // dan diproteksi flag `kasTunaiDibukukan` pada order.
    if (
      after.metodePembayaran === "tunai" &&
      after.kasTunaiDibukukan !== true
    ) {
      const penugasanArr = penugasan;
      const leadId =
        penugasanArr.length > 0 ? penugasanArr[0].cleanerId : cleanerId;
      const leadNama =
        penugasanArr.length > 0
          ? penugasanArr[0].nama
          : after.namaKru ?? "Kru";
      if (leadId) {
        const komisiTunai = Math.round((totalHarga * KOMISI_PERSEN) / 100);
        const kasRef = db.collection("kasKru").doc(leadId);
        const orderRef = db.collection("orders").doc(orderId);
        await db.runTransaction(async (tx) => {
          const kasSnap = await tx.get(kasRef);
          const ordSnap = await tx.get(orderRef);
          if (ordSnap.data()?.kasTunaiDibukukan === true) return; // guard ganda
          const d = kasSnap.data() ?? {};
          const saldo = Number(d.saldoTunai ?? 0);
          const masuk = Number(d.totalMasuk ?? 0);
          tx.set(
            kasRef,
            {
              cleanerId: leadId,
              namaKru: d.namaKru || leadNama,
              saldoTunai: saldo + komisiTunai,
              batasNunggak: Number(d.batasNunggak ?? 200000),
              totalMasuk: masuk + komisiTunai,
              totalSetor: Number(d.totalSetor ?? 0),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            {merge: true},
          );
          tx.update(orderRef, {kasTunaiDibukukan: true});
        });
        functions.logger.info(
          `[onOrderFinalize] Kas tunai ${leadId} +Rp${komisiTunai}`,
        );
      }
    }

    functions.logger.info(
      `[onOrderFinalize] ✓ Order ${orderId} selesai diproses.`,
    );
  },
);

/**
 * Push FCM ke kru saat order ditugaskan (status → 'ditugaskan').
 * Membaca fcmTokens tiap kru pada dokumen `kru/{id}` lalu mengirim notifikasi.
 * Token yang tak valid dibersihkan otomatis.
 */
export const onOrderAssigned = functions.firestore.onDocumentUpdated(
  {document: "orders/{orderId}", region: REGION},
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === "ditugaskan" || after.status !== "ditugaskan") return;

    const kruIds: string[] = after.kruIds ?? [];
    if (kruIds.length === 0) return;

    const judul = "Tugas baru untuk Anda";
    const isi = `${after.namaLayanan ?? "Pesanan"} — ${after.alamatLayanan ?? ""}`;

    for (const id of kruIds) {
      const kruSnap = await db.collection("kru").doc(id).get();
      const tokens: string[] = kruSnap.data()?.fcmTokens ?? [];
      if (tokens.length === 0) continue;

      const res = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {title: judul, body: isi},
        data: {orderId: event.params.orderId, tipe: "tugas_baru"},
        android: {
          priority: "high",
          notification: {channelId: "tk_high_importance_channel_v2"},
        },
      });

      // Bersihkan token invalid.
      const invalid: string[] = [];
      res.responses.forEach((r, i) => {
        if (!r.success) {
          const code = r.error?.code ?? "";
          if (
            code.includes("registration-token-not-registered") ||
            code.includes("invalid-argument")
          ) {
            invalid.push(tokens[i]);
          }
        }
      });
      if (invalid.length > 0) {
        await db.collection("kru").doc(id).update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalid),
        });
      }
      functions.logger.info(
        `[onOrderAssigned] Push ke kru ${id}: ${res.successCount}/${tokens.length}`,
      );
    }
  },
);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ helper push umum
/**
 * Ambil token FCM milik sebuah uid dari `users` DAN `kru` (uid bisa pelanggan
 * atau kru). Kembalikan pasangan token+koleksi asal untuk pembersihan token
 * invalid yang tepat sasaran.
 */
async function tokensUntuk(
  uid: string,
): Promise<Array<{token: string; col: "users" | "kru"}>> {
  const out: Array<{token: string; col: "users" | "kru"}> = [];
  const [u, k] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("kru").doc(uid).get(),
  ]);
  for (const t of (u.data()?.fcmTokens ?? []) as string[]) {
    out.push({token: t, col: "users"});
  }
  for (const t of (k.data()?.fcmTokens ?? []) as string[]) {
    out.push({token: t, col: "kru"});
  }
  return out;
}

/** Kirim push FCM ke satu uid; bersihkan token invalid dari koleksi asalnya. */
async function pushKeUid(
  uid: string,
  judul: string,
  isi: string,
  data: Record<string, string>,
): Promise<void> {
  const list = await tokensUntuk(uid);
  if (list.length === 0) return;
  const res = await admin.messaging().sendEachForMulticast({
    tokens: list.map((x) => x.token),
    notification: {title: judul, body: isi},
    data,
    android: {
      priority: "high",
      notification: {channelId: "tk_high_importance_channel_v2"},
    },
  });
  const rm: Record<"users" | "kru", string[]> = {users: [], kru: []};
  res.responses.forEach((r, i) => {
    if (!r.success) {
      const code = r.error?.code ?? "";
      if (
        code.includes("registration-token-not-registered") ||
        code.includes("invalid-argument")
      ) {
        rm[list[i].col].push(list[i].token);
      }
    }
  });
  await Promise.all(
    (["users", "kru"] as const).map((col) =>
      rm[col].length > 0 ?
        db.collection(col).doc(uid).update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...rm[col]),
        }) :
        Promise.resolve(),
    ),
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ onChatMessageCreate
/**
 * Trigger: `onCreate` pada `orders/{orderId}/messages/{messageId}`.
 *
 * Saat salah satu pihak mengirim pesan chat, buat notifikasi in-app untuk
 * penerima (badge + daftar P12/notifikasi) DAN kirim push FCM. Penerima
 * ditentukan dari senderId: bila pengirim = pelanggan (order.userId) →
 * kirim ke semua kru tertugas; selain itu (kru) → kirim ke pelanggan.
 */
export const onChatMessageCreate = functions.firestore.onDocumentCreated(
  {document: "orders/{orderId}/messages/{messageId}", region: REGION},
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const msg = snap.data();
    const orderId = event.params.orderId;
    const senderId: string = msg.senderId ?? "";
    const text = String(msg.text ?? "").trim();
    if (!text || !senderId) return;

    const orderSnap = await db.collection("orders").doc(orderId).get();
    const order = orderSnap.data();
    if (!order) return;

    const userId: string = order.userId ?? "";
    const kruIds: string[] = (
      order.kruIds ?? (order.cleanerId ? [order.cleanerId] : [])
    ).filter((x: string) => !!x);

    const cuplik = text.length > 120 ? text.slice(0, 117) + "…" : text;

    let recipients: string[] = [];
    let judul = "";
    if (senderId === userId) {
      // pelanggan → kru
      recipients = kruIds;
      judul = `Pesan dari ${order.namaPelanggan ?? "pelanggan"}`;
    } else {
      // kru → pelanggan
      recipients = userId ? [userId] : [];
      const penugasan: Array<{cleanerId: string; nama: string}> =
        order.penugasan ?? [];
      const namaKru =
        penugasan.find((p) => p.cleanerId === senderId)?.nama ??
        order.namaKru ??
        "kru";
      judul = `Pesan dari ${namaKru}`;
    }

    for (const rid of recipients) {
      if (!rid || rid === senderId) continue;
      const notifRef = db.collection("notifications").doc();
      await notifRef.set({
        notificationId: notifRef.id,
        userId: rid,
        judul,
        pesan: cuplik,
        waktu: admin.firestore.Timestamp.now(),
        dibaca: false,
        orderId,
        tipe: "chat",
      });
      await pushKeUid(rid, judul, cuplik, {orderId, tipe: "chat"});
    }
    functions.logger.info(
      `[onChatMessageCreate] ${orderId}: ${senderId} → ` +
        `${recipients.join(",") || "(none)"}`,
    );
  },
);

/**
 * Pengingat kru ~2 jam sebelum jadwal. Berjalan tiap 30 menit (cron),
 * mencari order 'ditugaskan' yang jadwalnya 90-150 menit lagi lalu push.
 */
export const reminderKru = functions.scheduler.onSchedule(
  {schedule: "every 30 minutes", region: REGION, timeZone: "Asia/Makassar"},
  async () => {
    const now = Date.now();
    const dari = admin.firestore.Timestamp.fromMillis(now + 90 * 60 * 1000);
    const sampai = admin.firestore.Timestamp.fromMillis(now + 150 * 60 * 1000);

    const snap = await db
      .collection("orders")
      .where("status", "==", "ditugaskan")
      .where("jadwal", ">=", dari)
      .where("jadwal", "<=", sampai)
      .get();

    for (const doc of snap.docs) {
      const o = doc.data();
      const kruIds: string[] = o.kruIds ?? [];
      for (const id of kruIds) {
        const tokens: string[] =
          (await db.collection("kru").doc(id).get()).data()?.fcmTokens ?? [];
        if (tokens.length === 0) continue;
        await admin.messaging().sendEachForMulticast({
          tokens,
          notification: {
            title: "Pengingat tugas",
            body: `Sebentar lagi: ${o.namaLayanan ?? "pesanan"} di ${
              o.alamatLayanan ?? ""
            }`,
          },
          data: {orderId: doc.id, tipe: "reminder"},
          android: {
            priority: "high",
            notification: {channelId: "tk_high_importance_channel_v2"},
          },
        });
      }
    }
    functions.logger.info(`[reminderKru] ${snap.size} order diingatkan.`);
  },
);

// ═══════════════════════════════════════════════ Manajemen Tim Admin (A#2)

/** Pastikan pemanggil adalah admin (baca users.role). */
async function pastikanAdmin(uid: string | undefined): Promise<void> {
  if (!uid) throw new functions.https.HttpsError("unauthenticated", "Harus login.");
  const snap = await db.collection("users").doc(uid).get();
  if (snap.data()?.role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Hanya admin.");
  }
}

/**
 * Buat akun admin baru (callable, admin-only). Membuat user Auth + dokumen
 * users role=admin — tanpa mengeluarkan admin yang sedang login (beda dgn
 * createUserWithEmailAndPassword di klien).
 */
export const buatAdmin = functions.https.onCall(
  {region: REGION},
  async (req) => {
    await pastikanAdmin(req.auth?.uid);
    const email = String(req.data?.email ?? "").trim();
    const password = String(req.data?.password ?? "");
    const nama = String(req.data?.nama ?? "").trim();
    if (!email || password.length < 8) {
      throw new functions.https.HttpsError(
        "invalid-argument", "Email valid & kata sandi min 8 karakter wajib.");
    }
    let user;
    try {
      user = await admin.auth().createUser({email, password, displayName: nama});
    } catch (e) {
      const code = (e as {code?: string}).code ?? "";
      if (code === "auth/email-already-exists") {
        throw new functions.https.HttpsError("already-exists", "Email sudah terdaftar.");
      }
      if (code === "auth/invalid-password" || code === "auth/invalid-email") {
        throw new functions.https.HttpsError("invalid-argument", "Email atau kata sandi tidak valid.");
      }
      throw new functions.https.HttpsError("internal", "Gagal membuat akun.");
    }
    await db.collection("users").doc(user.uid).set({
      userId: user.uid,
      nama,
      email,
      noTelepon: "",
      alamat: "",
      role: "admin",
      fotoUrl: "",
      nonaktif: false,
    });
    functions.logger.info(`[buatAdmin] admin baru ${email} oleh ${req.auth?.uid}`);
    return {uid: user.uid};
  },
);

/**
 * Aktif/nonaktifkan akun admin (callable, admin-only). Menonaktifkan =
 * disable Auth + flag nonaktif. Tak bisa menonaktifkan diri sendiri.
 */
export const setNonaktifAdmin = functions.https.onCall(
  {region: REGION},
  async (req) => {
    await pastikanAdmin(req.auth?.uid);
    const target = String(req.data?.uid ?? "");
    const nonaktif = req.data?.nonaktif === true;
    if (!target) {
      throw new functions.https.HttpsError("invalid-argument", "uid wajib.");
    }
    if (target === req.auth?.uid) {
      throw new functions.https.HttpsError(
        "failed-precondition", "Tidak bisa menonaktifkan akun sendiri.");
    }
    await admin.auth().updateUser(target, {disabled: nonaktif});
    await db.collection("users").doc(target).update({nonaktif});
    return {ok: true};
  },
);

// ═════════════════════════════════════════════════════ Referal (A#4)

/** Normalisasi nomor telepon: 0xxxx → 62xxxx, buang non-digit. */
function normalTelp(t: string): string {
  const d = (t ?? "").replace(/[^0-9]/g, "");
  if (d.startsWith("0")) return "62" + d.slice(1);
  return d;
}

/** Kode voucher acak REF + 6 char base32 (tanpa 0/1/O/I). */
function kodeVoucherReferal(): string {
  const abjad = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let s = "REF";
  for (let i = 0; i < 6; i++) {
    s += abjad[Math.floor(Math.random() * abjad.length)];
  }
  return s;
}

/**
 * Reward referal: saat order pertama pelanggan SELESAI dan ia mendaftar dengan
 * `referredBy`, terbitkan voucher hadiah untuk PENGUNDANG (pemilik kodeReferal).
 * Anti-abuse: dikunci per NOMOR TELEPON pelanggan (`referralClaims/{telp}`) —
 * daftar ulang dengan nomor sama tak bisa klaim lagi. Idempoten via klaim.
 */
export const rewardReferral = functions.firestore.onDocumentUpdated(
  {document: "orders/{orderId}", region: REGION},
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === "selesai" || after.status !== "selesai") return;

    const buyerId: string = after.userId ?? "";
    if (!buyerId) return;

    const buyerSnap = await db.collection("users").doc(buyerId).get();
    const buyer = buyerSnap.data();
    const referredBy = String(buyer?.referredBy ?? "").toUpperCase();
    if (!buyer || !referredBy) return;

    const telp = normalTelp(String(buyer.noTelepon ?? ""));
    if (!telp) return;

    // Konfigurasi reward (settings/referral) — default Rp20.000.
    const cfgSnap = await db.collection("settings").doc("referral").get();
    const cfg = cfgSnap.data() ?? {};
    const nominal = Number(cfg.nominal ?? 20000);
    const minBelanja = Number(cfg.minBelanja ?? 0);
    const masaHari = Number(cfg.masaBerlakuHari ?? 90);

    const claimRef = db.collection("referralClaims").doc(telp);
    const voucherKode = kodeVoucherReferal();
    const voucherRef = db.collection("vouchers").doc(voucherKode);

    // Cari pengundang by kodeReferal.
    const refQ = await db
      .collection("users")
      .where("kodeReferal", "==", referredBy)
      .limit(1)
      .get();
    if (refQ.empty) return;
    const referrer = refQ.docs[0];
    if (referrer.id === buyerId) return; // tak bisa mereferal diri sendiri

    const berlaku = new Date();
    berlaku.setDate(berlaku.getDate() + masaHari);

    try {
      await db.runTransaction(async (tx) => {
        const claim = await tx.get(claimRef);
        if (claim.exists) return; // sudah pernah klaim untuk nomor ini
        tx.set(claimRef, {
          telepon: telp,
          buyerId,
          referrerId: referrer.id,
          kodeReferal: referredBy,
          voucherKode,
          waktu: admin.firestore.FieldValue.serverTimestamp(),
        });
        tx.set(voucherRef, {
          kode: voucherKode,
          tipe: "nominal",
          nilai: nominal,
          deskripsi: `Hadiah referal dari ${buyer.nama ?? "teman"}`,
          minBelanja,
          maxPotongan: 0,
          kuota: 1,
          terpakai: 0,
          berlakuHingga: berlaku.toISOString(),
          aktif: true,
          khususPenggunaBaru: false,
          sekaliPerNomor: true,
        });
        const notifRef = db.collection("notifications").doc();
        tx.set(notifRef, {
          notificationId: notifRef.id,
          userId: referrer.id,
          judul: "Hadiah referal untuk Anda! 🎉",
          pesan:
            `Teman yang Anda undang menyelesaikan pesanan pertamanya. ` +
            `Pakai kode ${voucherKode} untuk potongan Rp${nominal}.`,
          waktu: admin.firestore.Timestamp.now(),
          dibaca: false,
        });
      });
      functions.logger.info(
        `[rewardReferral] voucher ${voucherKode} → ${referrer.id} ` +
          `(referred ${buyerId})`,
      );
    } catch (e) {
      functions.logger.error(`[rewardReferral] gagal: ${e}`);
    }
  },
);

// ═══════════════════════════════════════════════ WA Fonnte (A#8)

/**
 * Abstraksi pengirim WhatsApp. Implementasi aktif memakai Fonnte; ganti kelas
 * ini bila pindah vendor (Twilio, dsb.) tanpa menyentuh pemanggil.
 */
interface WaSender {
  kirim(target: string, pesan: string): Promise<boolean>;
}

/** Pengirim WA via Fonnte. Token dari env FONNTE_TOKEN (functions/.env). */
class FonnteSender implements WaSender {
  async kirim(target: string, pesan: string): Promise<boolean> {
    const token = process.env.FONNTE_TOKEN ?? "";
    if (!token) {
      functions.logger.warn("[wa] FONNTE_TOKEN belum diset — WA dilewati.");
      return false;
    }
    const t = normalTelp(target);
    if (!t) return false;
    try {
      const body = new URLSearchParams({target: t, message: pesan});
      const res = await fetch("https://api.fonnte.com/send", {
        method: "POST",
        headers: {Authorization: token},
        body,
      });
      if (!res.ok) {
        functions.logger.error(`[wa] Fonnte ${res.status} → ${t}`);
        return false;
      }
      return true;
    } catch (e) {
      functions.logger.error(`[wa] gagal kirim: ${e}`);
      return false;
    }
  }
}

const waSender: WaSender = new FonnteSender();

/**
 * Notifikasi WhatsApp ke pelanggan pada transisi status penting. No-op bila
 * FONNTE_TOKEN belum diset (aman untuk lingkungan tanpa kredensial WA).
 */
export const waNotifOrder = functions.firestore.onDocumentUpdated(
  {document: "orders/{orderId}", region: REGION},
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;

    const telp = after.teleponPelanggan ?? "";
    if (!telp) return;
    const nama = after.namaPelanggan ?? "Pelanggan";
    const layanan = after.namaLayanan ?? "layanan";

    let pesan: string | null = null;
    switch (after.status) {
      case "terverifikasi":
        pesan =
          `Halo ${nama}, pembayaran untuk *${layanan}* sudah kami verifikasi. ` +
          `Kru akan segera ditugaskan. Terima kasih — Tuntaskilat.`;
        break;
      case "ditugaskan":
        pesan =
          `Halo ${nama}, kru untuk *${layanan}* sudah ditugaskan dan akan ` +
          `datang sesuai jadwal. Pantau di aplikasi Tuntaskilat.`;
        break;
      case "selesai":
        pesan =
          `Halo ${nama}, pesanan *${layanan}* telah selesai. Terima kasih ` +
          `telah memakai Tuntaskilat! Beri ulasan Anda di aplikasi ya.`;
        break;
      default:
        return;
    }
    if (pesan) await waSender.kirim(telp, pesan);
  },
);

// ═══════════════════════════════════ Slot bebas saat batal (UX #1)
/**
 * Saat order berpindah ke `dibatalkan`, HAPUS dokumen kunci `slots/{slotId}`
 * agar jadwal bisa dipesan pelanggan lain. slotId dari field order (order
 * baru) atau = orderId (order lama pra-pemisahan ID).
 */
export const onOrderCancelled = functions.firestore.onDocumentUpdated(
  {document: "orders/{orderId}", region: REGION},
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === "dibatalkan" || after.status !== "dibatalkan") {
      return;
    }
    const slotId = String(after.slotId ?? event.params.orderId);
    await db.collection("slots").doc(slotId).delete();
    functions.logger.info(
      `[onOrderCancelled] slot ${slotId} dibebaskan (order ` +
        `${event.params.orderId}).`,
    );
  },
);

// ═══════════════════════════════════ Push status order ke pelanggan (#4)
/**
 * Push FCM ke PELANGGAN pada transisi status penting (melengkapi notifikasi
 * in-app yang ditulis klien/admin & WA Fonnte). data.tipe='status' →
 * deep-link ke P8 Lacak Pesanan.
 */
export const pushStatusPelanggan = functions.firestore.onDocumentUpdated(
  {document: "orders/{orderId}", region: REGION},
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;
    const userId: string = after.userId ?? "";
    if (!userId) return;

    const layanan = after.namaLayanan ?? "Pesanan";
    let judul: string | null = null;
    let isi = "";
    switch (after.status) {
      case "terverifikasi":
        judul = "Pembayaran terverifikasi";
        isi = `${layanan} dikonfirmasi & sedang dijadwalkan.`;
        break;
      case "ditugaskan":
        judul = "Kru ditugaskan";
        isi = `${after.namaKru ?? "Kru"} akan datang sesuai jadwal Anda.`;
        break;
      case "dalam_perjalanan":
        judul = "Kru dalam perjalanan";
        isi = `${after.namaKru ?? "Kru"} sedang menuju lokasi Anda.`;
        break;
      case "dikerjakan":
        judul = "Pengerjaan dimulai";
        isi = `${layanan} sedang dikerjakan.`;
        break;
      case "selesai":
        judul = "Pesanan selesai";
        isi = "Terima kasih! Jangan lupa beri ulasan untuk kru Anda.";
        break;
      case "ditolak":
        judul = "Pembayaran perlu diunggah ulang";
        isi =
          "Bukti transfer belum terverifikasi. Buka aplikasi untuk " +
          "unggah ulang.";
        break;
      default:
        return;
    }
    await pushKeUid(userId, judul, isi, {
      orderId: event.params.orderId,
      tipe: "status",
    });
  },
);

// ═══════════════════════════════════ Broadcast marketing (#4)
/**
 * Push promo massal: admin membuat dokumen `broadcasts/{id}`
 * {judul, pesan} → dikirim ke SEMUA pelanggan yang punya token FCM. Hasil
 * (terkirim/tanpaToken) ditulis balik ke dokumen. Create admin-only (rules);
 * function berjalan dengan admin SDK.
 */
export const onBroadcastCreate = functions.firestore.onDocumentCreated(
  {document: "broadcasts/{id}", region: REGION},
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const b = snap.data();
    const judul = String(b.judul ?? "").trim();
    const pesan = String(b.pesan ?? "").trim();
    if (!judul || !pesan) return;

    const users = await db
      .collection("users")
      .where("role", "==", "pelanggan")
      .get();
    let terkirim = 0;
    let tanpaToken = 0;
    for (const u of users.docs) {
      const tokens: string[] = u.data().fcmTokens ?? [];
      if (tokens.length === 0) {
        tanpaToken++;
        continue;
      }
      const res = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {title: judul, body: pesan},
        data: {tipe: "promo"},
        android: {
          priority: "high",
          notification: {channelId: "tk_high_importance_channel_v2"},
        },
      });
      terkirim += res.successCount;
    }
    await snap.ref.update({
      terkirim,
      tanpaToken,
      selesaiPada: admin.firestore.FieldValue.serverTimestamp(),
    });
    functions.logger.info(
      `[onBroadcastCreate] "${judul}": ${terkirim} push, ` +
        `${tanpaToken} user tanpa token.`,
    );
  },
);

// ═══════════════════════════════════ Rating anti-manipulasi (#5)
/**
 * Server-authoritative rating: setiap kali review DIBUAT, hitung ulang
 * rataRating & jumlahUlasan kru dari SELURUH koleksi `reviews` miliknya lalu
 * timpa dokumen kru. Manipulasi via REST (mis. set rataRating 5.0 langsung)
 * terkoreksi otomatis; rules tetap gerbang pertama.
 */
export const onReviewCreate = functions.firestore.onDocumentCreated(
  {document: "reviews/{reviewId}", region: REGION},
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const cleanerId = String(snap.data().cleanerId ?? "");
    if (!cleanerId) return;

    const q = await db
      .collection("reviews")
      .where("cleanerId", "==", cleanerId)
      .get();
    let total = 0;
    let n = 0;
    for (const d of q.docs) {
      const nilai = Number(d.data().penilaian ?? 0);
      if (nilai > 0) {
        total += nilai;
        n++;
      }
    }
    const rata = n > 0 ? Math.round((total / n) * 10) / 10 : 0;
    await db.collection("kru").doc(cleanerId).set(
      {rataRating: rata, jumlahUlasan: n},
      {merge: true},
    );
    functions.logger.info(
      `[onReviewCreate] kru ${cleanerId}: rata=${rata} n=${n} (recomputed).`,
    );
  },
);

// ═══════════════════════════════════════════════ Xendit webhook (A#7, stub)

/**
 * Webhook Xendit (VA/QRIS dinamis) — STUB defensif. Aktif hanya bila
 * XENDIT_CALLBACK_TOKEN diset; jika belum, balas 501 (belum diaktifkan).
 * Saat aktif: verifikasi header x-callback-token, tandai payment & order
 * terverifikasi berdasarkan external_id = orderId.
 */
export const xenditWebhook = functions.https.onRequest(
  {region: REGION},
  async (req, res) => {
    const expected = process.env.XENDIT_CALLBACK_TOKEN ?? "";
    if (!expected) {
      res.status(501).send("Xendit belum diaktifkan.");
      return;
    }
    if (req.get("x-callback-token") !== expected) {
      res.status(401).send("Token callback tidak valid.");
      return;
    }
    const body = req.body ?? {};
    const orderId: string = body.external_id ?? "";
    const status: string = body.status ?? "";
    if (!orderId) {
      res.status(400).send("external_id kosong.");
      return;
    }
    if (status === "PAID" || status === "SETTLED") {
      const payQ = await db
        .collection("payments")
        .where("orderId", "==", orderId)
        .limit(1)
        .get();
      if (!payQ.empty) {
        await payQ.docs[0].ref.update({statusBayar: "terverifikasi"});
      }
      await db.collection("orders").doc(orderId).update({
        status: "terverifikasi",
      });
      functions.logger.info(`[xenditWebhook] order ${orderId} PAID`);
    }
    res.status(200).send("OK");
  },
);
