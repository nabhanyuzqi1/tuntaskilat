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

  factory UserModel.fromMap(String id, Map<String, dynamic> map) => UserModel(
        userId: id,
        nama: map['nama'] as String? ?? '',
        email: map['email'] as String? ?? '',
        noTelepon: map['noTelepon'] as String? ?? '',
        alamat: map['alamat'] as String? ?? '',
        role: UserRole.fromWire(map['role'] as String),
        fotoUrl: map['fotoUrl'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'nama': nama,
        'email': email,
        'noTelepon': noTelepon,
        'alamat': alamat,
        'role': role.wire,
        'fotoUrl': fotoUrl,
      };

  UserModel copyWith({
    String? nama,
    String? noTelepon,
    String? alamat,
    String? fotoUrl,
  }) =>
      UserModel(
        userId: userId,
        nama: nama ?? this.nama,
        email: email,
        noTelepon: noTelepon ?? this.noTelepon,
        alamat: alamat ?? this.alamat,
        role: role,
        fotoUrl: fotoUrl ?? this.fotoUrl,
      );
}
