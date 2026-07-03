class InventoryLog {
  const InventoryLog({
    required this.id,
    required this.itemId,
    required this.action,
    required this.description,
    required this.createdAt,
    this.itemName,
  });

  final String id;
  final String itemId;
  final String action;
  final String description;
  final DateTime createdAt;
  final String? itemName;

  factory InventoryLog.fromJson(Map<String, dynamic> json) {
    final items = json['inventory_items'];
    String? name;
    if (items is Map<String, dynamic>) {
      name = items['product_name'] as String?;
    }

    return InventoryLog(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      action: json['action'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      itemName: name ?? json['item_name'] as String?,
    );
  }
}
