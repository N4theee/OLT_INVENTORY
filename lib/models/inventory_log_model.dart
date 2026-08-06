class InventoryLog {
  const InventoryLog({
    required this.id,
    required this.itemId,
    required this.action,
    required this.description,
    required this.createdAt,
    this.itemName,
    this.itemCode,
  });

  final String id;
  final String itemId;
  final String action;
  final String description;
  final DateTime createdAt;
  final String? itemName;
  final String? itemCode;

  factory InventoryLog.fromJson(Map<String, dynamic> json) {
    return InventoryLog(
      id: json['id']?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? '',
      itemName: json['item_name']?.toString(),
      itemCode: json['item_code']?.toString(),
      action: json['action']?.toString() ?? 'Activity',
      description: json['description']?.toString() ?? 'No description',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}