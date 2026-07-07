import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/models/inventory_item_model.dart';

class ReportDepartmentStat {
  const ReportDepartmentStat({
    required this.departmentName,
    required this.totalItems,
    required this.totalQuantity,
  });

  final String departmentName;
  final int totalItems;
  final int totalQuantity;
}

class ReportStatusStat {
  const ReportStatusStat({
    required this.status,
    required this.totalItems,
    required this.totalQuantity,
  });

  final String status;
  final int totalItems;
  final int totalQuantity;
}

class InventoryReportData {
  const InventoryReportData({
    required this.filterDepartmentName,
    required this.reportType,
    required this.items,
    required this.totalItems,
    required this.totalQuantity,
    required this.goodConditionQuantity,
    required this.needsRepairQuantity,
    required this.depreciatedQuantity,
    required this.fifthMetricLabel,
    required this.fifthMetricValue,
    required this.departmentStats,
    required this.statusStats,
    required this.generatedAt,
  });

  final String filterDepartmentName;
  final String reportType;
  final List<InventoryItem> items;
  final int totalItems;
  final int totalQuantity;
  final int goodConditionQuantity;
  final int needsRepairQuantity;
  final int depreciatedQuantity;
  final String fifthMetricLabel;
  final int fifthMetricValue;
  final List<ReportDepartmentStat> departmentStats;
  final List<ReportStatusStat> statusStats;
  final DateTime generatedAt;

  static InventoryReportData build({
    required String filterDepartmentName,
    required List<InventoryItem> items,
    String? cedCategoryFilter,
  }) {
    final isCed = filterDepartmentName == 'CED' ||
        (cedCategoryFilter != null && cedCategoryFilter.isNotEmpty);

    int totalQuantity = 0;
    int goodQty = 0;
    int repairQty = 0;
    int depreciatedQty = 0;
    int goodItems = 0;
    int repairItems = 0;
    int depreciatedItems = 0;

    final deptMap = <String, ({int items, int qty})>{};
    final cedGroups = <String>{};

    for (final item in items) {
      totalQuantity += item.quantity;
      final dept = item.departmentName ?? 'Uncategorized';

      final deptEntry = deptMap[dept];
      deptMap[dept] = (
        items: (deptEntry?.items ?? 0) + 1,
        qty: (deptEntry?.qty ?? 0) + item.quantity,
      );

      switch (item.status) {
        case AppConstants.statusGoodCondition:
          goodQty += item.quantity;
          goodItems++;
        case AppConstants.statusNeedsRepair:
          repairQty += item.quantity;
          repairItems++;
        case AppConstants.statusDepreciated:
          depreciatedQty += item.quantity;
          depreciatedItems++;
      }

      if (item.cedCategory != null && item.cedCategory!.isNotEmpty) {
        cedGroups.add(item.cedCategory!);
      }
    }

    final departmentStats = deptMap.entries
        .map(
          (e) => ReportDepartmentStat(
            departmentName: e.key,
            totalItems: e.value.items,
            totalQuantity: e.value.qty,
          ),
        )
        .toList()
      ..sort((a, b) => a.departmentName.compareTo(b.departmentName));

    final statusStats = <ReportStatusStat>[
      ReportStatusStat(
        status: AppConstants.statusGoodCondition,
        totalItems: goodItems,
        totalQuantity: goodQty,
      ),
      ReportStatusStat(
        status: AppConstants.statusNeedsRepair,
        totalItems: repairItems,
        totalQuantity: repairQty,
      ),
      ReportStatusStat(
        status: AppConstants.statusDepreciated,
        totalItems: depreciatedItems,
        totalQuantity: depreciatedQty,
      ),
      ReportStatusStat(
        status: 'TOTAL',
        totalItems: items.length,
        totalQuantity: totalQuantity,
      ),
    ];

    String fifthLabel;
    int fifthValue;
    if (isCed && cedGroups.isNotEmpty) {
      fifthLabel = 'CED GROUPS';
      fifthValue = cedGroups.length;
    } else if (filterDepartmentName == 'All Departments') {
      fifthLabel = 'DEPARTMENTS';
      fifthValue = deptMap.length;
    } else {
      fifthLabel = 'ITEM LINES';
      fifthValue = items.length;
    }

    final reportType = cedCategoryFilter != null
        ? 'CED Department Report ($cedCategoryFilter)'
        : filterDepartmentName == 'All Departments'
            ? 'Full Inventory Report'
            : 'Department Inventory Report';

    return InventoryReportData(
      filterDepartmentName: cedCategoryFilter != null
          ? 'CED — $cedCategoryFilter'
          : filterDepartmentName,
      reportType: reportType,
      items: items,
      totalItems: items.length,
      totalQuantity: totalQuantity,
      goodConditionQuantity: goodQty,
      needsRepairQuantity: repairQty,
      depreciatedQuantity: depreciatedQty,
      fifthMetricLabel: fifthLabel,
      fifthMetricValue: fifthValue,
      departmentStats: departmentStats,
      statusStats: statusStats,
      generatedAt: DateTime.now(),
    );
  }

  static String itemDetails(InventoryItem item) {
    final parts = <String>['Qty: ${item.quantity}'];
    if (item.departmentName != null && item.departmentName!.isNotEmpty) {
      parts.add('Dept: ${item.departmentName}');
    }
    if (item.cedCategory != null && item.cedCategory!.isNotEmpty) {
      parts.add('Group: ${item.cedCategory}');
    }
    return parts.join(' • ');
  }

  static String ownedBy(InventoryItem item) => item.itemHolder;

  static String itemIdDisplay(InventoryItem item, int fallbackIndex) {
    return item.itemCode ?? '$fallbackIndex';
  }
}
