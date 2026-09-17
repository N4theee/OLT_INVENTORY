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

    var query = _client
        .from('inventory_logs')
        .select(
          'id, item_id, item_name, item_code, action, description, created_at',
        );

    if (startDate != null) {
      query = query.gte('created_at', startDate.toUtc().toIso8601String());
    }

    if (endDate != null) {
      final exclusiveEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day + 1,
      ).toUtc();

      query = query.lt('created_at', exclusiveEnd.toIso8601String());
    }

    final term = search?.trim();

    if (term != null && term.isNotEmpty) {
      // Quote PostgREST values so punctuation cannot change the filter.
      final escaped = term
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('%', '\\%')
          .replaceAll('_', '\\_')
          .replaceAll('*', '\\*');
      final pattern = '"%$escaped%"';
      query = query.or(
        [
          'description',
          'action',
          'item_name',
          'item_code',
        ].map((field) => '$field.ilike.$pattern').join(','),
      );
    }

    final response = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(from, to);
    return response.map(InventoryLog.fromJson).toList();
  }

  Future<void> clearAllLogs() async {
    await _client
        .from('inventory_logs')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');
  }
}
