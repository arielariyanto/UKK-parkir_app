import 'package:intl/intl.dart';

class Helpers {
  // Format currency to Rupiah
  static String formatRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';
    
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    
    return formatter.format(amount is String ? int.parse(amount) : amount);
  }

  // Format date time
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  // Format date only
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(dateTime);
  }

  // Calculate duration in hours
  static int calculateDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    return hours < 1 ? 1 : hours; // Minimum 1 hour
  }

  // Format duration
  static String formatDuration(int hours) {
    return '$hours jam';
  }
}
