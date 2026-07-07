import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/models/inventory_item_model.dart';
import 'package:olt_inventory/services/log_service.dart';
import 'package:olt_inventory/services/storage_service.dart';
import 'package:olt_inventory/services/supabase_service.dart';
import 'package:olt_inventory/utils/item_code_generator.dart';

enum ItemSortOption { name, quantity, newest, oldest }

class InventoryService {
  InventoryService({
    SupabaseClient? client,
    LogService? logService,
    StorageService? storageService,
  })  : _client = client ?? SupabaseService.client,
        _logService = logService ?? LogService(),
        _storageService = storageService ?? StorageService();

  final SupabaseClient _client;
  final LogService _logService;
  final StorageService _storageService;

  static const _selectQuery = '*, departments(department_name)';

  Future<List<InventoryItem>> getActiveItems({
    int page = 0,
    int pageSize = AppConstants.pageSize,
    String? search,
    String? departmentId,
    String? status,
    String? cedCategory,
    ItemSortOption sort = ItemSortOption.newest,
  }) async {
    dynamic query = _client
        .from('inventory_items')
        .select(_selectQuery)
        .eq('is_deleted', false);

    query = _applyFilters(
      query,
      search: search,
      status: status,
      cedCategory: cedCategory,
    );

    if (departmentId != null && departmentId.isNotEmpty) {
      query = query.eq('department_id', departmentId);
    }

    query = _applySort(query, sort);

    final from = page * pageSize;
    final to = from + pageSize - 1;
    query = query.range(from, to);

    final response = await query;
    return _mapItems(response);
  }

  Future<List<InventoryItem>> getItemsByDepartment(
    String departmentId, {
    int page = 0,
    int pageSize = AppConstants.pageSize,
    String? search,
    String? status,
    String? cedCategory,
    ItemSortOption sort = ItemSortOption.newest,
  }) async {
    dynamic query = _client
        .from('inventory_items')
        .select(_selectQuery)
        .eq('is_deleted', false)
        .eq('department_id', departmentId);

    query = _applyFilters(
      query,
      search: search,
      status: status,
      cedCategory: cedCategory,
    );

    query = _applySort(query, sort);

    final response = await query.range(
      page * pageSize,
      (page + 1) * pageSize - 1,
    );

    return _mapItems(response);
  }

  Future<List<InventoryItem>> getDeletedItems({
    int page = 0,
    int pageSize = AppConstants.pageSize,
  }) async {
    final response = await _client
        .from('inventory_items')
        .select(_selectQuery)
        .eq('is_deleted', true)
        .order('last_updated', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return _mapItems(response);
  }

  Future<List<InventoryItem>> getRecentItems({int limit = 10}) async {
    final response = await _client
        .from('inventory_items')
        .select(_selectQuery)
        .eq('is_deleted', false)
        .order('date_added', ascending: false)
        .limit(limit);

    return _mapItems(response);
  }

  Future<List<InventoryItem>> getReportItems({
    String? departmentId,
    String? cedCategory,
  }) async {
    dynamic query = _client
        .from('inventory_items')
        .select(_selectQuery)
        .eq('is_deleted', false);

    if (departmentId != null && departmentId.isNotEmpty) {
      query = query.eq('department_id', departmentId);
    }
    if (cedCategory != null && cedCategory.isNotEmpty) {
      query = query.eq('ced_category', cedCategory);
    }

    query = query.order('product_name', ascending: true);

    final response = await query;
    return _mapItems(response);
  }

  Future<List<InventoryItem>> getLowStockItems({
    int threshold = AppConstants.lowStockThreshold,
  }) async {
    final response = await _client
        .from('inventory_items')
        .select(_selectQuery)
        .eq('is_deleted', false)
        .lte('quantity', threshold)
        .order('quantity', ascending: true);

    return _mapItems(response);
  }

  Future<InventoryItem?> getItemById(String id) async {
    final response = await _client
        .from('inventory_items')
        .select(_selectQuery)
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return InventoryItem.fromJson(response);
  }

  Future<Map<String, int>> getDashboardStats() async {
    final activeItems = await _client
        .from('inventory_items')
        .select('quantity, status')
        .eq('is_deleted', false);

    final departments = await _client.from('departments').select('id');

    int totalQuantity = 0;
    int goodCondition = 0;
    int needsRepair = 0;
    int depreciated = 0;

    for (final row in activeItems as List) {
      totalQuantity += row['quantity'] as int;
      switch (row['status'] as String) {
        case AppConstants.statusGoodCondition:
          goodCondition++;
        case AppConstants.statusNeedsRepair:
          needsRepair++;
        case AppConstants.statusDepreciated:
          depreciated++;
      }
    }

    return {
      'totalItems': (activeItems as List).length,
      'totalQuantity': totalQuantity,
      'totalDepartments': (departments as List).length,
      'goodCondition': goodCondition,
      'needsRepair': needsRepair,
      'depreciated': depreciated,
    };
  }

  Future<InventoryItem> addItem({
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
    String? imageUrl;

    if (imageFile != null) {
      try {
        imageUrl = await _storageService.uploadXFile(imageFile);
      } catch (e) {
        throw Exception(
          'Image upload failed: ${StorageService.formatStorageError(e)}',
        );
      }
    }

    final itemCode = await generateItemCode(
      departmentName: departmentName,
      productName: productName,
      cedCategory: cedCategory,
    );

    final payload = <String, dynamic>{
      'item_code': itemCode,
      'product_name': productName,
      'quantity': quantity,
      'department_id': departmentId,
      'status': status,
      'item_holder': itemHolder,
      'image_url': imageUrl,
      'notes': notes,
      'is_deleted': false,
    };
    if (cedCategory != null) {
      payload['ced_category'] = cedCategory;
    }

    Map<String, dynamic> response;
    try {
      response = await _client
          .from('inventory_items')
          .insert(payload)
          .select('*')
          .single();
    } catch (e) {
      if (imageUrl != null) {
        await _storageService.deleteImage(imageUrl);
      }
      throw Exception(_formatError(e));
    }

    final item = InventoryItem.fromJson({
      ...response,
      'department_name': departmentName,
    });

    try {
      await _logService.createLog(
        itemId: item.id,
        action: 'Added',
        description: _buildAddedLogDescription(
          itemCode: itemCode,
          quantity: quantity,
          productName: productName,
          departmentName: departmentName,
          cedCategory: cedCategory,
        ),
      );
    } catch (_) {
      // Item was saved; don't fail the whole operation if logging fails.
    }

    return item;
  }

  Future<InventoryItem> updateItem({
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
    String? imageUrl = item.imageUrl;

    if (removeImage && item.imageUrl != null) {
      await _storageService.deleteImage(item.imageUrl);
      imageUrl = null;
    } else if (newImageFile != null) {
      if (item.imageUrl != null) {
        await _storageService.deleteImage(item.imageUrl);
      }
      try {
        imageUrl = await _storageService.uploadXFile(newImageFile);
      } catch (e) {
        throw Exception(
          'Image upload failed: ${StorageService.formatStorageError(e)}',
        );
      }
    }

    final updatePayload = <String, dynamic>{
      'product_name': productName,
      'quantity': quantity,
      'department_id': departmentId,
      'status': status,
      'item_holder': itemHolder,
      'image_url': imageUrl,
      'notes': notes,
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    };
    if (cedCategory != null) {
      updatePayload['ced_category'] = cedCategory;
    } else {
      updatePayload['ced_category'] = null;
    }

    final response = await _client
        .from('inventory_items')
        .update(updatePayload)
        .eq('id', item.id)
        .select('*')
        .single();

    final updated = InventoryItem.fromJson({
      ...response,
      'department_name': departmentName,
    });

    try {
      await _logService.createLog(
        itemId: updated.id,
        action: 'Updated',
        description: 'Updated $productName',
      );
    } catch (_) {}

    return updated;
  }

  Future<void> softDeleteItem(InventoryItem item) async {
    await _client
        .from('inventory_items')
        .update({
          'is_deleted': true,
          'last_updated': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', item.id);

    await _logService.createLog(
      itemId: item.id,
      action: 'Deleted',
      description: 'Moved ${item.productName} to Deleted Items',
    );
  }

  Future<void> restoreItem(InventoryItem item) async {
    await _client
        .from('inventory_items')
        .update({
          'is_deleted': false,
          'last_updated': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', item.id);

    await _logService.createLog(
      itemId: item.id,
      action: 'Restored',
      description: 'Restored ${item.productName}',
    );
  }

  Future<void> permanentlyDeleteItem(InventoryItem item) async {
    if (item.imageUrl != null) {
      await _storageService.deleteImage(item.imageUrl);
    }

    await _logService.createLog(
      itemId: item.id,
      action: 'Permanently Deleted',
      description: 'Permanently deleted ${item.productName}',
    );

    await _client.from('inventory_items').delete().eq('id', item.id);
  }

  Future<void> clearAllInventory() async {
    final items = await _client
        .from('inventory_items')
        .select('image_url');

    for (final row in items as List) {
      await _storageService.deleteImage(row['image_url'] as String?);
    }

    await _client
        .from('inventory_items')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');
    await _logService.clearAllLogs();
  }

  dynamic _applyFilters(
    dynamic query, {
    String? search,
    String? status,
    String? cedCategory,
  }) {
    if (search != null && search.trim().isNotEmpty) {
      final term = search.trim();
      query = query.or('product_name.ilike.%$term%,item_code.ilike.%$term%');
    }
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (cedCategory != null && cedCategory.isNotEmpty) {
      query = query.eq('ced_category', cedCategory);
    }
    return query;
  }

  dynamic _applySort(dynamic query, ItemSortOption sort) {
    switch (sort) {
      case ItemSortOption.name:
        return query.order('product_name', ascending: true);
      case ItemSortOption.quantity:
        return query.order('quantity', ascending: false);
      case ItemSortOption.newest:
        return query.order('date_added', ascending: false);
      case ItemSortOption.oldest:
        return query.order('date_added', ascending: true);
    }
  }

  String _buildAddedLogDescription({
    required String itemCode,
    required int quantity,
    required String productName,
    required String departmentName,
    String? cedCategory,
  }) {
    if (cedCategory != null && departmentName == AppConstants.cedDepartmentName) {
      return 'Added $itemCode — $quantity $productName to CED ($cedCategory)';
    }
    return 'Added $itemCode — $quantity $productName to $departmentName';
  }

  Future<String> generateItemCode({
    required String departmentName,
    required String productName,
    String? cedCategory,
  }) async {
    final baseCode = ItemCodeGenerator.buildBaseCode(
      departmentName: departmentName,
      productName: productName,
      cedCategory: cedCategory,
    );

    final existing = await _client
        .from('inventory_items')
        .select('item_code')
        .ilike('item_code', '$baseCode%');

    final codes = (existing as List)
        .map((row) => row['item_code'] as String?)
        .toList();
    final next = ItemCodeGenerator.nextSequenceNumber(codes, baseCode);
    return ItemCodeGenerator.formatCode(baseCode, next);
  }

  String _formatError(Object error) {
    if (error is PostgrestException) {
      return error.message;
    }
    if (error is StorageException) {
      return error.message;
    }
    return error.toString();
  }

  List<InventoryItem> _mapItems(dynamic response) {
    return (response as List)
        .map((json) => InventoryItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
