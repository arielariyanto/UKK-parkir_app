class Tarif {
  final int idTarif;
  final String jenisKendaraan;
  final int tarifPerJam;

  Tarif({
    required this.idTarif,
    required this.jenisKendaraan,
    required this.tarifPerJam,
  });

  factory Tarif.fromJson(Map<String, dynamic> json) {
    return Tarif(
      idTarif: json['id_tarif'],
      jenisKendaraan: json['jenis_kendaraan'],
      tarifPerJam: json['tarif_per_jam'] is String 
          ? int.parse(json['tarif_per_jam']) 
          : json['tarif_per_jam'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_tarif': idTarif,
      'jenis_kendaraan': jenisKendaraan,
      'tarif_per_jam': tarifPerJam,
    };
  }
}
