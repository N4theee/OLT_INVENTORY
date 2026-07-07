import 'package:flutter/material.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/screens/activity_logs_screen.dart';
import 'package:olt_inventory/screens/add_inventory_screen.dart';
import 'package:olt_inventory/screens/all_items_screen.dart';
import 'package:olt_inventory/screens/dashboard_screen.dart';
import 'package:olt_inventory/screens/deleted_items_screen.dart';
import 'package:olt_inventory/screens/department_items_screen.dart';
import 'package:olt_inventory/screens/reports_screen.dart';
import 'package:olt_inventory/screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.currentRoute = '/dashboard'});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryGold),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.church, color: AppColors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Church Inventory Management',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerTile(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  selected: currentRoute == '/dashboard',
                  onTap: () => _navigate(context, const DashboardScreen(), '/dashboard'),
                ),
                _DrawerTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'All Items',
                  selected: currentRoute == '/all-items',
                  onTap: () => _navigate(context, const AllItemsScreen(), '/all-items'),
                ),
                _DrawerTile(
                  icon: Icons.apartment_outlined,
                  title: 'Department Items',
                  selected: currentRoute == '/departments',
                  onTap: () => _navigate(
                    context,
                    const DepartmentItemsScreen(),
                    '/departments',
                  ),
                ),
                _DrawerTile(
                  icon: Icons.add_box_outlined,
                  title: 'Add Inventory',
                  selected: currentRoute == '/add',
                  onTap: () => _navigate(context, const AddInventoryScreen(), '/add'),
                ),
                _DrawerTile(
                  icon: Icons.delete_outline,
                  title: 'Deleted Items',
                  selected: currentRoute == '/deleted',
                  onTap: () => _navigate(context, const DeletedItemsScreen(), '/deleted'),
                ),
                _DrawerTile(
                  icon: Icons.history,
                  title: 'Activity Logs',
                  selected: currentRoute == '/logs',
                  onTap: () => _navigate(context, const ActivityLogsScreen(), '/logs'),
                ),
                _DrawerTile(
                  icon: Icons.description_outlined,
                  title: 'Reports',
                  selected: currentRoute == '/reports',
                  onTap: () => _navigate(context, const ReportsScreen(), '/reports'),
                ),
                const Divider(),
                _DrawerTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  selected: currentRoute == '/settings',
                  onTap: () => _navigate(context, const SettingsScreen(), '/settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen, String route) {
  Navigator.pop(context);

  if (currentRoute == route) return;

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => screen),
  );
}
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.primaryGold : AppColors.mutedText,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? AppColors.primaryGold : AppColors.darkText,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.primaryGold.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}
