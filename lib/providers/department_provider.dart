import 'package:flutter/foundation.dart';
import 'package:olt_inventory/models/department_model.dart';
import 'package:olt_inventory/services/department_service.dart';

class DepartmentProvider extends ChangeNotifier {
  DepartmentProvider({DepartmentService? service})
      : _service = service ?? DepartmentService();

  final DepartmentService _service;

  List<Department> _departments = [];
  bool _isLoading = false;
  String? _error;

  List<Department> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDepartments({bool withStats = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _departments = withStats
          ? await _service.getDepartmentsWithStats()
          : await _service.getDepartments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetDepartments() async {
    try {
      await _service.resetDepartments();
      await loadDepartments(withStats: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Department? findById(String id) {
    try {
      return _departments.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
