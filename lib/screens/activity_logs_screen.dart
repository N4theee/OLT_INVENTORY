import 'package:flutter/material.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/models/inventory_log_model.dart';
import 'package:olt_inventory/services/log_service.dart';
import 'package:olt_inventory/utils/date_formatter.dart';
import 'package:olt_inventory/widgets/app_drawer.dart';
import 'package:olt_inventory/widgets/search_bar_widget.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final _logService = LogService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  List<InventoryLog> _logs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  String _search = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _activeDateFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadLogs(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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

      final result = await _logService.getLogs(
        page: page,
        search: _search,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

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
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _setSearch(String value) {
    _search = value;
    _loadLogs(refresh: true);
  }

  void _setPresetDateFilter(String filter) {
    final now = DateTime.now();

    setState(() {
      _activeDateFilter = filter;

      if (filter == 'all') {
        _startDate = null;
        _endDate = null;
      } else if (filter == 'day') {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day);
      } else if (filter == 'month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
      } else if (filter == 'year') {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
      }
    });

    _loadLogs(refresh: true);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked == null) return;

    setState(() {
      _activeDateFilter = 'custom';
      _startDate = picked.start;
      _endDate = picked.end;
    });

    _loadLogs(refresh: true);
  }

  String _dateRangeLabel() {
    if (_startDate == null || _endDate == null) {
      return 'Calendar';
    }

    return '${DateFormatter.formatDate(_startDate!)} - ${DateFormatter.formatDate(_endDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs'),
      ),
      drawer: const AppDrawer(currentRoute: '/logs'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search by item, Item ID, action...',
                  onChanged: _setSearch,
                  onClear: () {
                    _searchController.clear();
                    _setSearch('');
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _DateFilterChip(
                        label: 'All',
                        value: 'all',
                        selectedValue: _activeDateFilter,
                        onSelected: _setPresetDateFilter,
                      ),
                      const SizedBox(width: 8),
                      _DateFilterChip(
                        label: 'Day',
                        value: 'day',
                        selectedValue: _activeDateFilter,
                        onSelected: _setPresetDateFilter,
                      ),
                      const SizedBox(width: 8),
                      _DateFilterChip(
                        label: 'Month',
                        value: 'month',
                        selectedValue: _activeDateFilter,
                        onSelected: _setPresetDateFilter,
                      ),
                      const SizedBox(width: 8),
                      _DateFilterChip(
                        label: 'Year',
                        value: 'year',
                        selectedValue: _activeDateFilter,
                        onSelected: _setPresetDateFilter,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(_dateRangeLabel()),
                        selected: _activeDateFilter == 'custom',
                        avatar: const Icon(Icons.calendar_month, size: 18),
                        onSelected: (_) => _pickDateRange(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildLogsBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsBody() {
    if (_error != null && _logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 48,
                color: AppColors.mutedText,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load activity logs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.mutedText),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadLogs(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_logs.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_logs.isEmpty) {
      return const Center(child: Text('No activity logs found'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadLogs(refresh: true),
      color: AppColors.primaryGold,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                backgroundColor: AppColors.primaryGold.withValues(alpha: 0.15),
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
                  if (log.itemCode != null && log.itemCode!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Item ID: ${log.itemCode}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(log.description),
                  const SizedBox(height: 4),
                  Text(
                    '${log.action} • ${DateFormatter.formatDateTime(log.createdAt)}',
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

class _DateFilterChip extends StatelessWidget {
  const _DateFilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
    );
  }
}