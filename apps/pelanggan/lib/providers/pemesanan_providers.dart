import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tk_core/tk_core.dart';

import 'app_providers.dart';
import 'beranda_providers.dart';

/// Slot terisi pada hari tertentu — dipakai P5 untuk menampilkan slot
/// disabled + ikon gembok (kaidah Pencegahan Kesalahan).
final slotTerisiProvider =
    StreamProvider.autoDispose.family<Set<DateTime>, DateTime>((ref, hari) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const {});
  return ref.watch(firestoreServiceProvider).watchSlotTerisi(hari);
});

/// Draft pemesanan (P5) — dipegang sementara sampai pelanggan konfirmasi
/// pembayaran di P7. Order + kunci slot BARU dibuat saat bayar, sehingga
/// pelanggan bebas kembali/mengedit tanpa menyandera jadwal atau membuat
/// order ganda.
class DraftPesanan {
  const DraftPesanan({
    required this.layanan,
    required this.kuantitas,
    this.tanggal,
    this.jam,
    this.alamat = '',
    this.lokasi,
    this.catatan = '',
  });

  final ServiceModel layanan;
  final num kuantitas;
  final DateTime? tanggal;
  final int? jam;
  final String alamat;
  final GeoPoint? lokasi;
  final String catatan;

  DateTime? get jadwal => tanggal == null || jam == null
      ? null
      : DateTime(tanggal!.year, tanggal!.month, tanggal!.day, jam!);

  num get total => layanan.harga * kuantitas;

  bool get lengkap =>
      jadwal != null && alamat.trim().isNotEmpty && lokasi != null;

  DraftPesanan salin({
    num? kuantitas,
    DateTime? tanggal,
    int? jam,
    String? alamat,
    GeoPoint? lokasi,
    String? catatan,
    bool hapusJam = false,
  }) =>
      DraftPesanan(
        layanan: layanan,
        kuantitas: kuantitas ?? this.kuantitas,
        tanggal: tanggal ?? this.tanggal,
        jam: hapusJam ? null : (jam ?? this.jam),
        alamat: alamat ?? this.alamat,
        lokasi: lokasi ?? this.lokasi,
        catatan: catatan ?? this.catatan,
      );
}

/// Draft aktif. Diisi saat pelanggan membuka P5 dari P4, dipertahankan saat
/// bolak-balik P5↔P6↔P7, dan dibersihkan setelah pesanan sukses dibuat.
final draftPesananProvider = StateProvider<DraftPesanan?>((_) => null);

/// Hasil upaya pembuatan pesanan+pembayaran (P7).
typedef HasilPesan = ({OrderModel? order, String? error, bool jadwalPenuh});

class PembayaranController extends AutoDisposeAsyncNotifier<OrderModel?> {
  @override
  Future<OrderModel?> build() async => null;

  /// Konfirmasi pembayaran → buat order + payment dalam satu transaction
  /// (Atomic Locking di titik bayar). Bukti (non-tunai) diunggah ke Storage
  /// lebih dulu; harga dihitung ulang di backend (skenario #6).
  Future<HasilPesan> konfirmasi({
    required DraftPesanan draft,
    required MetodeBayar metode,
    Uint8List? buktiBytes,
  }) async {
    if (!ref.read(firebaseSiapProvider)) {
      return (
        order: null,
        error: 'Terjadi kendala. Coba beberapa saat lagi.',
        jadwalPenuh: false
      );
    }
    if (!draft.lengkap) {
      return (
        order: null,
        error: 'Lengkapi jadwal dan alamat terlebih dahulu.',
        jadwalPenuh: false
      );
    }
    if (metode != MetodeBayar.tunai && buktiBytes == null) {
      return (
        order: null,
        error: 'Unggah bukti transfer terlebih dahulu.',
        jadwalPenuh: false
      );
    }
    final profil = await ref.read(profilSayaProvider.future);
    if (profil == null) {
      return (
        order: null,
        error: 'Sesi Anda berakhir. Silakan masuk kembali.',
        jadwalPenuh: false
      );
    }

    state = const AsyncLoading();
    try {
      String? buktiUrl;
      if (buktiBytes != null) {
        buktiUrl = await ref.read(storageServiceProvider).uploadBuktiBayar(
              userId: profil.userId,
              orderId: FirestoreService.slotOrderId(draft.jadwal!),
              bytes: buktiBytes,
            );
      }
      final order = await ref.read(firestoreServiceProvider).buatPesananLengkap(
            pelanggan: profil,
            serviceId: draft.layanan.serviceId,
            jadwal: draft.jadwal!,
            kuantitas: draft.kuantitas,
            alamatLayanan: draft.alamat.trim(),
            lokasi: draft.lokasi!,
            metode: metode,
            buktiBayar: buktiUrl,
            catatan: draft.catatan.trim(),
          );
      state = AsyncData(order);
      return (order: order, error: null, jadwalPenuh: false);
    } on JadwalPenuhException {
      state = const AsyncData(null);
      return (order: null, error: 'Jadwal Penuh', jadwalPenuh: true);
    } on LuarWilayahLayananException {
      state = const AsyncData(null);
      return (
        order: null,
        error: 'Lokasi Anda di luar area layanan Kota Sampit '
            '(Out of Delivery Range).',
        jadwalPenuh: false
      );
    } catch (_) {
      state = const AsyncData(null);
      return (
        order: null,
        error: 'Pembayaran belum dapat diproses. Periksa koneksi Anda '
            'lalu coba lagi.',
        jadwalPenuh: false
      );
    }
  }
}

final pembayaranControllerProvider =
    AsyncNotifierProvider.autoDispose<PembayaranController, OrderModel?>(
        PembayaranController.new);
