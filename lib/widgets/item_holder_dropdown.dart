import 'package:flutter/material.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/utils/validators.dart';

class ItemHolderDropdown extends StatelessWidget {
  const ItemHolderDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('item-holder-$value'),
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Item Holder *'),
      items: AppConstants.itemHolderOptions
          .map((h) => DropdownMenuItem(value: h, child: Text(h)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => Validators.requiredSelection(v, 'Item holder'),
    );
  }
}
