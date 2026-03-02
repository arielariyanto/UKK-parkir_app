// Model data untuk Transaksi Parkir
// Merepresentasikan satu sesi parkir kendaraan, dari masuk hingga keluar
// Field dari JOIN tabel lain (platNomor, jenisKendaraan, dll.) ditandai dengan komentar
class Transaksi {
  // === Data Inti Transaksi (dari tabel transaksi/parkir) ===
  final int? idParkir;     
  final int? idKendaraan;  
  final int? idArea;       
  final DateTime? waktuMasuk; 
  final DateTime? waktuKeluar; 
  final int? durasiJam;   
  final int? biayaTotal;    
  final String? status;    
  final int? idUser;      
  
  // === Data Tambahan dari JOIN Tabel Lain ===
  final String? platNomor;      
  final String? jenisKendaraan; 
  final String? namaArea;       
  final String? petugas;        
  final int? tarifPerJam;       

  Transaksi({
    this.idParkir,
    this.idKendaraan,
    this.idArea,
    this.waktuMasuk,
    this.waktuKeluar,
    this.durasiJam,
    this.biayaTotal,
    this.status,
    this.idUser,
    this.platNomor,
    this.jenisKendaraan,
    this.namaArea,
    this.petugas,
    this.tarifPerJam,
  });

  // Factory constructor: membuat objek Transaksi dari data JSON respons API
  // Menangani tipe data yang beragam (int/String) dan nilai null
  factory Transaksi.fromJson(Map<String, dynamic> json) {
    return Transaksi(
      idParkir: json['id_parkir'],
      idKendaraan: json['id_kendaraan'],
      idArea: json['id_area'],
      // Parse string waktu ISO 8601 ke DateTime
      waktuMasuk: json['waktu_masuk'] != null 
          ? DateTime.parse(json['waktu_masuk']) 
          : null,
      waktuKeluar: json['waktu_keluar'] != null 
          ? DateTime.parse(json['waktu_keluar']) 
          : null,
      durasiJam: json['durasi_jam'],
      // biaya_total bisa berupa String atau int; parse jika String
      biayaTotal: json['biaya_total'] is String 
          ? int.parse(json['biaya_total']) 
          : json['biaya_total'],
      status: json['status'],
      idUser: json['id_user'],
      platNomor: json['plat_nomor'],
      jenisKendaraan: json['jenis_kendaraan'],
      namaArea: json['nama_area'],
      // Nama petugas bisa berada di field 'petugas' atau 'nama_lengkap' tergantung endpoint
      petugas: json['petugas'] ?? json['nama_lengkap'],
      // tarif_per_jam bisa berupa String atau int; parse jika String
      tarifPerJam: json['tarif_per_jam'] is String 
          ? int.parse(json['tarif_per_jam']) 
          : json['tarif_per_jam'],
    );
  }
}
