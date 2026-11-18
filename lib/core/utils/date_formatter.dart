import 'package:intl/intl.dart';

class DateFormatterHelper {
  static String formatShort(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  static String formatLong(DateTime dateTime) {
    return DateFormat('EEEE, dd MMMM yyyy').format(dateTime);
  }
}
