class Validators {
  Validators._();

  static String? productName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product name is required';
    }
    return null;
  }

  static String? quantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed <= 0) {
      return 'Quantity must be positive';
    }
    return null;
  }

  static String? requiredSelection(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? cedCategory(String? value, {required bool isCedDepartment}) {
    if (!isCedDepartment) return null;
    return requiredSelection(value, 'CED department');
  }
}
