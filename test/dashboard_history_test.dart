import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:olt_inventory/models/inventory_log_model.dart';
import 'package:olt_inventory/models/department_model.dart';
import 'package:olt_inventory/services/log_service.dart';
import 'package:olt_inventory/screens/activity_logs_screen.dart';
import 'package:olt_inventory/utils/history_date_filter.dart';
import 'package:olt_inventory/widgets/dashboard_charts.dart';

class PendingLogs extends LogService {
  PendingLogs()
    : super(
        client: SupabaseClient(
          'http://localhost',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  final requests = <Completer<List<InventoryLog>>>[];
  @override
  Future<List<InventoryLog>> getLogs({
    int page = 0,
    int pageSize = 20,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final pending = Completer<List<InventoryLog>>();
    requests.add(pending);
    return pending.future;
  }
}

InventoryLog entry(String name) => InventoryLog(
  id: name,
  itemId: name,
  action: 'Added',
  description: 'Added inventory',
  createdAt: DateTime(2026),
  itemName: name,
);

void main() {
  test('Calendar periods handle leap years and year boundaries', () {
    final february = historyPeriod('month', DateTime(2024, 2, 15));
    expect(february.start, DateTime(2024, 2, 1));
    expect(february.end, DateTime(2024, 2, 29));
    expect(
      historyPeriod('month', DateTime(2025, 2)).end,
      DateTime(2025, 2, 28),
    );
    expect(
      historyPeriod('year', DateTime(2025, 6)).end,
      DateTime(2025, 12, 31),
    );
    expect(
      historyPeriod('day', DateTime(2025, 12, 31, 18)).start,
      DateTime(2025, 12, 31),
    );
  });
  testWidgets('New filters supersede pending history requests', (tester) async {
    final service = PendingLogs();
    await tester.pumpWidget(
      MaterialApp(home: ActivityLogsScreen(logService: service)),
    );
    expect(service.requests.length, 1);
    await tester.tap(find.text('All'));
    await tester.pump();
    expect(service.requests.length, 2);
    service.requests[1].complete([entry('Latest result')]);
    await tester.pump();
    service.requests[0].complete([entry('Stale result')]);
    await tester.pumpAndSettle();
    expect(find.text('Latest result'), findsOneWidget);
    expect(find.text('Stale result'), findsNothing);
  });
  testWidgets('Month and year filters open explicit selectors', (tester) async {
    final service = PendingLogs();
    await tester.pumpWidget(
      MaterialApp(home: ActivityLogsScreen(logService: service)),
    );
    service.requests.first.complete([]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('Select month'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(find.text('Select year'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.requests.length, 1);
  });
  testWidgets('Charts render populated and empty data at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardCharts(
              stats: const {
                'goodCondition': 20,
                'needsRepair': 2,
                'depreciated': 1,
              },
              departments: [
                Department(
                  id: '1',
                  departmentName: 'Youth Department',
                  createdAt: DateTime(2026),
                  itemCount: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('20 (87%)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardCharts(stats: {}, departments: []),
          ),
        ),
      ),
    );
    expect(find.text('No inventory items yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
