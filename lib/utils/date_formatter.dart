import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateTime = DateFormat('MMM d, yyyy • h:mm a');
  static final DateFormat _dateOnly = DateFormat('MMM d, yyyy');

  static String formatDateTime(DateTime date) => _dateTime.format(date);

  static String formatDate(DateTime date) => _dateOnly.format(date);

  static final DateFormat _reportDate = DateFormat('MMMM d, yyyy');
  static final DateFormat _reportTime = DateFormat('h:mm a');

  static String formatReportDate(DateTime date) => _reportDate.format(date);

  static String formatReportTime(DateTime date) => _reportTime.format(date);
}
