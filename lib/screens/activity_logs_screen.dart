import 'dart:async';
import 'package:intl/intl.dart';
import 'package:olt_inventory/utils/history_date_filter.dart';
import 'package:flutter/material.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/models/inventory_log_model.dart';
import 'package:olt_inventory/services/log_service.dart';
import 'package:olt_inventory/utils/date_formatter.dart';
import 'package:olt_inventory/widgets/app_drawer.dart';
import 'package:olt_inventory/widgets/search_bar_widget.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key, this.logService});
  final LogService? logService;

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  late final _logService = widget.logService ?? LogService();
  Timer? _searchDebounce;
  int _requestId = 0;
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
    _searchDebounce?.cancel();
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
    if (_isLoading && !refresh) return;
    if (!_hasMore && !refresh) return;

    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;

      if (refresh) {
        _logs = [];
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

      if (!mounted || requestId != _requestId) return;

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
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _setSearch(String value) {
    _searchDebounce?.cancel();
    _search = value;
    // Invalidate old responses immediately, including during the debounce.
    _requestId++;
    setState(() {
      _logs = [];
      _isLoading = true;
      _error = null;
    });
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _loadLogs(refresh: true),
    );
  }

  Future<void> _setPresetDateFilter(String filter) async {
    if (filter == 'all') {
      _applyDates('all', null);
      return;
    }
    final picked = await pickHistoryPeriod(
      context,
      filter,
      _startDate ?? DateTime.now(),
    );
    if (!mounted || picked == null) return;
    _applyDates(filter, historyPeriod(filter, picked));
  }

  void _applyDates(String filter, DateTimeRange? dates) {
    _searchDebounce?.cancel();
    setState(() {
      _activeDateFilter = filter;
      _startDate = dates?.start;
      _endDate = dates?.end;
    });
    _loadLogs(refresh: true);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (!mounted || picked == null) return;
    _applyDates('custom', picked);
  }

  String _dateRangeLabel() {
    if (_startDate == null || _endDate == null) return 'All dates';
    if (_activeDateFilter == 'day') {
      return DateFormatter.formatDate(_startDate!);
    }
    if (_activeDateFilter == 'month') {
      return DateFormat.yMMMM().format(_startDate!);
    }
    if (_activeDateFilter == 'year') return '${_startDate!.year}';
    return '${DateFormatter.formatDate(_startDate!)} – ${DateFormatter.formatDate(_endDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Logs')),
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
                        label: const Text('Date range'),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _dateRangeLabel(),
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ),
          ),
          Expanded(child: _buildLogsBody()),
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
              const Icon(Icons.cloud_off, size: 48, color: AppColors.mutedText),
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _logs.length + ((_hasMore || _error != null) ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= _logs.length) {
            if (!_isLoading) {
              return Center(
                child: TextButton(
                  onPressed: () => _loadLogs(),
                  child: Text(
                    _error != null
                        ? 'Could not load more. Tap to retry'
                        : 'Load more',
                  ),
                ),
              );
            }
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
                    '${log.action} • ${DateFormatter.formatDateTime(log.createdAt.toLocal())}',
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
