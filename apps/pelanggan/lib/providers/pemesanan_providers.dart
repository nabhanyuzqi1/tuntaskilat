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

/// Hasil upaya pemesanan P5.
typedef HasilPesan = ({OrderModel? order, String? error, bool jadwalPenuh});

class PemesananController extends AutoDisposeAsyncNotifier<OrderModel?> {
  @override
  Future<OrderModel?> build() async => null;

  /// Membuat pesanan lewat Firestore Transaction (Atomic Locking, tk_core).
  /// Harga TIDAK dikirim dari sini — dihitung ulang di dalam transaction
  /// dari dokumen `services` (skenario Black-Box #6).
  Future<HasilPesan> buatPesanan({
    required ServiceModel layanan,
    required DateTime jadwal,
    required num kuantitas,
    required String alamatLayanan,
    required GeoPoint lokasi,
    String catatan = '',
  }) async {
    if (!ref.read(firebaseSiapProvider)) {
      return (
        order: null,
        error: 'Terjadi kendala. Coba beberapa saat lagi.',
        jadwalPenuh: false,
      );
    }
    final profil = await ref.read(profilSayaProvider.future);
    if (profil == null) {
      return (
        order: null,
        error: 'Sesi Anda berakhir. Silakan masuk kembali.',
        jadwalPenuh: false,
      );
    }
    state = const AsyncLoading();
    try {
      final order = await ref.read(firestoreServiceProvider).createOrder(
            pelanggan: profil,
            serviceId: layanan.serviceId,
            jadwal: jadwal,
            kuantitas: kuantitas,
            alamatLayanan: alamatLayanan,
            lokasi: lokasi,
            catatan: catatan,
          );
      state = AsyncData(order);
      return (order: order, error: null, jadwalPenuh: false);
    } on JadwalPenuhException {
      state = const AsyncData(null);
      return (
        order: null,
        error: 'Jadwal Penuh',
        jadwalPenuh: true,
      );
    } on LuarWilayahLayananException {
      state = const AsyncData(null);
      return (
        order: null,
        error: 'Lokasi Anda di luar area layanan Kota Sampit '
            '(Out of Delivery Range).',
        jadwalPenuh: false,
      );
    } catch (_) {
      state = const AsyncData(null);
      return (
        order: null,
        error: 'Pesanan belum dapat diproses. Periksa koneksi Anda lalu '
            'coba lagi.',
        jadwalPenuh: false,
      );
    }
  }
}

final pemesananControllerProvider =
    AsyncNotifierProvider.autoDispose<PemesananController, OrderModel?>(
        PemesananController.new);
