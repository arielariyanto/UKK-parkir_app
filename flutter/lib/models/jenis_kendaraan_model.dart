// Model data untuk Jenis Kendaraan
// Merepresentasikan kategori kendaraan seperti "Motor", "Mobil", "Truk", dll.
class JenisKendaraan {
  final int idKendaraan;
  final String jenisKendaraan;

  // Kedua field bersifat wajib karena jenis kendaraan harus memiliki ID dan nama
  JenisKendaraan({
    required this.idKendaraan,
    required this.jenisKendaraan,
  });

  // Factory constructor: membuat objek JenisKendaraan dari data JSON respons API
  factory JenisKendaraan.fromJson(Map<String, dynamic> json) {
    return JenisKendaraan(
      // Tangani kasus id_kendaraan bisa berupa int atau String dari server
      idKendaraan: json['id_kendaraan'] is int
          ? json['id_kendaraan']
          : int.parse(json['id_kendaraan'].toString()),
      jenisKendaraan: json['jenis_kendaraan']?.toString() ?? '',
    );
  }

  // Mengonversi objek JenisKendaraan ke Map untuk dikirim ke API
  Map<String, dynamic> toJson() {
    return {
      'id_kendaraan': idKendaraan,
      'jenis_kendaraan': jenisKendaraan,
    };
  }
}
