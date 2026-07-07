import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:olt_inventory/models/inventory_item_model.dart';
import 'package:olt_inventory/services/inventory_service.dart';

class InventoryProvider extends ChangeNotifier {
  InventoryProvider({InventoryService? service})
      : _service = service ?? InventoryService();

  final InventoryService _service;

  List<InventoryItem> _items = [];
  List<InventoryItem> _deletedItems = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _error;

  String _search = '';
  String? _departmentFilter;
  String? _statusFilter;
  ItemSortOption _sort = ItemSortOption.newest;

  List<InventoryItem> get items => _items;
  List<InventoryItem> get deletedItems => _deletedItems;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get search => _search;
  String? get departmentFilter => _departmentFilter;
  String? get statusFilter => _statusFilter;
  ItemSortOption get sort => _sort;

  Future<void> loadItems({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _items = [];
    }
    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final page = refresh ? 0 : _currentPage;
      final result = await _service.getActiveItems(
        page: page,
        search: _search.isEmpty ? null : _search,
        departmentId: _departmentFilter,
        status: _statusFilter,
        sort: _sort,
      );

      if (refresh) {
        _items = result;
      } else {
        _items = [..._items, ...result];
      }

      _hasMore = result.length >= 20;
      _currentPage = page + 1;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDeletedItems({bool refresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _deletedItems = await _service.getDeletedItems(page: 0);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<InventoryItem>> loadDepartmentItems(
    String departmentId, {
    int page = 0,
    String? search,
    String? status,
    String? cedCategory,
    ItemSortOption sort = ItemSortOption.newest,
  }) async {
    return _service.getItemsByDepartment(
      departmentId,
      page: page,
      search: search,
      status: status,
      cedCategory: cedCategory,
      sort: sort,
    );
  }

  Future<InventoryItem?> getItemById(String id) => _service.getItemById(id);

  void setSearch(String value) {
    _search = value;
    loadItems(refresh: true);
  }

 void setDepartmentFilter(String? value) {
  _departmentFilter = value == null || value.isEmpty ? null : value;
  loadItems(refresh: true);
}

  void setStatusFilter(String? value) {
  _statusFilter = value == null || value.isEmpty ? null : value;
  loadItems(refresh: true);
}

  void setSort(ItemSortOption value) {
    _sort = value;
    loadItems(refresh: true);
  }

  Future<InventoryItem?> addItem({
    required String productName,
    required int quantity,
    required String departmentId,
    required String status,
    required String itemHolder,
    String? notes,
    String? cedCategory,
    XFile? imageFile,
    required String departmentName,
  }) async {
    try {
      final item = await _service.addItem(
        productName: productName,
        quantity: quantity,
        departmentId: departmentId,
        status: status,
        itemHolder: itemHolder,
        notes: notes,
        cedCategory: cedCategory,
        imageFile: imageFile,
        departmentName: departmentName,
      );
      await loadItems(refresh: true);
      _error = null;
      notifyListeners();
      return item;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateItem({
    required InventoryItem item,
    required String productName,
    required int quantity,
    required String departmentId,
    required String status,
    required String itemHolder,
    String? notes,
    String? cedCategory,
    XFile? newImageFile,
    bool removeImage = false,
    required String departmentName,
  }) async {
    try {
      await _service.updateItem(
        item: item,
        productName: productName,
        quantity: quantity,
        departmentId: departmentId,
        status: status,
        itemHolder: itemHolder,
        notes: notes,
        cedCategory: cedCategory,
        newImageFile: newImageFile,
        removeImage: removeImage,
        departmentName: departmentName,
      );
      await loadItems(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> softDeleteItem(InventoryItem item) async {
    try {
      await _service.softDeleteItem(item);
      await loadItems(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreItem(InventoryItem item) async {
    try {
      await _service.restoreItem(item);
      await loadDeletedItems(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> permanentlyDeleteItem(InventoryItem item) async {
    try {
      await _service.permanentlyDeleteItem(item);
      await loadDeletedItems(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearAllInventory() async {
    try {
      await _service.clearAllInventory();
      _items = [];
      _deletedItems = [];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
