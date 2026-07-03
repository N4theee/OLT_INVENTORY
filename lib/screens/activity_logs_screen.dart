import 'package:flutter/material.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/models/inventory_log_model.dart';
import 'package:olt_inventory/services/log_service.dart';
import 'package:olt_inventory/utils/date_formatter.dart';
import 'package:olt_inventory/widgets/app_drawer.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final _logService = LogService();
  final _scrollController = ScrollController();

  List<InventoryLog> _logs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadLogs();
    }
  }

  Future<void> _loadLogs({bool refresh = false}) async {
    if (_isLoading) return;
    if (!_hasMore && !refresh) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _page = 0;
        _hasMore = true;
      }
    });

    try {
      final page = refresh ? 0 : _page;
      final result = await _logService.getLogs(page: page);

      setState(() {
        if (refresh) {
          _logs = result;
          _page = 1;
        } else {
          _logs = [..._logs, ...result];
          _page = page + 1;
        }
        _hasMore = result.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Logs')),
      drawer: const AppDrawer(currentRoute: '/logs'),
      body: _error != null && _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _loadLogs(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _logs.isEmpty && _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _logs.isEmpty
                  ? const Center(child: Text('No activity logs yet'))
                  : RefreshIndicator(
                      onRefresh: () => _loadLogs(refresh: true),
                      color: AppColors.primaryGold,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _logs.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index >= _logs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final log = _logs[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primaryGold.withValues(alpha: 0.15),
                                child: Icon(
                                  _actionIcon(log.action),
                                  color: AppColors.primaryGold,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                log.itemName ?? 'Unknown Item',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(log.description),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormatter.formatDateTime(log.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'Added':
        return Icons.add_circle_outline;
      case 'Updated':
        return Icons.edit_outlined;
      case 'Deleted':
        return Icons.delete_outline;
      case 'Restored':
        return Icons.restore;
      case 'Permanently Deleted':
        return Icons.delete_forever;
      default:
        return Icons.history;
    }
  }
}
