"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.onOrderFinalize = exports.validatePayment = exports.onOrderCreate = void 0;
const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
// ─────────────────────────────────────────────────────────── region Asia SE2
const REGION = "asia-southeast2";
/**
 * Hitung harga dari dokumen service.
 *
 * - Fixed pricing (TA): harga × kuantitas
 * - Dynamic pricing (produk): tergantung tipeHarga
 *
 * Mengembalikan harga yang seharusnya SEBELUM potongan voucher.
 */
function hitungHargaBackend(service, order) {
    const tipe = service.tipeHarga ?? "mulaiDari";
    const kuantitas = order.kuantitas ?? 1;
    if (tipe === "perLuas") {
        // Cari tier yang dipakai
        const rincian = order.rincian ?? [];
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
        const paketId = order.paketId ?? "";
        const addOnIds = order.addOnIds ?? [];
        const paket = (service.paketOpsi ?? []).find((p) => p.id === paketId);
        if (paket) {
            let total = paket.harga * kuantitas;
            for (const aoId of addOnIds) {
                const ao = (service.addOns ?? []).find((a) => a.id === aoId);
                if (ao)
                    total += ao.harga * kuantitas;
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
exports.onOrderCreate = functions.firestore.onDocumentCreated({
    document: "orders/{orderId}",
    region: REGION,
}, async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const order = snap.data();
    const orderId = event.params.orderId;
    const serviceId = order.serviceId ?? "";
    if (!serviceId) {
        functions.logger.warn(`[onOrderCreate] Order ${orderId} tanpa serviceId`);
        return;
    }
    // Baca dokumen service untuk hitung ulang harga
    const serviceSnap = await db.collection("services").doc(serviceId).get();
    if (!serviceSnap.exists) {
        functions.logger.error(`[onOrderCreate] Service ${serviceId} tidak ditemukan untuk ` +
            `order ${orderId}`);
        return;
    }
    const service = serviceSnap.data();
    const hargaBenar = hitungHargaBackend(service, order);
    // Hitung total setelah potongan voucher (jika ada)
    const potongan = order.potongan ?? 0;
    const subtotalOrder = order.subtotal ?? order.totalHarga ?? 0;
    const totalBenar = hargaBenar - potongan;
    // Bandingkan — toleransi pembulatan 1 Rupiah
    const totalKlien = order.totalHarga ?? 0;
    const selisih = Math.abs(totalKlien - totalBenar);
    if (selisih > 1) {
        functions.logger.warn(`[onOrderCreate] ⚠️ HARGA TIDAK COCOK — order ${orderId}: ` +
            `klien=${totalKlien}, seharusnya=${totalBenar}, selisih=${selisih}. ` +
            `DIKOREKSI.`);
        // Koreksi harga di Firestore
        const updates = {
            totalHarga: totalBenar,
            hargaSatuan: service.harga,
        };
        // Koreksi subtotal jika ada selisih juga
        if (subtotalOrder > 0 &&
            Math.abs(subtotalOrder - hargaBenar) > 1) {
            updates.subtotal = hargaBenar;
        }
        await snap.ref.update(updates);
    }
    else {
        functions.logger.info(`[onOrderCreate] ✓ Order ${orderId} harga valid: ${totalKlien}`);
    }
});
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ validatePayment
/**
 * Trigger: Firestore `onCreate` pada `payments/{paymentId}`.
 *
 * Memastikan `jumlah` pada dokumen pembayaran cocok dengan `totalHarga`
 * di dokumen `orders` yang direferensikan.
 */
exports.validatePayment = functions.firestore.onDocumentCreated({
    document: "payments/{paymentId}",
    region: REGION,
}, async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const payment = snap.data();
    const paymentId = event.params.paymentId;
    const orderId = payment.orderId ?? "";
    if (!orderId) {
        functions.logger.warn(`[validatePayment] Payment ${paymentId} tanpa orderId`);
        return;
    }
    const orderSnap = await db.collection("orders").doc(orderId).get();
    if (!orderSnap.exists) {
        functions.logger.error(`[validatePayment] Order ${orderId} tidak ditemukan ` +
            `untuk payment ${paymentId}`);
        return;
    }
    const order = orderSnap.data();
    const jumlahBayar = payment.jumlah ?? 0;
    const totalHarga = order.totalHarga ?? 0;
    const selisih = Math.abs(jumlahBayar - totalHarga);
    if (selisih > 1) {
        functions.logger.warn(`[validatePayment] ⚠️ JUMLAH BAYAR TIDAK COCOK — payment ${paymentId}: ` +
            `bayar=${jumlahBayar}, order=${totalHarga}. DIKOREKSI.`);
        await snap.ref.update({ jumlah: totalHarga });
    }
    else {
        functions.logger.info(`[validatePayment] ✓ Payment ${paymentId} valid: ${jumlahBayar}`);
    }
});
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
exports.onOrderFinalize = functions.firestore.onDocumentUpdated({
    document: "orders/{orderId}",
    region: REGION,
}, async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after)
        return;
    const orderId = event.params.orderId;
    // Hanya proses jika status baru saja berubah ke 'selesai'
    if (before.status === "selesai" || after.status !== "selesai")
        return;
    const totalHarga = after.totalHarga ?? 0;
    const penugasan = after.penugasan ?? [];
    const cleanerId = after.cleanerId ?? "";
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
                functions.logger.info(`[onOrderFinalize] Membuat payout ${payoutId}: Rp${bagian}`);
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
            }
            else {
                // Verifikasi jumlah existing
                const existingData = existing.data();
                const existingJumlah = existingData.jumlah ?? 0;
                if (Math.abs(existingJumlah - bagian) > 1) {
                    functions.logger.warn(`[onOrderFinalize] ⚠️ Payout ${payoutId} jumlah dikoreksi: ` +
                        `${existingJumlah} → ${bagian}`);
                    await payoutRef.update({ jumlah: bagian });
                }
            }
        }
    }
    else if (cleanerId) {
        // Single cleaner (fallback TA / pesanan lama)
        const payoutId = `${orderId}_${cleanerId}`;
        const payoutRef = db.collection("payouts").doc(payoutId);
        const existing = await payoutRef.get();
        const komisi = Math.round((totalHarga * KOMISI_PERSEN) / 100);
        const bagian = totalHarga - komisi;
        if (!existing.exists) {
            functions.logger.info(`[onOrderFinalize] Membuat payout single ${payoutId}: Rp${bagian}`);
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
    functions.logger.info(`[onOrderFinalize] ✓ Order ${orderId} selesai diproses.`);
});
//# sourceMappingURL=index.js.map