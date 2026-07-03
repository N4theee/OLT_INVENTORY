import 'package:olt_inventory/models/inventory_item_model.dart';
import 'package:olt_inventory/models/inventory_report_model.dart';
import 'package:olt_inventory/services/inventory_service.dart';

class ReportService {
  ReportService({InventoryService? inventoryService})
      : _inventoryService = inventoryService ?? InventoryService();

  final InventoryService _inventoryService;

  Future<InventoryReportData> generateReport({
    String? departmentId,
    String? departmentName,
    String? cedCategory,
  }) async {
    final items = await _inventoryService.getReportItems(
      departmentId: departmentId,
      cedCategory: cedCategory,
    );

    final filterName = departmentName ?? 'All Departments';

    return InventoryReportData.build(
      filterDepartmentName: filterName,
      items: items,
      cedCategoryFilter: cedCategory,
    );
  }

  Future<List<InventoryItem>> previewItems({
    String? departmentId,
    String? cedCategory,
  }) {
    return _inventoryService.getReportItems(
      departmentId: departmentId,
      cedCategory: cedCategory,
    );
  }
}
