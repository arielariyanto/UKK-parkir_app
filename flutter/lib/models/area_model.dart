// Model data untuk Area Parkir
// Merepresentasikan satu area/lokasi parkir beserta kapasitas dan jumlah kendaraan yang terisi
class Area {
  final int? idArea;
  final String namaArea;
  final int kapasitas;
  final int terisi;

  // Konstruktor dengan namaArea dan kapasitas sebagai field wajib
  Area({
    this.idArea,
    required this.namaArea,
    required this.kapasitas,
    this.terisi = 0,
  });

  // Factory constructor: membuat objek Area dari data JSON respons API
  // Menggunakan parsing defensif (tryParse) untuk menangani tipe data yang tidak konsisten dari server
  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      // Tangani kasus id_area bisa berupa int atau String dari server
      idArea: json['id_area'] is int ? json['id_area'] : (json['id_area'] != null ? int.tryParse(json['id_area'].toString()) : null),
      namaArea: json['nama_area']?.toString() ?? '',
      // Tangani kapasitas bisa berupa int atau String, default 0 jika null
      kapasitas: json['kapasitas'] is int ? json['kapasitas'] : (json['kapasitas'] != null ? int.tryParse(json['kapasitas'].toString()) ?? 0 : 0),
      // Tangani terisi bisa berupa int atau String, default 0 jika null
      terisi: json['terisi'] is int ? json['terisi'] : (json['terisi'] != null ? int.tryParse(json['terisi'].toString()) ?? 0 : 0),
    );
  }

  // Mengonversi objek Area kembali ke Map untuk dikirim ke API
  // Field id_area hanya disertakan jika tidak null (saat update, bukan create)
  Map<String, dynamic> toJson() {
    return {
      if (idArea != null) 'id_area': idArea,
      'nama_area': namaArea,
      'kapasitas': kapasitas,
      'terisi': terisi,
    };
  }

  // Getter untuk menghitung slot yang masih tersedia (kapasitas - terisi)
  int get tersedia => kapasitas - terisi;
}
