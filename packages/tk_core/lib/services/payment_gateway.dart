import '../models/payment_model.dart';
import 'firestore_service.dart';

/// Cara pelanggan menuntaskan pembayaran.
enum TipeInstruksi {
  /// Transfer manual / QRIS statis — pelanggan unggah bukti, admin verifikasi.
  manual,

  /// Redirect ke halaman gateway (VA/QRIS dinamis) — verifikasi via webhook.
  redirect,
}

/// Instruksi pembayaran yang dikembalikan gateway ke UI checkout.
class InstruksiBayar {
  const InstruksiBayar({
    required this.tipe,
    required this.metode,
    required this.jumlah,
    this.namaBank = '',
    this.noRekening = '',
    this.atasNama = '',
    this.qrisUrl = '',
    this.redirectUrl = '',
    this.expiry,
  });

  final TipeInstruksi tipe;
  final MetodeBayar metode;
  final int jumlah;

  // Manual (StaticGateway).
  final String namaBank;
  final String noRekening;
  final String atasNama;
  final String qrisUrl;

  // Redirect (gateway dinamis, mis. Xendit).
  final String redirectUrl;
  final DateTime? expiry;
}

/// Abstraksi payment gateway — mencegah vendor lock. Implementasi aktif
/// [StaticGateway] (transfer/QRIS statis + verifikasi admin). [XenditGateway]
/// disiapkan sebagai stub untuk aktivasi VA/QRIS dinamis di masa depan.
abstract class PaymentGateway {
  /// Buat instruksi pembayaran untuk sebuah order.
  Future<InstruksiBayar> buatInstruksi({
    required String orderId,
    required int jumlah,
    required MetodeBayar metode,
  });

  /// Identitas gateway (untuk logging/pemilihan).
  String get nama;
}

/// Gateway aktif: rekening & QRIS statis dari `settings/payments`; pelanggan
/// membayar manual lalu admin memverifikasi bukti (alur MVP yang berjalan).
class StaticGateway implements PaymentGateway {
  StaticGateway(this._fs);
  final FirestoreService _fs;

  @override
  String get nama => 'static';

  @override
  Future<InstruksiBayar> buatInstruksi({
    required String orderId,
    required int jumlah,
    required MetodeBayar metode,
  }) async {
    final s = await _fs.watchSettings('payments').first;
    return InstruksiBayar(
      tipe: TipeInstruksi.manual,
      metode: metode,
      jumlah: jumlah,
      namaBank: (s['namaBank'] as String?) ?? '',
      noRekening: (s['noRekening'] as String?) ?? '',
      atasNama: (s['atasNama'] as String?) ?? '',
      qrisUrl: (s['qrisUrl'] as String?) ?? '',
    );
  }
}

/// Gateway Xendit (VA/QRIS dinamis) — STUB. Diaktifkan saat integrasi resmi:
/// endpoint create-invoice + webhook `xenditWebhook` (Cloud Function).
/// Sengaja tak melempar di konstruksi agar bisa didaftarkan tanpa merusak build.
class XenditGateway implements PaymentGateway {
  const XenditGateway();

  @override
  String get nama => 'xendit';

  @override
  Future<InstruksiBayar> buatInstruksi({
    required String orderId,
    required int jumlah,
    required MetodeBayar metode,
  }) async {
    throw UnimplementedError(
      'XenditGateway belum diaktifkan. Aktifkan create-invoice + webhook '
      'xenditWebhook, lalu daftarkan gateway ini di paymentGatewayProvider.',
    );
  }
}
