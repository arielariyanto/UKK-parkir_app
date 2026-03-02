// Model data untuk Pengguna (User) sistem
// Merepresentasikan akun pengguna dengan peran berbeda: admin, petugas, atau owner
class User {
  final int? idUser;
  final String namaLengkap;
  final String username;
  final String role;
  final int statusAktif;

  // Wajib mengisi namaLengkap, username, dan role saat membuat User baru
  User({
    this.idUser,
    required this.namaLengkap,
    required this.username,
    required this.role,
    this.statusAktif = 0,
  });

  // Factory constructor: membuat objek User dari data JSON respons API
  // Menggunakan parsing defensif untuk menangani tipe data yang tidak konsisten
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Tangani id_user yang bisa berupa int atau String dari server
      idUser: json['id_user'] is int 
          ? json['id_user'] 
          : (json['id_user'] != null ? int.tryParse(json['id_user'].toString()) : null),
      namaLengkap: json['nama_lengkap']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      // Tangani status_aktif yang bisa berupa int atau String, default 0 jika null
      statusAktif: json['status_aktif'] is int 
          ? json['status_aktif'] 
          : (json['status_aktif'] != null ? int.tryParse(json['status_aktif'].toString()) ?? 0 : 0),
    );
  }

  // Mengonversi objek User ke Map untuk dikirim ke API
  // Field id_user hanya disertakan jika ada (tidak null), misal saat update
  Map<String, dynamic> toJson() {
    return {
      if (idUser != null) 'id_user': idUser,
      'nama_lengkap': namaLengkap,
      'username': username,
      'role': role,
      'status_aktif': statusAktif,
    };
  }

  // Getter: mengembalikan true jika pengguna sedang aktif (statusAktif == 1)
  bool get isAktif => statusAktif == 1;
}
