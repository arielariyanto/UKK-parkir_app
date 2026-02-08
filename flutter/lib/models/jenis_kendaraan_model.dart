class JenisKendaraan {
  final int idKendaraan;
  final String jenisKendaraan;

  JenisKendaraan({
    required this.idKendaraan,
    required this.jenisKendaraan,
  });

  factory JenisKendaraan.fromJson(Map<String, dynamic> json) {
    return JenisKendaraan(
      idKendaraan: json['id_kendaraan'] is int
          ? json['id_kendaraan']
          : int.parse(json['id_kendaraan'].toString()),
      jenisKendaraan: json['jenis_kendaraan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_kendaraan': idKendaraan,
      'jenis_kendaraan': jenisKendaraan,
    };
  }
}
