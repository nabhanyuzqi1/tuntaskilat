import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tk_core/tk_core.dart';

/// Di-override di main() — false selama firebase_options.dart masih
/// placeholder (sebelum `flutterfire configure`).
final firebaseSiapProvider = Provider<bool>((_) => false);

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final firestoreServiceProvider =
    Provider<FirestoreService>((_) => FirestoreService());

final storageServiceProvider =
    Provider<StorageService>((_) => StorageService());

final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return const Stream.empty();
  return ref.watch(authServiceProvider).authStateChanges;
});

const _kOnboardingSelesai = 'onboarding_selesai';

final onboardingSelesaiProvider = FutureProvider<bool>((_) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingSelesai) ?? false;
});

Future<void> tandaiOnboardingSelesai() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingSelesai, true);
}

/// Pesan konfigurasi saat aksi Firebase dipanggil sebelum
/// `flutterfire configure` dijalankan.
const pesanFirebaseBelumSiap =
    'Konfigurasi Firebase belum selesai. Jalankan flutterfire configure '
    'lalu build ulang aplikasi.';
