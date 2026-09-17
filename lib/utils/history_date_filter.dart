import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Local calendar dates; the service converts these to UTC query boundaries.
DateTimeRange historyPeriod(String period, DateTime selected) {
  switch (period) {
    case 'month':
      return DateTimeRange(
        start: DateTime(selected.year, selected.month),
        end: DateTime(selected.year, selected.month + 1, 0),
      );
    case 'year':
      return DateTimeRange(
        start: DateTime(selected.year),
        end: DateTime(selected.year, 12, 31),
      );
    default:
      final day = DateTime(selected.year, selected.month, selected.day);
      return DateTimeRange(start: day, end: day);
  }
}

Future<DateTime?> pickHistoryPeriod(
  BuildContext context,
  String period,
  DateTime initial,
) async {
  if (period == 'day') {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
  }
  var year = initial.year;
  var month = initial.month;
  return showDialog<DateTime>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(period == 'month' ? 'Select month' : 'Select year'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: year,
                decoration: const InputDecoration(labelText: 'Year'),
                items: [
                  for (var y = DateTime.now().year + 1; y >= 1900; y--)
                    DropdownMenuItem(value: y, child: Text('$y')),
                ],
                onChanged: (value) => setState(() => year = value!),
              ),
              if (period == 'month') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: month,
                  decoration: const InputDecoration(labelText: 'Month'),
                  items: [
                    for (var m = 1; m <= 12; m++)
                      DropdownMenuItem(
                        value: m,
                        child: Text(
                          DateFormat.MMMM().format(DateTime(2000, m)),
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => month = value!),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, DateTime(year, month)),
            child: const Text('Apply'),
          ),
        ],
      ),
    ),
  );
}
