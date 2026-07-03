import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/providers/department_provider.dart';
import 'package:olt_inventory/providers/inventory_provider.dart';
import 'package:olt_inventory/screens/item_details_screen.dart';
import 'package:olt_inventory/services/inventory_service.dart';
import 'package:olt_inventory/widgets/app_drawer.dart';
import 'package:olt_inventory/widgets/inventory_card.dart';
import 'package:olt_inventory/widgets/search_bar_widget.dart';

class AllItemsScreen extends StatefulWidget {
  const AllItemsScreen({super.key});

  @override
  State<AllItemsScreen> createState() => _AllItemsScreenState();
}

class _AllItemsScreenState extends State<AllItemsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepartmentProvider>().loadDepartments();
      context.read<InventoryProvider>().loadItems(refresh: true);
    });
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
      context.read<InventoryProvider>().loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Items')),
      drawer: const AppDrawer(currentRoute: '/all-items'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search by product name...',
                  onChanged: (value) {
                    context.read<InventoryProvider>().setSearch(value);
                  },
                  onClear: () {
                    context.read<InventoryProvider>().setSearch('');
                  },
                ),
                const SizedBox(height: 12),
                _FilterRow(),
              ],
            ),
          ),
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(provider.error!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => provider.loadItems(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: AppColors.mutedText),
                        SizedBox(height: 16),
                        Text('No inventory items found'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadItems(refresh: true),
                  color: AppColors.primaryGold,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: provider.items.length + (provider.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= provider.items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final item = provider.items[index];
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<InventoryProvider, DepartmentProvider>(
      builder: (context, inventory, departments, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              PopupMenuButton<String?>(
                onSelected: inventory.setDepartmentFilter,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: null, child: Text('All Departments')),
                  ...departments.departments.map(
                    (d) => PopupMenuItem(
                      value: d.id,
                      child: Text(d.departmentName),
                    ),
                  ),
                ],
                child: Chip(
                  label: Text(
                    inventory.departmentFilter != null
                        ? departments
                                .findById(inventory.departmentFilter!)
                                ?.departmentName ??
                            'Department'
                        : 'Department',
                  ),
                  avatar: const Icon(Icons.filter_list, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String?>(
                onSelected: inventory.setStatusFilter,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: null, child: Text('All Item Statuses')),
                  ...AppConstants.statusOptions.map(
                    (s) => PopupMenuItem(value: s, child: Text(s)),
                  ),
                ],
                child: Chip(
                  label: Text(inventory.statusFilter ?? 'Item Status'),
                  avatar: const Icon(Icons.filter_list, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<ItemSortOption>(
                onSelected: inventory.setSort,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: ItemSortOption.newest, child: Text('Newest')),
                  PopupMenuItem(value: ItemSortOption.oldest, child: Text('Oldest')),
                  PopupMenuItem(value: ItemSortOption.name, child: Text('Name')),
                  PopupMenuItem(value: ItemSortOption.quantity, child: Text('Quantity')),
                ],
                child: Chip(
                  label: Text(_sortLabel(inventory.sort)),
                  avatar: const Icon(Icons.sort, size: 18),
                ),
              ),
            ],
          ),
        );
      },
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
