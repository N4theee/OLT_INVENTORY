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
    if (cleaned.length >= 3) {
      return cleaned.substring(0, 3).toUpperCase();
    }
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
      return '${deptCode}_${cedCode}_$itemPrefix';
    }
    return '${deptCode}_$itemPrefix';
  }

  static int nextSequenceNumber(List<String?> existingCodes, String baseCode) {
    var maxNum = 0;
    for (final code in existingCodes) {
      if (code == null || !code.startsWith(baseCode)) continue;
      final match = RegExp(r'(\d+)$').firstMatch(code);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    return maxNum + 1;
  }

  static String formatCode(String baseCode, int sequence) {
    return '$baseCode${sequence.toString().padLeft(2, '0')}';
  }
}
