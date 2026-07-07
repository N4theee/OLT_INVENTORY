import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/models/department_model.dart';
import 'package:olt_inventory/providers/dashboard_provider.dart';
import 'package:olt_inventory/widgets/app_drawer.dart';
import 'package:olt_inventory/widgets/dashboard_card.dart';
import 'package:olt_inventory/widgets/responsive_content.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  Future<void> _refresh() async {
    await context.read<DashboardProvider>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.stats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.stats.isEmpty) {
            return _ErrorState(
              message: provider.error!,
              onRetry: _refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primaryGold,
            child: ResponsiveContent(
              padding: EdgeInsets.all(responsivePadding(context)),
              child: ListView(
                children: [
                  const _SectionTitle('Overview'),
                  const SizedBox(height: 12),
                  _OverviewGrid(stats: provider.stats),
                  const SizedBox(height: 24),
                  _DepartmentBreakdownSection(
                    departments: provider.departmentStats,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.stats});

  final Map<String, int> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: responsiveGridCount(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: MediaQuery.sizeOf(context).width >= 500 ? 1.5 : 1.35,
      children: [
        DashboardCard(
          title: 'Total Items',
          value: '${stats['totalItems'] ?? 0}',
          icon: Icons.inventory_2_outlined,
        ),
        DashboardCard(
          title: 'Total Quantity',
          value: '${stats['totalQuantity'] ?? 0}',
          icon: Icons.numbers,
        ),
        DashboardCard(
          title: 'Departments',
          value: '${stats['totalDepartments'] ?? 0}',
          icon: Icons.apartment_outlined,
        ),
        DashboardCard(
          title: 'Good Condition',
          value: '${stats['goodCondition'] ?? 0}',
          icon: Icons.check_circle_outline,
          iconColor: AppColors.success,
        ),
        DashboardCard(
          title: 'Needs Repair',
          value: '${stats['needsRepair'] ?? 0}',
          icon: Icons.build_outlined,
          iconColor: AppColors.warning,
        ),
        DashboardCard(
          title: 'Depreciated',
          value: '${stats['depreciated'] ?? 0}',
          icon: Icons.trending_down,
          iconColor: AppColors.error,
        ),
      ],
    );
  }
}

class _DepartmentBreakdownSection extends StatelessWidget {
  const _DepartmentBreakdownSection({required this.departments});

  final List<Department> departments;

  @override
  Widget build(BuildContext context) {
    final activeDepartments =
        departments.where((d) => d.itemCount > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Department Breakdown'),
        const SizedBox(height: 8),
        if (activeDepartments.isEmpty)
          const _EmptyHint('No department data.')
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: activeDepartments
                    .map(
                      (dept) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                dept.departmentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${dept.itemCount} Items',
                              style: const TextStyle(
                                color: AppColors.primaryGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: const TextStyle(color: AppColors.mutedText)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.mutedText),
            const SizedBox(height: 16),
            Text(
              'Unable to connect',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
