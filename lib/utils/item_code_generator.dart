import 'package:olt_inventory/constants/app_constants.dart';

class ItemCodeGenerator {
  ItemCodeGenerator._();

  static String getDepartmentCode(String departmentName) {
    return AppConstants.departmentCodes[departmentName] ?? 'UNK';
  }

  static String getCedCategoryCode(String? cedCategory) {
    if (cedCategory == null || cedCategory.isEmpty) return 'GEN';
    return AppConstants.cedCategoryCodes[cedCategory] ?? 'GEN';
  }

  static String getItemPrefix(String productName) {
    final cleaned = productName.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (cleaned.isEmpty) return 'ITM';
    if (cleaned.length >= 3) return cleaned.substring(0, 3).toUpperCase();
    return cleaned.toUpperCase().padRight(3, 'X');
  }

  static String buildBaseCode({
    required String departmentName,
    required String productName,
    String? cedCategory,
  }) {
    final deptCode = getDepartmentCode(departmentName);
    final itemPrefix = getItemPrefix(productName);

    if (departmentName == AppConstants.cedDepartmentName) {
      final cedCode = getCedCategoryCode(cedCategory);
      return '$deptCode$cedCode$itemPrefix';
    }

    return '$deptCode$itemPrefix';
  }

  static String formatCode({
    required String baseCode,
    required int typeNumber,
    required int globalNumber,
  }) {
    return '$baseCode'
        '${typeNumber.toString().padLeft(2, '0')}'
        '${globalNumber.toString().padLeft(5, '0')}';
  }

  static int extractTypeNumber(String itemCode) {
    if (itemCode.length < 7) return 1;
    final withoutGlobal = itemCode.substring(0, itemCode.length - 5);
    final typeText = withoutGlobal.substring(withoutGlobal.length - 2);
    return int.tryParse(typeText) ?? 1;
  }
}