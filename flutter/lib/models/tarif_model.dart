class Tarif {
  final int? idTarif;
  final int? idKendaraan;
  final String? jenisKendaraan;
  final double tarifPerJam;

  Tarif({
    this.idTarif,
    this.idKendaraan,
    this.jenisKendaraan,
    required this.tarifPerJam,
  });

  factory Tarif.fromJson(Map<String, dynamic> json) {
    return Tarif(
      idTarif: json['id_tarif'] is int
          ? json['id_tarif']
          : json['id_tarif'] != null
              ? int.tryParse(json['id_tarif'].toString())
              : null,
      idKendaraan: json['id_kendaraan'] is int
          ? json['id_kendaraan']
          : json['id_kendaraan'] != null
              ? int.tryParse(json['id_kendaraan'].toString())
              : null,
      jenisKendaraan: json['jenis_kendaraan']?.toString(),
      tarifPerJam: json['tarif_per_jam'] is double
          ? json['tarif_per_jam']
          : json['tarif_per_jam'] is int
              ? (json['tarif_per_jam'] as int).toDouble()
              : double.tryParse(json['tarif_per_jam']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idTarif != null) 'id_tarif': idTarif,
      if (idKendaraan != null) 'id_kendaraan': idKendaraan,
      if (jenisKendaraan != null) 'jenis_kendaraan': jenisKendaraan,
      'tarif_per_jam': tarifPerJam,
    };
  }
}
