class User {
  final int idUser;
  final String namaLengkap;
  final String username;
  final String role;
  final int statusAktif;

  User({
    required this.idUser,
    required this.namaLengkap,
    required this.username,
    required this.role,
    required this.statusAktif,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUser: json['id_user'],
      namaLengkap: json['nama_lengkap'] ?? '',
      username: json['username'],
      role: json['role'],
      statusAktif: json['status_aktif'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'nama_lengkap': namaLengkap,
      'username': username,
      'role': role,
      'status_aktif': statusAktif,
    };
  }
}
