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

    // Hitung total setelah potongan voucher (jika ada)
    const potongan: number = order.potongan ?? 0;
    const subtotalOrder: number = order.subtotal ?? order.totalHarga ?? 0;
    const totalBenar = hargaBenar - potongan;

    // Bandingkan — toleransi pembulatan 1 Rupiah
    const totalKlien: number = order.totalHarga ?? 0;
    const selisih = Math.abs(totalKlien - totalBenar);

    if (selisih > 1) {
      functions.logger.warn(
        `[onOrderCreate] ⚠️ HARGA TIDAK COCOK — order ${orderId}: ` +
          `klien=${totalKlien}, seharusnya=${totalBenar}, selisih=${selisih}. ` +
          `DIKOREKSI.`,
      );

      // Koreksi harga di Firestore
      const updates: Record<string, unknown> = {
        totalHarga: totalBenar,
        hargaSatuan: service.harga,
      };
      // Koreksi subtotal jika ada selisih juga
      if (
        subtotalOrder > 0 &&
        Math.abs(subtotalOrder - hargaBenar) > 1
      ) {
        updates.subtotal = hargaBenar;
      }
      await snap.ref.update(updates);
    } else {
      functions.logger.info(
        `[onOrderCreate] ✓ Order ${orderId} harga valid: ${totalKlien}`,
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

    // Konfigurasi upah default (sinkron dengan KonfigUpah di Dart)
    const KOMISI_PERSEN = 20;
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
          notification: {channelId: "tk_high_importance_channel"},
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
            notification: {channelId: "tk_high_importance_channel"},
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
