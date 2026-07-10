import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tk_core/tk_core.dart';

import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../services/tim_admin_service.dart';

final firebaseInitProvider = FutureProvider<bool>((_) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return true;
  } on UnsupportedError {
    return false;
  }
});

final firebaseSiapProvider = Provider<bool>(
    (ref) => ref.watch(firebaseInitProvider).valueOrNull ?? false);

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final firestoreServiceProvider =
    Provider<FirestoreService>((_) => FirestoreService());

final storageServiceProvider =
    Provider<StorageService>((_) => StorageService());

final timAdminServiceProvider =
    Provider<TimAdminService>((_) => TimAdminService());

final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return const Stream.empty();
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Profil admin yang sedang login (users/{uid}).
final profilAdminProvider = FutureProvider<UserModel?>((ref) async {
  if (!ref.watch(firebaseSiapProvider)) return null;
  final uid = ref.watch(authServiceProvider).currentUser?.uid;
  if (uid == null) return null;
  return ref.watch(authServiceProvider).fetchProfile(uid);
});

/// Seluruh pesanan (A2 agregasi + A3 tabel), terbaru dulu.
final semuaOrderProvider = StreamProvider<List<OrderModel>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchSemuaOrders().map(
        (orders) => (orders.toList()
          ..sort((a, b) => b.tanggalPesan.compareTo(a.tanggalPesan)))
            .toList(growable: false),
      );
});

/// Seluruh kru termasuk offline (A5 + dropdown penugasan A3).
final semuaKruProvider = StreamProvider<List<KruModel>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchSemuaKru();
});

/// Seluruh layanan (A4) — termasuk nonaktif.
final semuaLayananProvider = StreamProvider<List<ServiceModel>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const []);
  // watchActiveServices memfilter aktif; A4 butuh semuanya.
  return ref.watch(firestoreServiceProvider).watchSemuaLayanan();
});

/// Daftar admin (A6 Manajemen Tim) — users role==admin.
final daftarAdminProvider = StreamProvider<List<UserModel>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchAdmins().map(
        (l) => (l.toList()..sort((a, b) => a.nama.compareTo(b.nama)))
            .toList(growable: false),
      );
});

/// Daftar voucher — A7 kelola promo (lapisan produk nyata, di luar TA).
final vouchersProvider = StreamProvider<List<VoucherModel>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchVouchers();
});

/// Jumlah pesanan menunggu verifikasi — badge sidebar & KPI A2.
final menungguVerifikasiProvider = Provider<int>((ref) =>
    ref
        .watch(semuaOrderProvider)
        .valueOrNull
        ?.where((o) => o.status == OrderStatus.menungguVerifikasi)
        .length ??
    0);

const pesanFirebaseBelumSiap =
    'Konfigurasi Firebase belum selesai. Jalankan flutterfire configure '
    'lalu build ulang aplikasi.';
