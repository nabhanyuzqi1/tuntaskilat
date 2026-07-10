import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tk_core/tk_core.dart';

import 'app_providers.dart';

/// Profil pengguna yang sedang login (dokumen `users/{uid}`).
final profilSayaProvider = FutureProvider<UserModel?>((ref) async {
  if (!ref.watch(firebaseSiapProvider)) return null;
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return null;
  return ref.watch(authServiceProvider).fetchProfile(uid);
});

/// Katalog layanan aktif — real-time (StreamBuilder/snapshots, PRD §7).
final layananAktifProvider = StreamProvider<List<ServiceModel>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchActiveServices();
});

/// Order aktif terbaru pelanggan — kartu "pesanan berjalan" di Beranda.
final orderAktifProvider =
    StreamProvider.autoDispose.family<OrderModel?, String>((ref, uid) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).watchOrderAktif(uid);
});

/// Kata kunci pencarian P3 (filter opsional, page-inventory P3).
final pencarianLayananProvider = StateProvider<String>((_) => '');

/// Hasil filter katalog berdasarkan kata kunci.
final layananTersaringProvider = Provider<AsyncValue<List<ServiceModel>>>(
  (ref) {
    final kata = ref.watch(pencarianLayananProvider).trim().toLowerCase();
    return ref.watch(layananAktifProvider).whenData(
          (list) => kata.isEmpty
              ? list
              : list
                  .where((s) => s.namaLayanan.toLowerCase().contains(kata))
                  .toList(growable: false),
        );
  },
);

/// Pesanan selesai milik pengguna untuk section "Pesan Ulang" (maks. 5,
/// terbaru dulu).
final pesanUlangProvider = StreamProvider<List<OrderModel>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const []);
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchOrdersByUser(uid).map(
    (orders) {
      final selesai = orders
          .where((o) =>
              o.status == OrderStatus.selesai ||
              o.status == OrderStatus.dinilai)
          .toList()
        ..sort((a, b) => b.tanggalPesan.compareTo(a.tanggalPesan));
      return selesai.take(5).toList(growable: false);
    },
  );
});
