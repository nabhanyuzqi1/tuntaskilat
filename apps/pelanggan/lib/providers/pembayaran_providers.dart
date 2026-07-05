import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tk_core/tk_core.dart';

import 'app_providers.dart';

/// Controller P7 — unggah bukti (non-tunai) lalu tulis `payments` dan
/// majukan status order ke `menunggu_verifikasi` (State Diagram 3.11).
class PembayaranController extends AutoDisposeAsyncNotifier<PaymentModel?> {
  @override
  Future<PaymentModel?> build() async => null;

  /// Mengembalikan pesan error, atau null jika sukses.
  Future<String?> konfirmasi({
    required OrderModel order,
    required MetodeBayar metode,
    Uint8List? buktiBytes,
  }) async {
    if (metode != MetodeBayar.tunai && buktiBytes == null) {
      return 'Unggah bukti transfer terlebih dahulu.';
    }
    state = const AsyncLoading();
    try {
      String? buktiUrl;
      if (buktiBytes != null) {
        buktiUrl = await ref.read(storageServiceProvider).uploadBuktiBayar(
              orderId: order.orderId,
              bytes: buktiBytes,
            );
      }
      final payment = await ref.read(firestoreServiceProvider).createPayment(
            orderId: order.orderId,
            userId: order.userId,
            metode: metode,
            jumlah: order.totalHarga,
            buktiBayar: buktiUrl,
          );
      await ref
          .read(firestoreServiceProvider)
          .updateOrderStatus(order.orderId, OrderStatus.menungguVerifikasi);
      state = AsyncData(payment);
      return null;
    } catch (_) {
      state = const AsyncData(null);
      return 'Pembayaran belum terkirim. Periksa koneksi Anda lalu coba '
          'lagi.';
    }
  }
}

final pembayaranControllerProvider =
    AsyncNotifierProvider.autoDispose<PembayaranController, PaymentModel?>(
        PembayaranController.new);
