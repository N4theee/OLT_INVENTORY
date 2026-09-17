import 'package:flutter_test/flutter_test.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/models/inventory_item_model.dart';
import 'package:olt_inventory/utils/item_code_generator.dart';

void main() {
  test(
    'Default departments include all nine departments without Uncategorized',
    () {
      expect(AppConstants.defaultDepartments, hasLength(9));
      expect(AppConstants.defaultDepartments.toSet(), hasLength(9));
      expect(
        AppConstants.defaultDepartments,
        containsAll(['Care Department', 'Intercessory Department', 'General']),
      );
      expect(AppConstants.defaultDepartments, isNot(contains('Uncategorized')));
    },
  );

  test('New items use the correct department prefix', () {
    for (final entry in {
      'Care Department': 'CARCHA',
      'Intercessory Department': 'INTCHA',
      'General': 'GENCHA',
    }.entries) {
      expect(
        ItemCodeGenerator.buildBaseCode(
          departmentName: entry.key,
          productName: 'Chair',
        ),
        entry.value,
      );
    }
    expect(
      ItemCodeGenerator.buildBaseCode(
        departmentName: 'CED',
        cedCategory: 'Musicians',
        productName: 'Guitar',
      ),
      'CEDMSCGUI',
    );
  });

  test(
    'Existing UNC codes survive the department rename and ordinary edits',
    () {
      final item = InventoryItem.fromJson({
        'id': 'item-1',
        'product_name': 'Chair',
        'quantity': 3,
        'department_id': 'same-department-id',
        'status': 'Good condition',
        'item_code': 'UNCCHA0100001',
        'date_added': '2026-01-01T00:00:00Z',
        'last_updated': '2026-01-01T00:00:00Z',
        'departments': {'department_name': 'General'},
      });
      expect(item.departmentName, 'General');
      expect(item.itemCode, 'UNCCHA0100001');
      final edited = item.copyWith(quantity: 4);
      expect(edited.itemCode, item.itemCode);
      expect(edited.toUpdateJson(), isNot(contains('item_code')));
      expect(edited.departmentId, item.departmentId);
    },
  );
}
