import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:olt_inventory/constants/app_colors.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/models/inventory_item_model.dart';
import 'package:olt_inventory/models/inventory_report_model.dart';
import 'package:olt_inventory/providers/department_provider.dart';
import 'package:olt_inventory/services/report_csv_service.dart';
import 'package:olt_inventory/services/report_pdf_service.dart';
import 'package:olt_inventory/services/report_service.dart';
import 'package:olt_inventory/utils/date_formatter.dart';
import 'package:olt_inventory/widgets/app_drawer.dart';
import 'package:olt_inventory/widgets/ced_category_dropdown.dart';
import 'package:olt_inventory/widgets/responsive_content.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _reportService = ReportService();

  String? _departmentId;
  String? _cedCategory;
  InventoryReportData? _reportData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepartmentProvider>().loadDepartments();
    });
  }

  bool _isCedSelected(DepartmentProvider provider) {
    if (_departmentId == null) return false;
    final dept = provider.findById(_departmentId!);
    return isCedDepartmentName(dept?.departmentName);
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final deptProvider = context.read<DepartmentProvider>();
      final deptName = _departmentId == null
          ? 'All Departments'
          : deptProvider.findById(_departmentId!)?.departmentName ??
              'Unknown';

      final data = await _reportService.generateReport(
        departmentId: _departmentId,
        departmentName: deptName,
        cedCategory: _isCedSelected(deptProvider) ? _cedCategory : null,
      );

      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _ensureReport() async {
    if (_reportData == null) {
      await _generateReport();
    }
  }

  Future<void> _printReport() async {
    await _ensureReport();
    if (_reportData == null || !mounted) return;

    try {
      await ReportPdfService.printReport(_reportData!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    await _ensureReport();
    if (_reportData == null || !mounted) return;

    try {
      await ReportPdfService.shareReport(_reportData!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF save failed: $e')),
        );
      }
    }
  }

  Future<void> _downloadCsv() async {
    await _ensureReport();
    if (_reportData == null || !mounted) return;

    try {
      await ReportCsvService.shareCsv(_reportData!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV download failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      drawer: const AppDrawer(currentRoute: '/reports'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return ResponsiveContent(
            padding: EdgeInsets.all(responsivePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _FilterCard(
                          departmentId: _departmentId,
                          cedCategory: _cedCategory,
                          isCedSelected: _isCedSelected,
                          onDepartmentChanged: _onDepartmentChanged,
                          onCedCategoryChanged: _onCedCategoryChanged,
                          onGenerate: _generateReport,
                          isLoading: _isLoading,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _buildPreviewArea(),
                      ),
                    ],
                  )
                else ...[
                  _FilterCard(
                    departmentId: _departmentId,
                    cedCategory: _cedCategory,
                    isCedSelected: _isCedSelected,
                    onDepartmentChanged: _onDepartmentChanged,
                    onCedCategoryChanged: _onCedCategoryChanged,
                    onGenerate: _generateReport,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildPreviewArea()),
                ],
                const SizedBox(height: 12),
                _ActionButtons(
                  isLoading: _isLoading,
                  isWide: isWide,
                  onDownloadCsv: _downloadCsv,
                  onSavePdf: _sharePdf,
                  onPrint: _printReport,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onDepartmentChanged(String? id) {
    setState(() {
      _departmentId = id;
      _cedCategory = null;
      _reportData = null;
    });
  }

  void _onCedCategoryChanged(String? value) {
    setState(() {
      _cedCategory = value;
      _reportData = null;
    });
  }

  Widget _buildPreviewArea() {
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: AppColors.error)),
      );
    }
    if (_isLoading && _reportData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reportData == null) {
      return _EmptyPreview();
    }
    return _ReportPreview(data: _reportData!);
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isLoading,
    required this.isWide,
    required this.onDownloadCsv,
    required this.onSavePdf,
    required this.onPrint,
  });

  final bool isLoading;
  final bool isWide;
  final VoidCallback onDownloadCsv;
  final VoidCallback onSavePdf;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      OutlinedButton.icon(
        onPressed: isLoading ? null : onDownloadCsv,
        icon: const Icon(Icons.table_chart_outlined),
        label: const Text('Download CSV'),
      ),
      OutlinedButton.icon(
        onPressed: isLoading ? null : onSavePdf,
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Save PDF'),
      ),
      ElevatedButton.icon(
        onPressed: isLoading ? null : onPrint,
        icon: const Icon(Icons.print),
        label: const Text('Print Report'),
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          Expanded(child: buttons[0]),
          const SizedBox(width: 12),
          Expanded(child: buttons[1]),
          const SizedBox(width: 12),
          Expanded(child: buttons[2]),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buttons[0],
        const SizedBox(height: 8),
        buttons[1],
        const SizedBox(height: 8),
        buttons[2],
      ],
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.departmentId,
    required this.cedCategory,
    required this.isCedSelected,
    required this.onDepartmentChanged,
    required this.onCedCategoryChanged,
    required this.onGenerate,
    required this.isLoading,
  });

  final String? departmentId;
  final String? cedCategory;
  final bool Function(DepartmentProvider) isCedSelected;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<String?> onCedCategoryChanged;
  final VoidCallback onGenerate;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Report Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select a department, generate the report, then print or download.',
              style: TextStyle(color: AppColors.mutedText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Consumer<DepartmentProvider>(
              builder: (context, provider, _) {
                return DropdownButtonFormField<String?>(
                  key: ValueKey('report-dept-$departmentId'),
                  initialValue: departmentId,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    hintText: 'All Departments',
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Departments'),
                    ),
                    ...provider.departments.map(
                      (d) => DropdownMenuItem<String?>(
                        value: d.id,
                        child: Text(d.departmentName),
                      ),
                    ),
                  ],
                  onChanged: onDepartmentChanged,
                );
              },
            ),
            Consumer<DepartmentProvider>(
              builder: (context, provider, _) {
                if (!isCedSelected(provider)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: CedDepartmentDropdown(
                    key: ValueKey('report-ced-$cedCategory'),
                    value: cedCategory,
                    isRequired: false,
                    onChanged: onCedCategoryChanged,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onGenerate,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.description_outlined),
              label: const Text('Generate Report'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.article_outlined, size: 64, color: AppColors.mutedText),
          const SizedBox(height: 16),
          const Text(
            'Select filters and generate a report',
            style: TextStyle(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReportPreview extends StatelessWidget {
  const _ReportPreview({required this.data});

  final InventoryReportData data;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 600;

    return Card(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isNarrow ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    AppConstants.churchName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isNarrow ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  Text(
                    AppConstants.churchLocation,
                    style: const TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const Text(
                    'INVENTORY REPORT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                ],
              ),
            ),
            if (isNarrow)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metaLine('Department', data.filterDepartmentName),
                  _metaLine('Report Type', data.reportType),
                  _metaLine('Scope', 'Active Items'),
                  _metaLine(
                    'Date',
                    DateFormatter.formatReportDate(data.generatedAt),
                  ),
                  _metaLine(
                    'Time',
                    DateFormatter.formatReportTime(data.generatedAt),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _metaLine('Department', data.filterDepartmentName),
                        _metaLine('Report Type', data.reportType),
                        _metaLine('Scope', 'Active Items'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _metaLine(
                          'Date',
                          DateFormatter.formatReportDate(data.generatedAt),
                        ),
                        _metaLine(
                          'Time',
                          DateFormatter.formatReportTime(data.generatedAt),
                        ),
                        _metaLine(
                          'Generated By',
                          AppConstants.reportGeneratedBy,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            _SummaryRow(data: data, isNarrow: isNarrow),
            const SizedBox(height: 16),
            const Text(
              'Inventory Items',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${AppConstants.churchMinistryName} UPDATED INVENTORY AS OF '
              '${DateFormatter.formatReportDate(data.generatedAt).toUpperCase()}',
              style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
            ),
            const SizedBox(height: 8),
            if (data.items.isEmpty)
              const Text('No items in this report.')
            else if (isNarrow)
              ...data.items.map(
                (item) => _MobileReportItem(
                  index: data.items.indexOf(item) + 1,
                  item: item,
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: width > 800 ? width - 120 : 700,
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.lightGrayCard,
                    ),
                    columns: const [
                      DataColumn(label: Text('ITEM NO')),
                      DataColumn(label: Text('ITEM NAME/ DESCRIPTION')),
                      DataColumn(label: Text('DETAILS')),
                      DataColumn(label: Text('ITEM STATUS')),
                      DataColumn(label: Text('OWNED BY')),
                      DataColumn(label: Text('REMARKS')),
                    ],
                    rows: data.items.asMap().entries.map((entry) {
                      final item = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text('${entry.key + 1}')),
                          DataCell(Text(item.productName)),
                          DataCell(Text(InventoryReportData.itemDetails(item))),
                          DataCell(Text(item.status)),
                          DataCell(Text(InventoryReportData.ownedBy(item))),
                          DataCell(Text(item.notes ?? '')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _metaLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.darkText, fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _MobileReportItem extends StatelessWidget {
  const _MobileReportItem({required this.index, required this.item});

  final int index;
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.lightGrayCard,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$index. ${item.productName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              InventoryReportData.itemDetails(item),
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),
            const SizedBox(height: 4),
            Text('Item Status: ${item.status}'),
            Text('Owned By: ${InventoryReportData.ownedBy(item)}'),
            if (item.notes != null && item.notes!.isNotEmpty)
              Text('Remarks: ${item.notes}'),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.data, required this.isNarrow});

  final InventoryReportData data;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Items', '${data.totalItems}'),
      ('Quantity', '${data.totalQuantity}'),
      ('Good Condition', '${data.goodConditionQuantity}'),
      ('Needs Repair', '${data.needsRepairQuantity}'),
      ('Depreciated', '${data.depreciatedQuantity}'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items
          .map(
            (item) => Container(
              width: isNarrow ? (MediaQuery.sizeOf(context).width / 2 - 36) : 110,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    item.$1,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
