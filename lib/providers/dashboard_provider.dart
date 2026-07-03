import 'package:flutter/foundation.dart';
import 'package:olt_inventory/models/department_model.dart';
import 'package:olt_inventory/models/inventory_item_model.dart';
import 'package:olt_inventory/models/inventory_log_model.dart';
import 'package:olt_inventory/services/inventory_service.dart';
import 'package:olt_inventory/services/log_service.dart';
import 'package:olt_inventory/services/department_service.dart';
import 'package:olt_inventory/constants/app_constants.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    InventoryService? inventoryService,
    LogService? logService,
    DepartmentService? departmentService,
  })  : _inventoryService = inventoryService ?? InventoryService(),
        _logService = logService ?? LogService(),
        _departmentService = departmentService ?? DepartmentService();

  final InventoryService _inventoryService;
  final LogService _logService;
  final DepartmentService _departmentService;

  Map<String, int> _stats = {};
  List<InventoryItem> _recentItems = [];
  List<Department> _departmentStats = [];
  List<InventoryLog> _recentLogs = [];
  bool _isLoading = false;
  String? _error;

  Map<String, int> get stats => _stats;
  List<InventoryItem> get recentItems => _recentItems;
  List<Department> get departmentStats => _departmentStats;
  List<InventoryLog> get recentLogs => _recentLogs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _inventoryService.getDashboardStats(),
        _inventoryService.getRecentItems(limit: AppConstants.recentItemsLimit),
        _departmentService.getDepartmentsWithStats(),
        _logService.getLogs(page: 0, pageSize: 20),
      ]);

      _stats = results[0] as Map<String, int>;
      _recentItems = results[1] as List<InventoryItem>;
      _departmentStats = results[2] as List<Department>;
      _recentLogs = results[3] as List<InventoryLog>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
