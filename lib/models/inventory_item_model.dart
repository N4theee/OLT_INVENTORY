import 'package:olt_inventory/constants/app_constants.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.departmentId,
    required this.status,
    required this.itemHolder,
    this.imageUrl,
    this.imageUrls = const [],
    this.notes,
    this.cedCategory,
    this.itemCode,
    required this.dateAdded,
    required this.lastUpdated,
    this.isDeleted = false,
    this.departmentName,
  });

  final String id;
  final String productName;
  final int quantity;
  final String departmentId;
  final String status;
  final String itemHolder;
  final String? imageUrl;
  final List<String> imageUrls;
  final String? notes;
  final String? cedCategory;
  final String? itemCode;
  final DateTime dateAdded;
  final DateTime lastUpdated;
  final bool isDeleted;
  final String? departmentName;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final departments = json['departments'];
    String? deptName;
    if (departments is Map<String, dynamic>) {
      deptName = departments['department_name'] as String?;
    }

    final legacyImageUrl = json['image_url'] as String?;
    final storedImageUrls = (json['image_urls'] as List?)
            ?.whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList() ??
        const <String>[];
    final allImageUrls = storedImageUrls.isNotEmpty
        ? storedImageUrls
        : legacyImageUrl != null && legacyImageUrl.isNotEmpty
            ? <String>[legacyImageUrl]
            : const <String>[];

    return InventoryItem(
      id: json['id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      departmentId: json['department_id'] as String,
      status: json['status'] as String,
      itemHolder: json['item_holder'] as String? ?? AppConstants.defaultItemHolder,
      imageUrl: allImageUrls.isEmpty ? null : allImageUrls.first,
      imageUrls: allImageUrls,
      notes: json['notes'] as String?,
      cedCategory: json['ced_category'] as String?,
      itemCode: json['item_code'] as String?,
      dateAdded: DateTime.parse(json['date_added'] as String),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
      departmentName: deptName ?? json['department_name'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'product_name': productName,
      'quantity': quantity,
      'department_id': departmentId,
      'status': status,
      'item_holder': itemHolder,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'notes': notes,
      'ced_category': cedCategory,
      'item_code': itemCode,
      'date_added': dateAdded.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'product_name': productName,
      'quantity': quantity,
      'department_id': departmentId,
      'status': status,
      'item_holder': itemHolder,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'notes': notes,
      'ced_category': cedCategory,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? productName,
    int? quantity,
    String? departmentId,
    String? status,
    String? itemHolder,
    String? imageUrl,
    List<String>? imageUrls,
    String? notes,
    String? cedCategory,
    String? itemCode,
    DateTime? dateAdded,
    DateTime? lastUpdated,
    bool? isDeleted,
    String? departmentName,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      departmentId: departmentId ?? this.departmentId,
      status: status ?? this.status,
      itemHolder: itemHolder ?? this.itemHolder,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      notes: notes ?? this.notes,
      cedCategory: cedCategory ?? this.cedCategory,
      itemCode: itemCode ?? this.itemCode,
      dateAdded: dateAdded ?? this.dateAdded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isDeleted: isDeleted ?? this.isDeleted,
      departmentName: departmentName ?? this.departmentName,
    );
  }
}
