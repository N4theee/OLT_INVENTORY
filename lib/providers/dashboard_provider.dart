import 'package:flutter/foundation.dart';
import 'package:olt_inventory/models/department_model.dart';
import 'package:olt_inventory/services/inventory_service.dart';
import 'package:olt_inventory/services/department_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    InventoryService? inventoryService,
    DepartmentService? departmentService,
  })  : _inventoryService = inventoryService ?? InventoryService(),
        _departmentService = departmentService ?? DepartmentService();

  final InventoryService _inventoryService;
  final DepartmentService _departmentService;

  Map<String, int> _stats = {};
  List<Department> _departmentStats = [];
  bool _isLoading = false;
  String? _error;

  Map<String, int> get stats => _stats;
  List<Department> get departmentStats => _departmentStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _inventoryService.getDashboardStats();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    try {
      _departmentStats = await _departmentService.getDepartmentsWithStats();
    } catch (_) {
      _departmentStats = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}