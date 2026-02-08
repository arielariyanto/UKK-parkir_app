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

  factory LogAktivitas.fromJson(Map<String, dynamic> json) {
    return LogAktivitas(
      idLog: json['id_log'] is int
          ? json['id_log']
          : json['id_log'] != null
              ? int.tryParse(json['id_log'].toString())
              : null,
      idUser: json['id_user'] is int
          ? json['id_user']
          : json['id_user'] != null
              ? int.tryParse(json['id_user'].toString())
              : null,
      namaLengkap: json['nama_lengkap']?.toString(),
      role: json['role']?.toString(),
      aktivitas: json['aktivitas']?.toString() ?? '',
      waktuAktivitas: json['waktu_aktivitas'] != null
          ? DateTime.tryParse(json['waktu_aktivitas'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idLog != null) 'id_log': idLog,
      if (idUser != null) 'id_user': idUser,
      if (namaLengkap != null) 'nama_lengkap': namaLengkap,
      if (role != null) 'role': role,
      'aktivitas': aktivitas,
      if (waktuAktivitas != null) 'waktu_aktivitas': waktuAktivitas!.toIso8601String(),
    };
  }
}
