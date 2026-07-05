import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tk_core/tk_core.dart';

import 'app_providers.dart';

/// Controller autentikasi K1 — login kru menolak akun dengan role lain
/// (validasi klien; Security Rules melengkapi di server — aturan #1).
class AuthKruController extends AutoDisposeAsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async => null;

  Future<bool> masuk({required String email, required String password}) async {
    if (!ref.read(firebaseSiapProvider)) {
      state = AsyncError(
        kDebugMode
            ? pesanFirebaseBelumSiap
            : 'Terjadi kendala. Coba beberapa saat lagi.',
        StackTrace.current,
      );
      return false;
    }
    state = const AsyncLoading();
    try {
      final user = await ref.read(authServiceProvider).signIn(
            email: email,
            password: password,
            roleDiharapkan: UserRole.kru,
          );
      state = AsyncData(user);
      return true;
    } on RoleTidakSesuaiException {
      state = AsyncError(
        'Akun ini bukan akun kru. Gunakan Aplikasi Pelanggan atau hubungi '
        'admin.',
        StackTrace.current,
      );
    } on FirebaseAuthException catch (e) {
      state = AsyncError(_pesanAuth(e), StackTrace.current);
    } catch (_) {
      state = AsyncError(
        'Terjadi kendala. Periksa koneksi Anda lalu coba lagi.',
        StackTrace.current,
      );
    }
    return false;
  }

  static String _pesanAuth(FirebaseAuthException e) => switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Email atau kata sandi tidak sesuai. Periksa kembali.',
        'too-many-requests' =>
          'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.',
        'network-request-failed' =>
          'Koneksi terputus. Periksa jaringan Anda lalu coba lagi.',
        _ => 'Terjadi kendala saat autentikasi. Coba lagi.',
      };
}

final authKruControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthKruController, UserModel?>(
        AuthKruController.new);
