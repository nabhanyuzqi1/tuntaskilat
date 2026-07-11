import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tk_core/tk_core.dart';

import 'app_providers.dart';

/// Controller autentikasi P2. State `AsyncValue<UserModel?>`:
/// data(null) = belum masuk, data(user) = berhasil, error = pesan untuk UI
/// (tone brand: profesional, ramah, berorientasi solusi).
class AuthController extends AutoDisposeAsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async => null;

  Future<bool> masuk({required String email, required String password}) =>
      _jalankan(() => ref.read(authServiceProvider).signIn(
            email: email,
            password: password,
            roleDiharapkan: UserRole.pelanggan,
          ));

  Future<bool> daftar({
    required String nama,
    required String email,
    required String noTelepon,
    required String password,
    String? kodeReferal,
  }) =>
      _jalankan(() => ref.read(authServiceProvider).registerPelanggan(
            nama: nama,
            email: email,
            noTelepon: noTelepon,
            password: password,
            kodeReferal: kodeReferal,
          ));

  static var _googleSiap = false;

  /// Masuk/daftar dengan akun Google (page-inventory P2 — akun pihak
  /// ketiga). Pembatalan oleh pengguna bukan error — kembali diam-diam.
  Future<bool> masukDenganGoogle() async {
    // Tunggu Firebase selesai init.
    final initResult = await ref.read(firebaseInitProvider.future);
    if (!initResult) {
      state = AsyncError(
        kDebugMode
            ? pesanFirebaseBelumSiap
            : 'Terjadi kendala. Coba beberapa saat lagi.',
        StackTrace.current,
      );
      return false;
    }
    final GoogleSignInAccount akun;
    try {
      final gsi = GoogleSignIn.instance;
      if (!_googleSiap) {
        // serverClientId = OAuth Web client (client_type 3 di
        // google-services.json). WAJIB di Android agar
        // authentication.idToken terisi — tanpa ini idToken null dan
        // GoogleAuthProvider.credential gagal (akar Bug login Google).
        await gsi.initialize(
          serverClientId:
              '429452141588-07vcu9fniaem41as3tlpsp23lb6a66g2.apps.googleusercontent.com',
        );
        _googleSiap = true;
      }
      akun = await gsi.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      state = AsyncError(
        'Masuk dengan Google tidak berhasil. Coba lagi atau gunakan email.',
        StackTrace.current,
      );
      return false;
    }
    final credential = GoogleAuthProvider.credential(
      idToken: akun.authentication.idToken,
    );
    return _jalankan(() => ref
        .read(authServiceProvider)
        .signInWithCredentialPelanggan(credential));
  }

  Future<bool> _jalankan(Future<UserModel> Function() aksi) async {
    // Tunggu Firebase selesai init — jangan langsung gagal jika belum siap.
    final initResult = await ref.read(firebaseInitProvider.future);
    if (!initResult) {
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
      final user = await aksi();
      state = AsyncData(user);
      return true;
    } on RoleTidakSesuaiException {
      state = AsyncError(
        'Akun ini bukan akun pelanggan. Gunakan aplikasi yang sesuai '
        'dengan peran Anda.',
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
        'email-already-in-use' =>
          'Email sudah terdaftar. Silakan masuk dengan akun tersebut.',
        'invalid-email' => 'Format email tidak valid',
        'weak-password' => 'Kata sandi terlalu lemah. Gunakan minimal 8 '
            'karakter.',
        'too-many-requests' =>
          'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.',
        'network-request-failed' =>
          'Koneksi terputus. Periksa jaringan Anda lalu coba lagi.',
        _ => 'Terjadi kendala saat autentikasi. Coba lagi.',
      };
}

final authControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, UserModel?>(
        AuthController.new);
