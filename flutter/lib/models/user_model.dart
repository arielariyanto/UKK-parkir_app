class User {
  final int? idUser;
  final String namaLengkap;
  final String username;
  final String role;
  final int statusAktif;

  User({
    this.idUser,
    required this.namaLengkap,
    required this.username,
    required this.role,
    this.statusAktif = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUser: json['id_user'] is int 
          ? json['id_user'] 
          : (json['id_user'] != null ? int.tryParse(json['id_user'].toString()) : null),
      namaLengkap: json['nama_lengkap']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      statusAktif: json['status_aktif'] is int 
          ? json['status_aktif'] 
          : (json['status_aktif'] != null ? int.tryParse(json['status_aktif'].toString()) ?? 0 : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idUser != null) 'id_user': idUser,
      'nama_lengkap': namaLengkap,
      'username': username,
      'role': role,
      'status_aktif': statusAktif,
    };
  }

  bool get isAktif => statusAktif == 1;
}
