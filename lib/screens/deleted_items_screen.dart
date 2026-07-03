import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/models/inventory_item_model.dart';
import 'package:olt_inventory/providers/inventory_provider.dart';
import 'package:olt_inventory/providers/dashboard_provider.dart';
import 'package:olt_inventory/widgets/app_drawer.dart';
import 'package:olt_inventory/widgets/inventory_card.dart';

class DeletedItemsScreen extends StatefulWidget {
  const DeletedItemsScreen({super.key});

  @override
  State<DeletedItemsScreen> createState() => _DeletedItemsScreenState();
}

class _DeletedItemsScreenState extends State<DeletedItemsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadDeletedItems(refresh: true);
    });
  }

  Future<void> _restoreItem(InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Item'),
        content: Text('Restore "${item.productName}" to active inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<InventoryProvider>().restoreItem(item);
    if (!mounted) return;

    if (success) {
      context.read<DashboardProvider>().loadDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item restored successfully')),
      );
    }
  }

  Future<void> _permanentlyDelete(InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: Text(
          'Permanently delete "${item.productName}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success =
        await context.read<InventoryProvider>().permanentlyDeleteItem(item);
    if (!mounted) return;

    if (success) {
      context.read<DashboardProvider>().loadDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item permanently deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deleted Items')),
      drawer: const AppDrawer(currentRoute: '/deleted'),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.deletedItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.deletedItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, size: 64, color: AppColors.mutedText),
                  SizedBox(height: 16),
                  Text('No deleted items'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadDeletedItems(refresh: true),
            color: AppColors.primaryGold,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.deletedItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = provider.deletedItems[index];
                return InventoryCard(
                  item: item,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'restore') {
                        _restoreItem(item);
                      } else if (value == 'delete') {
                        _permanentlyDelete(item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'restore',
                        child: Text('Restore'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Permanently Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
