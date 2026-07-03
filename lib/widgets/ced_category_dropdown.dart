import 'package:flutter/material.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/utils/validators.dart';

class CedDepartmentDropdown extends StatelessWidget {
  const CedDepartmentDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.isRequired = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey('ced-dept-$value'),
      initialValue: value,
      validator: (v) =>
          Validators.cedCategory(v, isCedDepartment: isRequired),
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: isRequired ? 'CED Department *' : 'CED Department (optional)',
            errorText: field.errorText,
            filled: true,
            fillColor: AppColors.lightGrayCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: field.value,
              hint: const Text('Select CED department'),
              items: [
                if (!isRequired)
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All CED Departments'),
                  ),
                ...AppConstants.cedCategories.map(
                  (category) => DropdownMenuItem<String?>(
                    value: category,
                    child: Text(category),
                  ),
                ),
              ],
              onChanged: (selected) {
                field.didChange(selected);
                onChanged(selected);
              },
            ),
          ),
        );
      },
    );
  }
}

bool isCedDepartmentName(String? name) =>
    name == AppConstants.cedDepartmentName;
