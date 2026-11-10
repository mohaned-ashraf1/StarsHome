import 'package:flutter/material.dart';
import 'package:stars_home/frontend/constants/app_colors.dart';
import 'package:stars_home/backend/constants/database_dictionary.dart';

/// STARS HOMES ERP — Arabic Database Dictionary Screen
///
/// Provides Arabic-speaking factory administrators with a clean,
/// intuitive, and comprehensive viewer for the entire Supabase database.
class DatabaseDictionaryScreen extends StatefulWidget {
  const DatabaseDictionaryScreen({super.key});

  @override
  State<DatabaseDictionaryScreen> createState() =>
      _DatabaseDictionaryScreenState();
}

class _DatabaseDictionaryScreenState extends State<DatabaseDictionaryScreen> {
  String _searchQuery = '';
  String _selectedSchema = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tables = DatabaseDictionary.search(_searchQuery);
    if (_selectedSchema != 'all') {
      tables = tables.where((t) => t.schema == _selectedSchema).toList();
    }

    final totalTables = DatabaseDictionary.getAllTables().length;
    final totalColumns = DatabaseDictionary.getAllTables()
        .fold<int>(0, (sum, t) => sum + t.columns.length);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: const Text(
          'قاموس ودليل قاعدة البيانات (Supabase)',
          style: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Top Metrics Banner ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'إجمالي الجداول',
                      '$totalTables جدولاً',
                      'موثقة ومعربة',
                      AppColors.accentGold,
                      Icons.table_chart_outlined,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.surfaceBorder),
                  Expanded(
                    child: _buildMetricItem(
                      'إجمالي الأعمدة',
                      '$totalColumns عموداً',
                      'بأنواعها وعلاقاتها',
                      AppColors.incomeGreen,
                      Icons.view_column_outlined,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.surfaceBorder),
                  Expanded(
                    child: _buildMetricItem(
                      'المخططات (Schemas)',
                      '4 مخططات',
                      'public, auth, storage, realtime',
                      AppColors.infoBlue,
                      Icons.schema_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 2. Search & Filter Bar ─────────────────────────────────
            TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'ابحث باسم الجدول، العمود، أو الشرح بالعربية والإنجليزية...',
                hintStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.accentGold, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceDark,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.accentGold, width: 1.5),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 10),

            // Schema Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSchemaFilterChip('all', 'الكل ($totalTables)'),
                  _buildSchemaFilterChip('public', 'جداول المصنع (public)'),
                  _buildSchemaFilterChip('auth', 'المصادقة والأمان (auth)'),
                  _buildSchemaFilterChip('storage', 'الملفات والصور (storage)'),
                  _buildSchemaFilterChip('realtime', 'البث اللحظي (realtime)'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 3. Tables List ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الجداول المطابقة (${tables.length})',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'اضغط على الجدول لعرض الأعمدة والأنواع',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (tables.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
                    SizedBox(height: 10),
                    Text(
                      'لا توجد جداول أو أعمدة مطابقة للبحث',
                      style: TextStyle(color: AppColors.textWhite, fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tables.length,
                itemBuilder: (ctx, idx) => _buildTableCard(tables[idx]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          title,
          style: const TextStyle(color: AppColors.textWhite, fontSize: 10),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSchemaFilterChip(String schemaKey, String label) {
    final isSelected = _selectedSchema == schemaKey;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? AppColors.backgroundDark : AppColors.textWhite,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.accentGold,
        backgroundColor: AppColors.surfaceDark,
        checkmarkColor: AppColors.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.accentGold : AppColors.surfaceBorder,
          ),
        ),
        onSelected: (_) => setState(() => _selectedSchema = schemaKey),
      ),
    );
  }

  Widget _buildTableCard(TableMetadata table) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: AppColors.accentGold,
          iconColor: AppColors.accentGold,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            table.arabicName,
                            style: const TextStyle(
                              color: AppColors.accentGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Text(
                            table.name,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      table.description,
                      style: const TextStyle(
                          color: AppColors.textWhite, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.infoBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.infoBlue.withOpacity(0.4)),
                ),
                child: Text(
                  table.module,
                  style: const TextStyle(
                    color: AppColors.infoBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          children: [
            const Divider(color: AppColors.surfaceBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الأعمدة والبيانات (${table.columns.length} عموداً)',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'المخطط: ${table.schema}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...table.columns.map((col) => _buildColumnRow(col)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnRow(ColumnMetadata col) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                col.arabicName,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${col.name})',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  col.type,
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            col.description,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          if (col.relationship != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.link, size: 12, color: AppColors.infoBlue),
                const SizedBox(width: 4),
                Text(
                  'علاقة مع: ${col.relationship}',
                  style: const TextStyle(
                    color: AppColors.infoBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

