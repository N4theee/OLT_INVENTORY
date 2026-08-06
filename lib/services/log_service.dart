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
    String? itemName,
    String? itemCode,
  }) async {
    await _client.from('inventory_logs').insert({
      'item_id': itemId,
      'item_name': itemName,
      'item_code': itemCode,
      'action': action,
      'description': description,
    });
  }

  Future<List<InventoryLog>> getLogs({
    int page = 0,
    int pageSize = 20,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    dynamic query = _client
        .from('inventory_logs')
        .select('id, item_id, item_name, item_code, action, description, created_at')
        .order('created_at', ascending: false);

    if (startDate != null) {
      query = query.gte('created_at', startDate.toUtc().toIso8601String());
    }

    if (endDate != null) {
      final inclusiveEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      ).toUtc();

      query = query.lte('created_at', inclusiveEnd.toIso8601String());
    }

    final response = await query.range(from, to);

    var logs = (response as List)
        .map((json) => InventoryLog.fromJson(json as Map<String, dynamic>))
        .toList();

    final term = search?.trim().toLowerCase();

    if (term != null && term.isNotEmpty) {
      logs = logs.where((log) {
        return log.description.toLowerCase().contains(term) ||
            log.action.toLowerCase().contains(term) ||
            (log.itemName ?? '').toLowerCase().contains(term) ||
            (log.itemCode ?? '').toLowerCase().contains(term);
      }).toList();
    }

    return logs;
  }

  Future<void> clearAllLogs() async {
    await _client
        .from('inventory_logs')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');
  }
}