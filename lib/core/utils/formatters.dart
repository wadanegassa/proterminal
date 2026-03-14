import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount) {
    return NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    ).format(amount);
  }

  static String compactCurrency(double amount) {
    return NumberFormat.compactCurrency(
      symbol: '\$',
      decimalDigits: 0,
    ).format(amount);
  }

  static String date(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  static String shortDate(DateTime date) {
    return DateFormat.MMMd().format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) {
      return DateFormat.yMMMd().format(date);
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static String initials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
