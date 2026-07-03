import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/providers/department_provider.dart';
import 'package:olt_inventory/screens/department_detail_screen.dart';
import 'package:olt_inventory/widgets/app_drawer.dart';
import 'package:olt_inventory/widgets/department_card.dart';

class DepartmentItemsScreen extends StatefulWidget {
  const DepartmentItemsScreen({super.key});

  @override
  State<DepartmentItemsScreen> createState() => _DepartmentItemsScreenState();
}

class _DepartmentItemsScreenState extends State<DepartmentItemsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepartmentProvider>().loadDepartments(withStats: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Department Items')),
      drawer: const AppDrawer(currentRoute: '/departments'),
      body: Consumer<DepartmentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.departments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.departments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        provider.loadDepartments(withStats: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.departments.isEmpty) {
            return const Center(child: Text('No departments found'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadDepartments(withStats: true),
            color: AppColors.primaryGold,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.departments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final dept = provider.departments[index];
                return DepartmentCard(
                  department: dept,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DepartmentDetailScreen(
                          departmentId: dept.id,
                          departmentName: dept.departmentName,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
