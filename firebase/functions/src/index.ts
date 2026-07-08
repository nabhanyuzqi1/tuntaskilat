/**
 * Cloud Functions — Tuntaskilat (Branch TA)
 *
 * Safety-net layer: validasi harga dan pembayaran di sisi server.
 * TA Bab IV 4.2.2 — Atomic Locking + Backend Validation.
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
const REGION = "asia-southeast2";

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

    if (!serviceId) return;

    const serviceSnap = await db.collection("services").doc(serviceId).get();
    if (!serviceSnap.exists) return;

    const service = serviceSnap.data()!;
    const hargaAsli: number = service.harga ?? 0;
    const kuantitas: number = order.kuantitas ?? 1;
    
    // Fixed pricing (TA mode):
    const totalBenar = hargaAsli * kuantitas;
    const totalKlien: number = order.totalHarga ?? 0;
    const selisih = Math.abs(totalKlien - totalBenar);

    if (selisih > 1) {
      functions.logger.warn(
        `[onOrderCreate] ⚠️ HARGA TIDAK COCOK — order ${orderId}: ` +
          `klien=${totalKlien}, seharusnya=${totalBenar}. DIKOREKSI.`,
      );
      await snap.ref.update({
        totalHarga: totalBenar,
        hargaSatuan: hargaAsli,
      });
    }
  },
);

export const validatePayment = functions.firestore.onDocumentCreated(
  {
    document: "payments/{paymentId}",
    region: REGION,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const payment = snap.data();
    const orderId: string = payment.orderId ?? "";
    if (!orderId) return;

    const orderSnap = await db.collection("orders").doc(orderId).get();
    if (!orderSnap.exists) return;

    const order = orderSnap.data()!;
    const jumlahBayar: number = payment.jumlah ?? 0;
    const totalHarga: number = order.totalHarga ?? 0;
    const selisih = Math.abs(jumlahBayar - totalHarga);

    if (selisih > 1) {
      functions.logger.warn(
        `[validatePayment] ⚠️ JUMLAH BAYAR TIDAK COCOK: dikoreksi.`,
      );
      await snap.ref.update({jumlah: totalHarga});
    }
  },
);
