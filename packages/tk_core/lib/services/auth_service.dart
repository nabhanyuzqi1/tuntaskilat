import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

/// Dilempar saat akun berhasil autentikasi tapi `role`-nya tidak sesuai
/// aplikasi yang dipakai (mis. akun pelanggan login di Portal Kru).
/// Validasi ini wajib ada di klien DAN Security Rules (aturan arsitektur #1).
class RoleTidakSesuaiException implements Exception {
  const RoleTidakSesuaiException(this.roleDiharapkan, this.roleAktual);

  final UserRole roleDiharapkan;
  final UserRole roleAktual;

  @override
  String toString() =>
      'Akun ini terdaftar sebagai ${roleAktual.wire}, bukan ${roleDiharapkan.wire}.';
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Masuk dengan email + kata sandi, lalu validasi `role` terhadap aplikasi
  /// yang sedang dipakai. Jika role tidak cocok, sesi langsung diakhiri.
  Future<UserModel> signIn({
    required String email,
    required String password,
    required UserRole roleDiharapkan,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) {
      await _auth.signOut();
      throw StateError('Dokumen users/$uid tidak ditemukan.');
    }
    final user = UserModel.fromMap(uid, snap.data()!);
    if (user.role != roleDiharapkan) {
      await _auth.signOut();
      throw RoleTidakSesuaiException(roleDiharapkan, user.role);
    }
    return user;
  }

  /// Registrasi mandiri hanya untuk pelanggan (akun kru dibuat admin via A5,
  /// akun admin dikelola terpisah).
  Future<UserModel> registerPelanggan({
    required String nama,
    required String email,
    required String noTelepon,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final user = UserModel(
      userId: uid,
      nama: nama,
      email: email,
      noTelepon: noTelepon,
      alamat: '',
      role: UserRole.pelanggan,
    );
    await _db.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  Future<UserModel?> fetchProfile(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromMap(uid, snap.data()!);
  }

  Future<void> updatePassword({
    required String passwordLama,
    required String passwordBaru,
  }) async {
    final user = _auth.currentUser!;
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: passwordLama,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(passwordBaru);
  }

  Future<void> signOut() => _auth.signOut();
}
