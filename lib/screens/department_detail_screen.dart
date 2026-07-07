import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/models/inventory_item_model.dart';
import 'package:olt_inventory/providers/inventory_provider.dart';
import 'package:olt_inventory/screens/item_details_screen.dart';
import 'package:olt_inventory/services/inventory_service.dart';
import 'package:olt_inventory/widgets/inventory_card.dart';
import 'package:olt_inventory/widgets/search_bar_widget.dart';

class DepartmentDetailScreen extends StatefulWidget {
  const DepartmentDetailScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  final String departmentId;
  final String departmentName;

  @override
  State<DepartmentDetailScreen> createState() => _DepartmentDetailScreenState();
}

class _DepartmentDetailScreenState extends State<DepartmentDetailScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<InventoryItem> _items = [];
  bool _isLoading = true;
  int _page = 0;
  bool _hasMore = true;
  String _search = '';
  String? _statusFilter;
  String? _cedCategoryFilter;
  ItemSortOption _sort = ItemSortOption.newest;

  bool get _isCedDepartment =>
      widget.departmentName == AppConstants.cedDepartmentName;

  @override
  void initState() {
    super.initState();
    _loadItems(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadItems();
    }
  }

  Future<void> _loadItems({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    if (!_hasMore && !refresh) return;

    setState(() => _isLoading = true);

    try {
      final page = refresh ? 0 : _page;
      final result =
          await context.read<InventoryProvider>().loadDepartmentItems(
                widget.departmentId,
                page: page,
                search: _search.isEmpty ? null : _search,
                status: _statusFilter,
                cedCategory: _isCedDepartment ? _cedCategoryFilter : null,
                sort: _sort,
              );

      if (mounted) {
        setState(() {
          if (refresh) {
            _items = result;
            _page = 1;
          } else {
            _items = [..._items, ...result];
            _page = page + 1;
          }
          _hasMore = result.length >= AppConstants.pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load items: $e')),
        );
      }
    }
  }

  void _applySearch(String value) {
    _search = value;
    _loadItems(refresh: true);
  }

  void _setStatusFilter(String? value) {
    setState(() => _statusFilter = value);
    _loadItems(refresh: true);
  }

  void _setCedCategoryFilter(String? value) {
    setState(() => _cedCategoryFilter = value);
    _loadItems(refresh: true);
  }

  void _setSort(ItemSortOption value) {
    setState(() => _sort = value);
    _loadItems(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.departmentName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search by name or Item ID in ${widget.departmentName}...',
                  onChanged: _applySearch,
                  onClear: () => _applySearch(''),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PopupMenuButton<String?>(
                        onSelected: _setStatusFilter,
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: null,
                            child: Text('All Item Statuses'),
                          ),
                          ...AppConstants.statusOptions.map(
                            (s) => PopupMenuItem(value: s, child: Text(s)),
                          ),
                        ],
                        child: Chip(
                          label: Text(_statusFilter ?? 'Item Status'),
                          avatar: const Icon(Icons.filter_list, size: 18),
                        ),
                      ),
                      if (_isCedDepartment) ...[
                        const SizedBox(width: 8),
                        PopupMenuButton<String?>(
                          onSelected: _setCedCategoryFilter,
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: null,
                              child: Text('All CED Categories'),
                            ),
                            ...AppConstants.cedCategories.map(
                              (c) => PopupMenuItem(value: c, child: Text(c)),
                            ),
                          ],
                          child: Chip(
                            label: Text(_cedCategoryFilter ?? 'CED Category'),
                            avatar: const Icon(Icons.category_outlined, size: 18),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      PopupMenuButton<ItemSortOption>(
                        onSelected: _setSort,
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: ItemSortOption.newest,
                            child: Text('Newest'),
                          ),
                          PopupMenuItem(
                            value: ItemSortOption.oldest,
                            child: Text('Oldest'),
                          ),
                          PopupMenuItem(
                            value: ItemSortOption.name,
                            child: Text('Name'),
                          ),
                          PopupMenuItem(
                            value: ItemSortOption.quantity,
                            child: Text('Quantity'),
                          ),
                        ],
                        child: Chip(
                          label: Text(_sortLabel(_sort)),
                          avatar: const Icon(Icons.sort, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: AppColors.mutedText),
                            SizedBox(height: 16),
                            Text('No items match your filters'),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadItems(refresh: true),
                        color: AppColors.primaryGold,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _items.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (index >= _items.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final item = _items[index];
                            return InventoryCard(
                              item: item,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ItemDetailsScreen(itemId: item.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(ItemSortOption sort) {
    switch (sort) {
      case ItemSortOption.name:
        return 'Name';
      case ItemSortOption.quantity:
        return 'Quantity';
      case ItemSortOption.newest:
        return 'Newest';
      case ItemSortOption.oldest:
        return 'Oldest';
    }
  }
}
