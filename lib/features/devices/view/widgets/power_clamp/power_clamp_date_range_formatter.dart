import 'package:intl/intl.dart';

abstract final class PowerClampDateRangeFormatter {
  static String monthRange(DateTime selectedDate) {
    final firstDay = DateTime(selectedDate.year, selectedDate.month);
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final dateFormat = DateFormat('dd/MM/yyyy');
    return '${dateFormat.format(firstDay)} - ${dateFormat.format(lastDay)}';
  }
}
