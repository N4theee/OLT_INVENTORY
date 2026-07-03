import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/models/department_model.dart';
import 'package:olt_inventory/services/supabase_service.dart';

class DepartmentService {
  DepartmentService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<List<Department>> getDepartments() async {
    final response = await _client
        .from('departments')
        .select()
        .order('department_name', ascending: true);

    return (response as List)
        .map((json) => Department.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Department>> getDepartmentsWithStats() async {
    final departments = await getDepartments();
    final itemsResponse = await _client
        .from('inventory_items')
        .select('department_id, quantity')
        .eq('is_deleted', false);

    final stats = <String, ({int count, int quantity})>{};
    for (final row in itemsResponse as List) {
      final deptId = row['department_id'] as String;
      final qty = row['quantity'] as int;
      final current = stats[deptId];
      stats[deptId] = (
        count: (current?.count ?? 0) + 1,
        quantity: (current?.quantity ?? 0) + qty,
      );
    }

    return departments
        .map(
          (dept) => dept.copyWith(
            itemCount: stats[dept.id]?.count ?? 0,
            totalQuantity: stats[dept.id]?.quantity ?? 0,
          ),
        )
        .toList();
  }

  Future<void> resetDepartments() async {
    await _client.from('inventory_items').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await _client.from('inventory_logs').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await _client.from('departments').delete().neq('id', '00000000-0000-0000-0000-000000000000');

    for (final name in AppConstants.defaultDepartments) {
      await _client.from('departments').insert({'department_name': name});
    }
  }
}
