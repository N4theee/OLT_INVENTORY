import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/models/inventory_item_model.dart';
import 'package:olt_inventory/providers/department_provider.dart';
import 'package:olt_inventory/providers/inventory_provider.dart';
import 'package:olt_inventory/providers/dashboard_provider.dart';
import 'package:olt_inventory/utils/validators.dart';
import 'package:olt_inventory/widgets/ced_category_dropdown.dart';
import 'package:olt_inventory/widgets/item_holder_dropdown.dart';
import 'package:olt_inventory/widgets/responsive_content.dart';

class EditInventoryScreen extends StatefulWidget {
  const EditInventoryScreen({super.key, required this.item});

  final InventoryItem item;

  @override
  State<EditInventoryScreen> createState() => _EditInventoryScreenState();
}

class _EditInventoryScreenState extends State<EditInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;

  XFile? _newImageFile;
  Uint8List? _newImageBytes;
  bool _removeImage = false;
  late String? _departmentId;
  late String? _status;
  String? _cedCategory;
  late String? _itemHolder;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.productName);
    _quantityController =
        TextEditingController(text: widget.item.quantity.toString());
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    _departmentId = widget.item.departmentId;
    _status = widget.item.status;
    _cedCategory = widget.item.cedCategory;
    _itemHolder = widget.item.itemHolder;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepartmentProvider>().loadDepartments();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isCedSelected(DepartmentProvider provider) {
    final dept = provider.findById(_departmentId ?? '');
    return isCedDepartmentName(dept?.departmentName);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _newImageFile = picked;
          _newImageBytes = bytes;
          _removeImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final deptProvider = context.read<DepartmentProvider>();
    final deptName =
        deptProvider.findById(_departmentId!)?.departmentName ?? 'Unknown';
    final isCed = isCedDepartmentName(deptName);

    final success = await context.read<InventoryProvider>().updateItem(
          item: widget.item,
          productName: _nameController.text.trim(),
          quantity: int.parse(_quantityController.text.trim()),
          departmentId: _departmentId!,
          status: _status!,
          itemHolder: _itemHolder!,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          cedCategory: isCed ? _cedCategory : null,
          newImageFile: _newImageFile,
          removeImage: _removeImage,
          departmentName: deptName,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      context.read<DashboardProvider>().loadDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<InventoryProvider>().error ?? 'Failed to update item',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showNetworkImage =
        !_removeImage && _newImageBytes == null && widget.item.imageUrl != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: ResponsiveContent(
        padding: EdgeInsets.all(responsivePadding(context)),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lightGrayCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: _newImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_newImageBytes!, fit: BoxFit.cover),
                      )
                    : showNetworkImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: widget.item.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.inventory_2_outlined, size: 64),
                          ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              if ((widget.item.imageUrl != null || _newImageBytes != null) &&
                  !_removeImage)
                TextButton(
                  onPressed: () => setState(() {
                    _removeImage = true;
                    _newImageFile = null;
                    _newImageBytes = null;
                  }),
                  child: const Text('Remove Image'),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name *'),
                validator: Validators.productName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity *'),
                keyboardType: TextInputType.number,
                validator: Validators.quantity,
              ),
              const SizedBox(height: 16),
              Consumer<DepartmentProvider>(
                builder: (context, provider, _) {
                  return DropdownButtonFormField<String>(
                    key: ValueKey('dept-$_departmentId'),
                    initialValue: _departmentId,
                    decoration:
                        const InputDecoration(labelText: 'Department *'),
                    items: provider.departments
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.departmentName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      final dept = provider.findById(value ?? '');
                      setState(() {
                        _departmentId = value;
                        if (!isCedDepartmentName(dept?.departmentName)) {
                          _cedCategory = null;
                        }
                      });
                    },
                    validator: (v) =>
                        Validators.requiredSelection(v, 'Department'),
                  );
                },
              ),
              Consumer<DepartmentProvider>(
                builder: (context, provider, _) {
                  if (!_isCedSelected(provider)) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: CedDepartmentDropdown(
                      key: ValueKey('ced-$_cedCategory'),
                      value: _cedCategory,
                      onChanged: (value) =>
                          setState(() => _cedCategory = value),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ItemHolderDropdown(
                value: _itemHolder,
                onChanged: (value) => setState(() => _itemHolder = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('status-$_status'),
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Item Status *'),
                items: AppConstants.statusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _status = value),
                validator: (v) => Validators.requiredSelection(v, 'Item status'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
