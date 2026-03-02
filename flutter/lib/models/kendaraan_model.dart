// Model data untuk Kendaraan yang terdaftar di sistem
// Merepresentasikan kendaraan berdasarkan plat nomor, jenis, warna, dan nama pemilik
class Kendaraan {
  final int? idKendaraan;
  final String platNomor;
  final String jenisKendaraan;
  final String? warna;
  final String? pemilik;

  Kendaraan({
    this.idKendaraan,
    required this.platNomor,
    required this.jenisKendaraan,
    this.warna,
    this.pemilik,
  });

  // Factory constructor: membuat objek Kendaraan dari data JSON respons API
  factory Kendaraan.fromJson(Map<String, dynamic> json) {
    return Kendaraan(
      idKendaraan: json['id_kendaraan'],
      platNomor: json['plat_nomor'],
      jenisKendaraan: json['jenis_kendaraan'],
      warna: json['warna'],
      pemilik: json['pemilik'],
    );
  }

  // Mengonversi objek Kendaraan ke Map untuk dikirim ke API
  // Field opsional (warna, pemilik, dan id) hanya disertakan jika tidak null
  Map<String, dynamic> toJson() {
    return {
      if (idKendaraan != null) 'id_kendaraan': idKendaraan,
      'plat_nomor': platNomor,
      'jenis_kendaraan': jenisKendaraan,
      if (warna != null) 'warna': warna,
      if (pemilik != null) 'pemilik': pemilik,
    };
  }
}
