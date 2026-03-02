import 'package:intl/intl.dart';

// Kumpulan fungsi utilitas umum yang digunakan di seluruh aplikasi
// Berisi pemformatan angka, tanggal, dan perhitungan durasi
class Helpers {
  // Mengubah angka menjadi format mata uang Rupiah Indonesia
  // Contoh: 15000 -> "Rp 15.000"
  // Parameter [amount] dapat berupa int, double, atau String angka
  static String formatRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0'; // Kembalikan nilai default jika null
    
    final formatter = NumberFormat.currency(
      locale: 'id_ID',       // Format angka gaya Indonesia (titik sebagai pemisah ribuan)
      symbol: 'Rp ',         // Simbol mata uang
      decimalDigits: 0,      // Tidak tampilkan desimal karena Rupiah tidak menggunakan koma
    );
    
    // Jika amount berupa String, parse ke int terlebih dahulu
    return formatter.format(amount is String ? int.parse(amount) : amount);
  }

  // Mengubah objek DateTime menjadi string format tanggal dan jam
  // Contoh: "25/12/2024 14:30"
  // Mengembalikan '-' jika dateTime bernilai null
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  // Mengubah objek DateTime menjadi string format tanggal saja (tanpa jam)
  // Contoh: "25/12/2024"
  // Mengembalikan '-' jika dateTime bernilai null
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(dateTime);
  }

  // Menghitung durasi parkir dalam jam (pembulatan ke atas)
  // Jika durasi kurang dari 1 jam, tetap dihitung 1 jam (tarif minimum)
  // Parameter: [start] waktu kendaraan masuk, [end] waktu kendaraan keluar
  static int calculateDuration(DateTime start, DateTime end) {
    final duration = end.difference(start); // Selisih waktu
    final hours = duration.inHours;         // Konversi ke jam (pembulatan bawah)
    return hours < 1 ? 1 : hours;           // Minimum 1 jam
  }

  // Memformat jumlah jam menjadi teks yang mudah dibaca
  // Contoh: 3 -> "3 jam"
  static String formatDuration(int hours) {
    return '$hours jam';
  }
}
