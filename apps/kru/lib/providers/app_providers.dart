import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tk_core/tk_core.dart';

import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

final firebaseInitProvider = FutureProvider<bool>((_) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      try {
        await NotificationService().initialize();
      } catch (e) {
        debugPrint('Gagal inisialisasi background service: $e');
      }
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

final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return const Stream.empty();
  return ref.watch(authServiceProvider).authStateChanges;
});

const _kOnboardingKruSelesai = 'onboarding_kru_selesai';

final onboardingKruSelesaiProvider = FutureProvider<bool>((_) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingKruSelesai) ?? false;
});

Future<void> tandaiOnboardingKruSelesai() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingKruSelesai, true);
}

/// Dokumen `kru/{uid}` milik kru yang sedang login — real-time
/// (statusKetersediaan, rataRating, jumlahUlasan, posisi).
final kruSayaProvider = StreamProvider<KruModel>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return const Stream.empty();
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).watchKru(uid);
});

/// Dokumen `users/{uid}` (email untuk header K6).
final profilSayaProvider = FutureProvider<UserModel?>((ref) async {
  if (!ref.watch(firebaseSiapProvider)) return null;
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return null;
  return ref.watch(authServiceProvider).fetchProfile(uid);
});

/// Seluruh penugasan kru (orders dengan cleanerId == uid), terdekat dulu.
final tugasSayaProvider = StreamProvider<List<OrderModel>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const []);
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchOrdersByKru(uid).map(
        (orders) => (orders.toList()
          ..sort((a, b) => a.jadwal.compareTo(b.jadwal)))
            .toList(growable: false),
      );
});

/// Ulasan untuk kru ini — dipakai K5 menampilkan rating per pekerjaan.
final ulasanSayaProvider = StreamProvider<List<ReviewModel>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const []);
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchReviewsByKru(uid);
});

const pesanFirebaseBelumSiap =
    'Konfigurasi Firebase belum selesai. Jalankan flutterfire configure '
    'lalu build ulang aplikasi.';
