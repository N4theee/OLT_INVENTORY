import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:olt_inventory/models/inventory_log_model.dart';
import 'package:olt_inventory/services/supabase_service.dart';

class LogService {
  LogService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<void> createLog({
    required String itemId,
    required String action,
    required String description,
  }) async {
    await _client.from('inventory_logs').insert({
      'item_id': itemId,
      'action': action,
      'description': description,
    });
  }

  Future<List<InventoryLog>> getLogs({int page = 0, int pageSize = 20}) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final response = await _client
        .from('inventory_logs')
        .select('*, inventory_items(product_name)')
        .order('created_at', ascending: false)
        .range(from, to);

    return (response as List)
        .map((json) => InventoryLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearAllLogs() async {
    await _client
        .from('inventory_logs')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');
  }
}
