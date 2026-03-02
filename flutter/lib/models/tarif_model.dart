// Model data untuk Tarif Parkir
// Merepresentasikan tarif per jam untuk setiap jenis kendaraan
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

  // Factory constructor: membuat objek Tarif dari data JSON respons API
  // Menggunakan parsing defensif karena server bisa mengirimkan tipe data yang bervariasi
  factory Tarif.fromJson(Map<String, dynamic> json) {
    return Tarif(
      // Tangani id_tarif bisa berupa int atau String
      idTarif: json['id_tarif'] is int
          ? json['id_tarif']
          : json['id_tarif'] != null
              ? int.tryParse(json['id_tarif'].toString())
              : null,
      // Tangani id_kendaraan bisa berupa int atau String
      idKendaraan: json['id_kendaraan'] is int
          ? json['id_kendaraan']
          : json['id_kendaraan'] != null
              ? int.tryParse(json['id_kendaraan'].toString())
              : null,
      jenisKendaraan: json['jenis_kendaraan']?.toString(),
      // Tangani tarif_per_jam yang bisa berupa double, int, atau String
      // Prioritas: double > int (konversi ke double) > String (parse) > 0.0 (default)
      tarifPerJam: json['tarif_per_jam'] is double
          ? json['tarif_per_jam']
          : json['tarif_per_jam'] is int
              ? (json['tarif_per_jam'] as int).toDouble()
              : double.tryParse(json['tarif_per_jam']?.toString() ?? '0') ?? 0.0,
    );
  }

  // Mengonversi objek Tarif ke Map untuk dikirim ke API
  // Field null tidak disertakan dalam body request
  Map<String, dynamic> toJson() {
    return {
      if (idTarif != null) 'id_tarif': idTarif,
      if (idKendaraan != null) 'id_kendaraan': idKendaraan,
      if (jenisKendaraan != null) 'jenis_kendaraan': jenisKendaraan,
      'tarif_per_jam': tarifPerJam,
    };
  }
}
