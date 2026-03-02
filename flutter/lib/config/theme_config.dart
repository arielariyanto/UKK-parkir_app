import 'package:flutter/material.dart';

// Konfigurasi tema visual aplikasi secara global
// Semua warna, gradient, dan gaya komponen UI didefinisikan di sini
// agar tampilan aplikasi konsisten di seluruh halaman
class AppTheme {
  // === Palet Warna Utama ===
  static const Color primaryColor = Color(0xFF6366F1);   // Indigo - warna aksi utama
  static const Color secondaryColor = Color(0xFF8B5CF6); // Ungu - warna pendukung
  static const Color accentColor = Color(0xFF10B981);    // Hijau - warna sukses/positif
  static const Color errorColor = Color(0xFFEF4444);     // Merah - warna error/bahaya
  static const Color warningColor = Color(0xFFF59E0B);   // Amber - warna peringatan
  
  // === Warna Latar & Teks ===
  static const Color backgroundColor = Color(0xFFF9FAFB); // Latar belakang halaman (abu sangat terang)
  static const Color surfaceColor = Colors.white;          // Warna permukaan card dan dialog
  static const Color textPrimaryColor = Color(0xFF111827); // Teks utama (hampir hitam)
  static const Color textSecondaryColor = Color(0xFF6B7280); // Teks sekunder (abu-abu)
  
  // === Gradient ===
  // Gradient dari kiri atas (indigo) ke kanan bawah (ungu) untuk header dan splash
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // === Tema Terang Global Material 3 ===
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true, // Gunakan komponen Material Design 3 terbaru
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundColor, // Latar semua halaman

    // Gaya AppBar - putih bersih tanpa bayangan
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimaryColor),
      titleTextStyle: TextStyle(
        color: textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Gaya Card - sudut membulat dengan bayangan tipis
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: surfaceColor,
    ),

    // Gaya tombol ElevatedButton - indigo dengan teks putih
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    ),

    // Gaya input field - latar abu terang dengan border membulat
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      // Border biru/indigo saat field sedang aktif/difokuskan
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      // Border merah saat ada error validasi
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
