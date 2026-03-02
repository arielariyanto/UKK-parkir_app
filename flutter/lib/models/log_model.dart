// Model data untuk Log Aktivitas pengguna di sistem
// Digunakan untuk mencatat setiap aksi yang dilakukan oleh admin/petugas
// seperti login, tambah data, ubah tarif, dll.
class LogAktivitas {
  final int? idLog;
  final int? idUser;
  final String? namaLengkap;
  final String? role;
  final String aktivitas;
  final DateTime? waktuAktivitas;

  LogAktivitas({
    this.idLog,
    this.idUser,
    this.namaLengkap,
    this.role,
    required this.aktivitas,
    this.waktuAktivitas,
  });

  // Factory constructor: membuat objek LogAktivitas dari data JSON respons API
  // Menggunakan tryParse untuk menghindari error jika tipe data dari server tidak konsisten
  factory LogAktivitas.fromJson(Map<String, dynamic> json) {
    return LogAktivitas(
      // Pastikan id_log berupa int, fallback jika datang sebagai String
      idLog: json['id_log'] is int
          ? json['id_log']
          : json['id_log'] != null
              ? int.tryParse(json['id_log'].toString())
              : null,
      // Pastikan id_user berupa int, fallback jika datang sebagai String
      idUser: json['id_user'] is int
          ? json['id_user']
          : json['id_user'] != null
              ? int.tryParse(json['id_user'].toString())
              : null,
      namaLengkap: json['nama_lengkap']?.toString(),
      role: json['role']?.toString(),
      aktivitas: json['aktivitas']?.toString() ?? '',
      // Parse string ISO 8601 ke DateTime, null jika tidak ada atau format salah
      waktuAktivitas: json['waktu_aktivitas'] != null
          ? DateTime.tryParse(json['waktu_aktivitas'].toString())
          : null,
    );
  }

  // Mengonversi objek LogAktivitas ke Map untuk dikirim ke API
  // Field null tidak disertakan dalam body request
  Map<String, dynamic> toJson() {
    return {
      if (idLog != null) 'id_log': idLog,
      if (idUser != null) 'id_user': idUser,
      if (namaLengkap != null) 'nama_lengkap': namaLengkap,
      if (role != null) 'role': role,
      'aktivitas': aktivitas,
      // Konversi DateTime ke format ISO 8601 agar dapat dibaca oleh server
      if (waktuAktivitas != null) 'waktu_aktivitas': waktuAktivitas!.toIso8601String(),
    };
  }
}
