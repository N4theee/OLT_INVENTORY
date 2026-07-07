import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/models/inventory_item_model.dart';
import 'package:olt_inventory/providers/inventory_provider.dart';
import 'package:olt_inventory/providers/dashboard_provider.dart';
import 'package:olt_inventory/screens/edit_inventory_screen.dart';
import 'package:olt_inventory/utils/date_formatter.dart';

class ItemDetailsScreen extends StatefulWidget {
  const ItemDetailsScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  InventoryItem? _item;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final item =
        await context.read<InventoryProvider>().getItemById(widget.itemId);
    if (mounted) {
      setState(() {
        _item = item;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem() async {
    if (_item == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text(
          'Move "${_item!.productName}" to Deleted Items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success =
        await context.read<InventoryProvider>().softDeleteItem(_item!);

    if (!mounted) return;

    if (success) {
      context.read<DashboardProvider>().loadDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item moved to Deleted Items')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _editItem() async {
    if (_item == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditInventoryScreen(item: _item!),
      ),
    );

    if (updated == true) {
      await _loadItem();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _item == null
              ? const Center(child: Text('Item not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _DetailImage(imageUrl: _item!.imageUrl),
                    const SizedBox(height: 20),
                    Text(
                      _item!.productName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (_item!.itemCode != null && _item!.itemCode!.isNotEmpty)
                      _DetailRow(label: 'Item ID', value: _item!.itemCode!),
                    _DetailRow(label: 'Quantity', value: '${_item!.quantity}'),
                    _DetailRow(
                      label: 'Department',
                      value: _item!.departmentName ?? 'Unknown',
                    ),
                    _DetailRow(label: 'Item Status', value: _item!.status),
                    _DetailRow(label: 'Item Holder', value: _item!.itemHolder),
                    if (_item!.cedCategory != null &&
                        _item!.cedCategory!.isNotEmpty)
                      _DetailRow(
                        label: 'CED Department',
                        value: _item!.cedCategory!,
                      ),
                    if (_item!.notes != null && _item!.notes!.isNotEmpty)
                      _DetailRow(label: 'Notes', value: _item!.notes!),
                    _DetailRow(
                      label: 'Date Added',
                      value: DateFormatter.formatDateTime(_item!.dateAdded),
                    ),
                    _DetailRow(
                      label: 'Last Updated',
                      value: DateFormatter.formatDateTime(_item!.lastUpdated),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _editItem,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Item'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _deleteItem,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Item'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.lightGrayCard,
      child: const Icon(Icons.inventory_2_outlined, size: 80),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
