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
                  hintText: 'Search by name or Item ID...',
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
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return Consumer2<InventoryProvider, DepartmentProvider>(
      builder: (context, inventory, departments, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: Text(
                  inventory.departmentFilter != null
                      ? departments
                              .findById(inventory.departmentFilter!)
                              ?.departmentName ??
                          'Department'
                      : 'All Departments',
                ),
                avatar: const Icon(Icons.apartment_outlined, size: 18),
                onSelected: (_) async {
                  final selected = await showModalBottomSheet<String>(
                    context: context,
                    builder: (context) {
                      return SafeArea(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              title: const Text('All Departments'),
                              onTap: () => Navigator.pop(context, ''),
                            ),
                            ...departments.departments.map(
                              (d) => ListTile(
                                title: Text(d.departmentName),
                                onTap: () => Navigator.pop(context, d.id),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  if (selected != null) {
                    inventory.setDepartmentFilter(
                      selected.isEmpty ? null : selected,
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(inventory.statusFilter ?? 'All Item Statuses'),
                avatar: const Icon(Icons.filter_list, size: 18),
                onSelected: (_) async {
                  final selected = await showModalBottomSheet<String>(
                    context: context,
                    builder: (context) {
                      return SafeArea(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              title: const Text('All Item Statuses'),
                              onTap: () => Navigator.pop(context, ''),
                            ),
                            ...AppConstants.statusOptions.map(
                              (s) => ListTile(
                                title: Text(s),
                                onTap: () => Navigator.pop(context, s),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  if (selected != null) {
                    inventory.setStatusFilter(
                      selected.isEmpty ? null : selected,
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(_sortLabel(inventory.sort)),
                avatar: const Icon(Icons.sort, size: 18),
                onSelected: (_) async {
                  final selected =
                      await showModalBottomSheet<ItemSortOption>(
                    context: context,
                    builder: (context) {
                      return SafeArea(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              title: const Text('Newest'),
                              onTap: () => Navigator.pop(
                                context,
                                ItemSortOption.newest,
                              ),
                            ),
                            ListTile(
                              title: const Text('Oldest'),
                              onTap: () => Navigator.pop(
                                context,
                                ItemSortOption.oldest,
                              ),
                            ),
                            ListTile(
                              title: const Text('Name'),
                              onTap: () => Navigator.pop(
                                context,
                                ItemSortOption.name,
                              ),
                            ),
                            ListTile(
                              title: const Text('Quantity'),
                              onTap: () => Navigator.pop(
                                context,
                                ItemSortOption.quantity,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  if (selected != null) {
                    inventory.setSort(selected);
                  }
                },
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