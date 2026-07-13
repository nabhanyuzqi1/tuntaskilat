import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tk_core/tk_core.dart';

import '../firebase_options.dart';

/// A5 — pembuatan akun kru oleh admin, 100% Firebase tanpa server terpisah
/// (aturan arsitektur #2):
///
/// `createUserWithEmailAndPassword` di app utama akan MENGGANTI sesi admin
/// dengan akun baru. Solusinya: Firebase app SEKUNDER — akun kru dibuat &
/// login di sana, dokumen `users` ditulis oleh sesi akun baru itu sendiri
/// (rules `users.create` = isOwner), lalu dokumen `kru` ditulis dari sesi
/// admin (rules `kru.create` = isAdmin). Sesi admin tidak tersentuh.
class AkunKruService {
  Future<void> buatAkunKru({
    required String nama,
    required String email,
    required String noTelepon,
    required String password,
    List<String> keahlian = const [],
  }) async {
    final sekunder = await Firebase.initializeApp(
      name: 'buat-akun-kru',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final auth2 = FirebaseAuth.instanceFor(app: sekunder);
      final cred = await auth2.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      final db2 = FirebaseFirestore.instanceFor(app: sekunder);
      await db2.collection('users').doc(uid).set(UserModel(
            userId: uid,
            nama: nama,
            email: email,
            noTelepon: noTelepon,
            alamat: '',
            role: UserRole.kru,
          ).toMap());
      await auth2.signOut();

      await FirestoreService().buatDokumenKru(KruModel(
        cleanerId: uid,
        nama: nama,
        noTelepon: noTelepon,
        statusKetersediaan: false,
        rataRating: 0,
        jumlahUlasan: 0,
        keahlian: keahlian,
      ));
    } finally {
      await sekunder.delete();
    }
  }
}
