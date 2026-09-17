import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/models/department_model.dart';

class DashboardCharts extends StatelessWidget {
  const DashboardCharts({
    super.key,
    required this.stats,
    required this.departments,
  });
  final Map<String, int> stats;
  final List<Department> departments;

  @override
  Widget build(BuildContext context) {
    final values = [
      stats['goodCondition'] ?? 0,
      stats['needsRepair'] ?? 0,
      stats['depreciated'] ?? 0,
    ];
    final total = values.fold<int>(0, (a, b) => a + b);
    const colors = [AppColors.success, AppColors.warning, AppColors.error];
    const labels = ['Good condition', 'Needs repair', 'Depreciated'];
    final condition = _ChartCard(
      title: 'Item Condition',
      child: Column(
        children: [
          const Text(
            'Share of inventory items',
            style: TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 154,
            width: 154,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _DonutPainter(values, colors)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Text('items'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < values.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: colors[i]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(labels[i])),
                  Text(
                    '${values[i]} (${total == 0 ? '0' : (values[i] * 100 / total).toStringAsFixed(0)}%)',
                  ),
                ],
              ),
            ),
          if (total == 0) const Text('No inventory items yet.'),
        ],
      ),
    );
    final active = departments.where((d) => d.itemCount > 0).toList();
    final maxCount = active.fold<int>(0, (v, d) => math.max(v, d.itemCount));
    final distribution = _ChartCard(
      title: 'Department Distribution',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Number of inventory items',
            style: TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 20),
          if (active.isEmpty)
            const SizedBox(
              height: 220,
              child: Center(child: Text('No department data.')),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = math.max(
                  constraints.maxWidth,
                  active.length * 90.0,
                );
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    height: 262,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: active
                          .map(
                            (dept) => Expanded(
                              child: Semantics(
                                label:
                                    '${dept.departmentName}: ${dept.itemCount} items',
                                child: Tooltip(
                                  message:
                                      '${dept.departmentName}: ${dept.itemCount} items',
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 195,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${dept.itemCount}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              width: 30,
                                              height:
                                                  160 *
                                                  dept.itemCount /
                                                  maxCount,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGold,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(5),
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          4,
                                          10,
                                          4,
                                          0,
                                        ),
                                        child: Text(
                                          dept.departmentName.replaceAll(
                                            ' Department',
                                            '',
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [condition, const SizedBox(height: 12), distribution],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: condition),
            const SizedBox(width: 12),
            Expanded(child: distribution),
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.values, this.colors);
  final List<int> values;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(14);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26;
    paint.color = const Color(0xFFE5E7EB);
    canvas.drawArc(ring, 0, math.pi * 2, false, paint);
    final total = values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      paint.color = colors[i];
      canvas.drawArc(ring, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
