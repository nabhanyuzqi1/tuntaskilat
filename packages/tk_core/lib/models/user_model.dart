/// Koleksi `users` — lihat firestore-schema.md.
enum UserRole {
  pelanggan('pelanggan'),
  kru('kru'),
  admin('admin');

  const UserRole(this.wire);

  /// Nilai string yang tersimpan di field `role`.
  final String wire;

  static UserRole fromWire(String value) =>
      UserRole.values.firstWhere((r) => r.wire == value);
}

class UserModel {
  const UserModel({
    required this.userId,
    required this.nama,
    required this.email,
    required this.noTelepon,
    required this.alamat,
    required this.role,
    this.fotoUrl = '',
    this.nonaktif = false,
    this.kodeReferal = '',
    this.referredBy = '',
  });

  /// PK — ID dari Firebase Authentication.
  final String userId;
  final String nama;
  final String email;
  final String noTelepon;
  final String alamat;
  final UserRole role;

  /// URL foto profil di Cloud Storage ('' bila belum diunggah).
  final String fotoUrl;

  /// Akun dinonaktifkan (khusus admin — tak bisa login). Default aktif.
  final bool nonaktif;

  /// Kode referal milik pengguna ini untuk dibagikan ('' bila belum dibuat).
  final String kodeReferal;

  /// Kode referal yang dipakai saat mendaftar ('' bila mendaftar mandiri).
  final String referredBy;

  factory UserModel.fromMap(String id, Map<String, dynamic> map) => UserModel(
        userId: id,
        nama: map['nama'] as String? ?? '',
        email: map['email'] as String? ?? '',
        noTelepon: map['noTelepon'] as String? ?? '',
        alamat: map['alamat'] as String? ?? '',
        role: UserRole.fromWire(map['role'] as String),
        fotoUrl: map['fotoUrl'] as String? ?? '',
        nonaktif: map['nonaktif'] as bool? ?? false,
        kodeReferal: (map['kodeReferal'] as String? ?? '').toUpperCase(),
        referredBy: (map['referredBy'] as String? ?? '').toUpperCase(),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'nama': nama,
        'email': email,
        'noTelepon': noTelepon,
        'alamat': alamat,
        'role': role.wire,
        'fotoUrl': fotoUrl,
        'nonaktif': nonaktif,
        'kodeReferal': kodeReferal.toUpperCase(),
        'referredBy': referredBy.toUpperCase(),
      };

  /// Kode referal deterministik dari uid (6 char base32, tanpa 0/1/O/I).
  static String kodeReferalDari(String uid) {
    const abjad = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    var h = 0;
    for (final c in uid.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    final sb = StringBuffer('TK');
    for (var i = 0; i < 6; i++) {
      sb.write(abjad[h % abjad.length]);
      h ~/= abjad.length;
      if (h == 0) h = uid.length + i + 7;
    }
    return sb.toString();
  }

  UserModel copyWith({
    String? nama,
    String? noTelepon,
    String? alamat,
    String? fotoUrl,
    String? kodeReferal,
    String? referredBy,
  }) =>
      UserModel(
        userId: userId,
        nama: nama ?? this.nama,
        email: email,
        noTelepon: noTelepon ?? this.noTelepon,
        alamat: alamat ?? this.alamat,
        role: role,
        fotoUrl: fotoUrl ?? this.fotoUrl,
        nonaktif: nonaktif,
        kodeReferal: kodeReferal ?? this.kodeReferal,
        referredBy: referredBy ?? this.referredBy,
      );
}
