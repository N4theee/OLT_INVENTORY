import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/constants/app_theme.dart';
import 'package:olt_inventory/models/department_model.dart';
import 'package:olt_inventory/models/inventory_item_model.dart';
import 'package:olt_inventory/models/inventory_report_model.dart';
import 'package:olt_inventory/providers/department_provider.dart';
import 'package:olt_inventory/screens/department_items_screen.dart';
import 'package:olt_inventory/screens/reports_screen.dart';
import 'package:olt_inventory/services/department_service.dart';
import 'package:olt_inventory/services/report_service.dart';
import 'package:olt_inventory/widgets/app_safe_area.dart';
import 'package:olt_inventory/widgets/department_card.dart';

class MemoryDepartments implements DepartmentService {
  @override
  Future<List<Department>> getDepartments() async {
    final names = [...AppConstants.defaultDepartments]..sort();
    return [
      for (final name in names)
        Department(id: name, departmentName: name, createdAt: DateTime(2026)),
    ];
  }

  @override
  Future<List<Department>> getDepartmentsWithStats() => getDepartments();

  @override
  Future<void> resetDepartments() async {}
}

class MemoryReports implements ReportService {
  @override
  Future<List<InventoryItem>> previewItems({
    String? departmentId,
    String? cedCategory,
  }) async => [
    for (var i = 0; i < 15; i++)
      InventoryItem(
        id: '$i',
        productName: 'Inventory item $i',
        quantity: 2,
        departmentId: 'Youth Department',
        departmentName: 'Youth Department',
        status: 'Good condition',
        itemHolder: 'Church',
        dateAdded: DateTime(2026),
        lastUpdated: DateTime(2026),
      ),
  ];

  @override
  Future<InventoryReportData> generateReport({
    String? departmentId,
    String? departmentName,
    String? cedCategory,
  }) async => InventoryReportData.build(
    filterDepartmentName: departmentName ?? 'All Departments',
    items: await previewItems(),
  );
}

Widget testApp(Widget screen, {double textScale = 1}) {
  return ChangeNotifierProvider(
    create: (_) => DepartmentProvider(service: MemoryDepartments()),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: AppSafeArea(child: child!),
      ),
      home: screen,
    ),
  );
}

void configureScreen(
  WidgetTester tester,
  Size size, {
  double bottom = 48,
  double side = 0,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = FakeViewPadding(
    top: 24,
    bottom: bottom,
    left: side,
    right: side,
  );
  tester.view.viewPadding = FakeViewPadding(
    top: 24,
    bottom: bottom,
    left: side,
    right: side,
  );
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'Last department remains fully above Android navigation buttons',
    (tester) async {
      configureScreen(tester, const Size(360, 640));
      await tester.pumpWidget(testApp(const DepartmentItemsScreen()));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Youth Department'), 300);
      await tester.pumpAndSettle();
      final card = find.ancestor(
        of: find.text('Youth Department'),
        matching: find.byType(DepartmentCard),
      );
      final rect = tester.getRect(card);
      expect(rect.bottom, lessThanOrEqualTo(640 - 48));
      expect(find.text('Youth Department').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1280, 720),
  ]) {
    testWidgets('Report actions stay accessible at $size with large text', (
      tester,
    ) async {
      final side = size.width > size.height ? 24.0 : 0.0;
      configureScreen(tester, size, side: side);
      await tester.pumpWidget(
        testApp(ReportsScreen(reportService: MemoryReports()), textScale: 1.5),
      );
      await tester.pumpAndSettle();
      final printButton = find.widgetWithText(ElevatedButton, 'Print Report');
      await tester.scrollUntilVisible(printButton, 250, maxScrolls: 60);
      await tester.pumpAndSettle();
      var rect = tester.getRect(printButton);
      expect(rect.bottom, lessThanOrEqualTo(size.height - 48));
      expect(rect.left, greaterThanOrEqualTo(side));
      expect(rect.right, lessThanOrEqualTo(size.width - side));
      expect(printButton.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Generate Report'),
        -300,
        maxScrolls: 60,
      );
      await tester.tap(find.text('Generate Report'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        printButton,
        400,
        maxScrolls: 100,
        scrollable: find.byWidgetPredicate(
          (widget) => widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      await tester.pumpAndSettle();
      rect = tester.getRect(printButton);
      expect(rect.bottom, lessThanOrEqualTo(size.height - 48));
      expect(printButton.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Safe area follows gesture navigation and keyboard insets', (
    tester,
  ) async {
    configureScreen(tester, const Size(390, 844), bottom: 24);
    const actionKey = ValueKey('bottom-action');
    await tester.pumpWidget(
      testApp(
        const Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(key: actionKey, width: 100, height: 48),
          ),
        ),
      ),
    );
    expect(tester.getRect(find.byKey(actionKey)).bottom, 820);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.view.padding = const FakeViewPadding(top: 24);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(actionKey)).bottom, 544);
    expect(tester.takeException(), isNull);
  });
}
