import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/providers/department_provider.dart';
import 'package:olt_inventory/providers/inventory_provider.dart';
import 'package:olt_inventory/providers/dashboard_provider.dart';
import 'package:olt_inventory/utils/validators.dart';
import 'package:olt_inventory/widgets/app_drawer.dart';
import 'package:olt_inventory/widgets/ced_category_dropdown.dart';
import 'package:olt_inventory/widgets/item_holder_dropdown.dart';
import 'package:olt_inventory/widgets/responsive_content.dart';

class AddInventoryScreen extends StatefulWidget {
  const AddInventoryScreen({super.key});

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  final List<XFile> _imageFiles = [];
  final List<Uint8List> _imagePreviewBytes = [];
  String? _departmentId;
  String? _status;
  String? _cedCategory;
  String? _itemHolder;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickImages(ImageSource source) async {
    try {
      final remaining = 10 - _imageFiles.length;
      if (remaining == 0) return;
      late final List<XFile> picked;
      if (source == ImageSource.gallery) {
        picked = await _picker.pickMultiImage(
          maxWidth: 1200,
          imageQuality: 85,
        );
      } else {
        final image = await _picker.pickImage(
          source: source,
          maxWidth: 1200,
          imageQuality: 85,
        );
        picked = image == null ? <XFile>[] : <XFile>[image];
      }
      final accepted = picked.take(remaining).toList();
      final previews = await Future.wait(
        accepted.map((image) => image.readAsBytes()),
      );
      if (!mounted) return;
      setState(() {
        _imageFiles.addAll(accepted);
        _imagePreviewBytes.addAll(previews);
      });
      if (picked.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only the first 10 images were added.')),
        );
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

    final item = await context.read<InventoryProvider>().addItem(
          productName: _nameController.text.trim(),
          quantity: int.parse(_quantityController.text.trim()),
          departmentId: _departmentId!,
          status: _status!,
          itemHolder: _itemHolder!,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          cedCategory: isCed ? _cedCategory : null,
          imageFiles: _imageFiles,
          departmentName: deptName,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    final provider = context.read<InventoryProvider>();

    if (item != null) {
      context.read<DashboardProvider>().loadDashboard();
      final idLabel = item.itemCode ?? 'assigned';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item added — ID: $idLabel')),
      );
      _formKey.currentState!.reset();
      setState(() {
        _imageFiles.clear();
        _imagePreviewBytes.clear();
        _departmentId = null;
        _status = null;
        _cedCategory = null;
        _itemHolder = null;
      });
      _nameController.clear();
      _quantityController.clear();
      _notesController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to add item'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Inventory')),
      drawer: const AppDrawer(currentRoute: '/add'),
      body: ResponsiveContent(
        padding: EdgeInsets.all(responsivePadding(context)),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _ImagePickerSection(
                previewBytes: _imagePreviewBytes,
                onCamera: _imageFiles.length >= 10
                    ? null
                    : () => _pickImages(ImageSource.camera),
                onGallery: _imageFiles.length >= 10
                    ? null
                    : () => _pickImages(ImageSource.gallery),
                onRemove: (index) => setState(() {
                  _imageFiles.removeAt(index);
                  _imagePreviewBytes.removeAt(index);
                }),
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
                  if (provider.isLoading && provider.departments.isEmpty) {
                    return const LinearProgressIndicator();
                  }

                  if (provider.departments.isEmpty) {
                    return const Text(
                      'No departments found. Run supabase/schema.sql first.',
                      style: TextStyle(color: AppColors.error),
                    );
                  }

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
              const SizedBox(height: 8),
              Text(
                'Item ID is assigned automatically when you save.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
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
                    : const Text('Save Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  const _ImagePickerSection({
    required this.previewBytes,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final List<Uint8List> previewBytes;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (previewBytes.isEmpty)
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.lightGrayCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo,
                        size: 48, color: AppColors.mutedText),
                    SizedBox(height: 8),
                    Text('Add up to 10 product images',
                        style: TextStyle(color: AppColors.mutedText)),
                  ],
                ),
          )
        else
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: previewBytes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      previewBytes[index],
                      width: 116,
                      height: 116,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filled(
                      onPressed: () => onRemove(index),
                      icon: const Icon(Icons.close, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text('${previewBytes.length}/10 images'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
