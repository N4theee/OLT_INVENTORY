class Department {
  const Department({
    required this.id,
    required this.departmentName,
    required this.createdAt,
    this.itemCount = 0,
    this.totalQuantity = 0,
  });

  final String id;
  final String departmentName;
  final DateTime createdAt;
  final int itemCount;
  final int totalQuantity;

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String,
      departmentName: json['department_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      itemCount: json['item_count'] as int? ?? 0,
      totalQuantity: json['total_quantity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'department_name': departmentName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Department copyWith({
    String? id,
    String? departmentName,
    DateTime? createdAt,
    int? itemCount,
    int? totalQuantity,
  }) {
    return Department(
      id: id ?? this.id,
      departmentName: departmentName ?? this.departmentName,
      createdAt: createdAt ?? this.createdAt,
      itemCount: itemCount ?? this.itemCount,
      totalQuantity: totalQuantity ?? this.totalQuantity,
    );
  }
}
