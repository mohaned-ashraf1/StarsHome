/// STARS HOMES ERP — Database Dictionary & Translation Mapping (Arabic)
///
/// Provides complete runtime mappings of all Supabase / PostgreSQL tables,
/// columns, data types, Arabic labels, descriptions, and relationships.
/// Preserves English SQL identifiers internally while providing 100% Arabic UI context.
library;

class ColumnMetadata {
  final String name;
  final String arabicName;
  final String type;
  final String description;
  final String? relationship;

  const ColumnMetadata({
    required this.name,
    required this.arabicName,
    required this.type,
    required this.description,
    this.relationship,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'arabicName': arabicName,
        'type': type,
        'description': description,
        'relationship': relationship,
      };
}

class TableMetadata {
  final String name;
  final String arabicName;
  final String description;
  final String schema;
  final String module;
  final List<ColumnMetadata> columns;

  const TableMetadata({
    required this.name,
    required this.arabicName,
    required this.description,
    this.schema = 'public',
    required this.module,
    required this.columns,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'arabicName': arabicName,
        'description': description,
        'schema': schema,
        'module': module,
        'columns': columns.map((c) => c.toMap()).toList(),
      };
}

class DatabaseDictionary {
  DatabaseDictionary._();

  /// Returns the user-friendly Arabic label for any table.
  static String getTableLabel(String tableName) {
    final clean = tableName.replaceAll('public.', '').trim().toLowerCase();
    return _tables[clean]?.arabicName ?? tableName;
  }

  /// Returns the Arabic description for any table.
  static String getTableDescription(String tableName) {
    final clean = tableName.replaceAll('public.', '').trim().toLowerCase();
    return _tables[clean]?.description ?? '';
  }

  /// Returns the Arabic column label.
  static String getColumnLabel(String tableName, String columnName) {
    final cleanTable = tableName.replaceAll('public.', '').trim().toLowerCase();
    final table = _tables[cleanTable];
    if (table == null) return columnName;
    for (final col in table.columns) {
      if (col.name.toLowerCase() == columnName.trim().toLowerCase()) {
        return col.arabicName;
      }
    }
    return columnName;
  }

  /// Returns column description.
  static String getColumnDescription(String tableName, String columnName) {
    final cleanTable = tableName.replaceAll('public.', '').trim().toLowerCase();
    final table = _tables[cleanTable];
    if (table == null) return '';
    for (final col in table.columns) {
      if (col.name.toLowerCase() == columnName.trim().toLowerCase()) {
        return col.description;
      }
    }
    return '';
  }

  /// Gets table metadata by name.
  static TableMetadata? getTable(String tableName) {
    final clean = tableName.replaceAll('public.', '').trim().toLowerCase();
    return _tables[clean];
  }

  /// Returns all registered tables.
  static List<TableMetadata> getAllTables({String? schema}) {
    if (schema == null) return _tables.values.toList();
    return _tables.values.where((t) => t.schema == schema).toList();
  }

  /// Searches tables and columns by Arabic or English query.
  static List<TableMetadata> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAllTables();
    return _tables.values.where((t) {
      final matchTable = t.name.toLowerCase().contains(q) ||
          t.arabicName.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.module.toLowerCase().contains(q);
      if (matchTable) return true;
      return t.columns.any((c) =>
          c.name.toLowerCase().contains(q) ||
          c.arabicName.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q));
    }).toList();
  }

  // ── ALL TABLES REGISTRY ───────────────────────────────────────
  static final Map<String, TableMetadata> _tables = {
    // ── PUBLIC SCHEMA ───────────────────────────────────────────
    'profiles': const TableMetadata(
      name: 'profiles',
      arabicName: 'ملفات المستخدمين والصلاحيات',
      description: 'بيانات حسابات المالك والمدير في المصنع وتحديد مستويات الوصول والأمان.',
      module: 'الأمان والمستخدمين',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'المعرف الأساسي', type: 'UUID', description: 'معرف المستخدم المرتبط بحسابه في Supabase Auth', relationship: 'auth.users(id)'),
        ColumnMetadata(name: 'full_name', arabicName: 'الاسم بالكامل', type: 'TEXT', description: 'اسم المالك أو المدير المعروض في النظام'),
        ColumnMetadata(name: 'role', arabicName: 'الرتبة / الصلاحية', type: 'TEXT', description: 'دور المستخدم: مالك المصنع (owner) أو مدير المصنع (manager)'),
        ColumnMetadata(name: 'phone', arabicName: 'رقم الهاتف', type: 'TEXT', description: 'رقم هاتف المستخدم للتواصل'),
        ColumnMetadata(name: 'is_active', arabicName: 'حالة الحساب', type: 'BOOLEAN', description: 'هل الحساب نشط ومصرح له بالدخول للمصنع'),
        ColumnMetadata(name: 'created_at', arabicName: 'تاريخ الإنشاء', type: 'TIMESTAMPTZ', description: 'وقت وتاريخ إنشاء حساب المستخدم'),
        ColumnMetadata(name: 'updated_at', arabicName: 'تاريخ التحديث', type: 'TIMESTAMPTZ', description: 'وقت وتاريخ آخر تعديل لبيانات الحساب'),
      ],
    ),

    'categories': const TableMetadata(
      name: 'categories',
      arabicName: 'تصنيفات المصروفات والإيرادات',
      description: 'شجرة التصنيفات المعتمدة بالمصنع لتبويب بنود المشتريات والمصروفات والإيرادات بدقة.',
      module: 'المالية والحسابات',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'معرف التصنيف', type: 'TEXT / UUID', description: 'الرمز الفريد للتصنيف'),
        ColumnMetadata(name: 'name', arabicName: 'اسم التصنيف', type: 'TEXT', description: 'اسم التصنيف (أخشاب، إكسسوارات، وقود، مصاريف تشغيل...)'),
        ColumnMetadata(name: 'type', arabicName: 'نوع التصنيف', type: 'TEXT', description: 'هل هو تصنيف مصروف (expense) أم إيراد (income)'),
        ColumnMetadata(name: 'is_reusable', arabicName: 'قابل للاستخدام المتكرر', type: 'BOOLEAN', description: 'هل يظهر في القوائم المنسدلة السريعة'),
        ColumnMetadata(name: 'created_at', arabicName: 'تاريخ الإضافة', type: 'TIMESTAMPTZ', description: 'وقت إضافة التصنيف'),
      ],
    ),

    'item_suggestions': const TableMetadata(
      name: 'item_suggestions',
      arabicName: 'الاقتراحات السريعة لبنود الشراء',
      description: 'قاموس ذكي يحفظ أسماء الخامات الأكثر شراءً مع آخر سعر شراء وتكرار الاستخدام للاقتراح التلقائي السريع.',
      module: 'المشتريات والخزينة',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'المعرف الفريد', type: 'TEXT / UUID', description: 'الرمز الفريد للبند المقترح'),
        ColumnMetadata(name: 'item_name', arabicName: 'اسم الخامة / البند', type: 'TEXT', description: 'اسم الصنف المقترح (مثل: أبلكاش سي كا، غراء أبيض...)'),
        ColumnMetadata(name: 'default_category', arabicName: 'التصنيف الافتراضي', type: 'TEXT', description: 'التصنيف المقترن بهذا الصنف تلقائياً', relationship: 'categories(name)'),
        ColumnMetadata(name: 'last_unit_price', arabicName: 'آخر سعر شراء', type: 'NUMERIC(12, 2)', description: 'آخر سعر تم الشراء به للمقارنة والتسعير'),
        ColumnMetadata(name: 'times_used', arabicName: 'مرات الاستخدام', type: 'INTEGER', description: 'معدل تكرار شراء هذه الخامة لترتيب الأولويات'),
        ColumnMetadata(name: 'last_used_at', arabicName: 'تاريخ آخر استخدام', type: 'TIMESTAMPTZ', description: 'تاريخ آخر حركة شراء تضمنت هذا البند'),
      ],
    ),

    'purchases': const TableMetadata(
      name: 'purchases',
      arabicName: 'المشتريات ومصروفات المصنع',
      description: 'دفتر الخزينة للمصروفات، يسجل كل قرش يتم إنفاقه على الخامات والتشغيل والصيانة ويوميات النقل.',
      module: 'المشتريات والخزينة',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'المعرف الفريد', type: 'TEXT', description: 'كود العملية المالي الفريد'),
        ColumnMetadata(name: 'item_name', arabicName: 'اسم البند / الخامة', type: 'TEXT', description: 'وصف ما تم شراؤه بالتفصيل'),
        ColumnMetadata(name: 'category', arabicName: 'التصنيف', type: 'TEXT', description: 'قسم المصروف (أخشاب، إكسسوارات، وقود، صيانة...)', relationship: 'categories(name)'),
        ColumnMetadata(name: 'quantity', arabicName: 'الكمية المشتراة', type: 'NUMERIC(12, 2)', description: 'عدد الوحدات أو الألواح أو الكيلوجرامات'),
        ColumnMetadata(name: 'unit_price', arabicName: 'سعر الوحدة', type: 'NUMERIC(12, 2)', description: 'سعر القطعة أو اللوح الواحد بالجنيه'),
        ColumnMetadata(name: 'total_amount', arabicName: 'إجمالي المبلغ', type: 'NUMERIC(12, 2)', description: 'القيمة الكلية المدفوعة للبند بالجنيه المصري'),
        ColumnMetadata(name: 'transaction_date', arabicName: 'تاريخ المصروف', type: 'DATE', description: 'التاريخ الفعلي الذي تم فيه الدفع أو الشراء'),
        ColumnMetadata(name: 'notes', arabicName: 'ملاحظات وبيانات الفاتورة', type: 'TEXT', description: 'ملاحظات إضافية، اسم المورد، أو رقم الفاتورة'),
        ColumnMetadata(name: 'source_type', arabicName: 'نوع المصدر', type: 'TEXT', description: 'نوع المعاملة (مباشر، سلفة عامل، دفعة مقاول...)'),
        ColumnMetadata(name: 'source_id', arabicName: 'معرف السجل المرتبط', type: 'TEXT', description: 'المعرف المربوط به إذا كان سلفة أو دفعة مقاول'),
        ColumnMetadata(name: 'created_by', arabicName: 'القائم بالتسجيل', type: 'TEXT', description: 'اسم وتوقيع المالك/المدير الذي سجل الحركة'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت التسجيل', type: 'TIMESTAMPTZ', description: 'الطابع الزمني بالثانية لتسجيل الحركة'),
        ColumnMetadata(name: 'updated_at', arabicName: 'وقت التحديث', type: 'TIMESTAMPTZ', description: 'وقت آخر تعديل تم على السجل'),
        ColumnMetadata(name: 'is_reversed', arabicName: 'هل المعاملة ملغاة/معكوسة', type: 'BOOLEAN', description: 'تحديد ما إذا تم استرجاع المصروف أو إلغاؤه محاسبياً'),
        ColumnMetadata(name: 'reversed_at', arabicName: 'تاريخ الإلغاء', type: 'TIMESTAMPTZ', description: 'تاريخ ووقت تنفيذ الإلغاء'),
        ColumnMetadata(name: 'reversed_by', arabicName: 'القائم بالإلغاء', type: 'TEXT', description: 'اسم الشخص الذي اعتمد إلغاء المصروف'),
        ColumnMetadata(name: 'sync_status', arabicName: 'حالة المزامنة', type: 'TEXT', description: 'حالة المزامنة السحابية للحركة'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الهاتف أو الكمبيوتر الذي أنشأ الحركة لمنع التكرار'),
      ],
    ),

    'incomes': const TableMetadata(
      name: 'incomes',
      arabicName: 'سجل الإيرادات والدخل',
      description: 'دفتر المقبوضات المالية للمصنع، يشمل المبيعات المباشرة وبيع الفوارغ والمخلفات الخشبية وأي دخل خارجي.',
      module: 'المالية والحسابات',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'المعرف الفريد', type: 'TEXT', description: 'كود عملية الإيراد'),
        ColumnMetadata(name: 'source_name', arabicName: 'جهة أو مصدر الإيراد', type: 'TEXT', description: 'من أين دخل هذا المبلغ (بيع نشارة، دفعة عميل، استرداد تأمين...)'),
        ColumnMetadata(name: 'amount', arabicName: 'المبلغ المحصل', type: 'NUMERIC(12, 2)', description: 'قيمة الإيراد الفعلي بالجنيه المصري'),
        ColumnMetadata(name: 'transaction_date', arabicName: 'تاريخ التحصيل', type: 'DATE', description: 'تاريخ استلام المبلغ'),
        ColumnMetadata(name: 'notes', arabicName: 'تفاصيل وملاحظات', type: 'TEXT', description: 'بيان الإيصال أو تفاصيل التحويل المالي'),
        ColumnMetadata(name: 'created_by', arabicName: 'القائم بالاستلام', type: 'TEXT', description: 'اسم الموظف أو المدير المحصل'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت التسجيل', type: 'TIMESTAMPTZ', description: 'الطابع الزمني بالثانية'),
        ColumnMetadata(name: 'updated_at', arabicName: 'وقت التعديل', type: 'TIMESTAMPTZ', description: 'وقت آخر تحديث'),
        ColumnMetadata(name: 'is_reversed', arabicName: 'هل الإيراد ملغي/مسترد', type: 'BOOLEAN', description: 'لتسوية وإرجاع المبالغ عند الضرورة'),
        ColumnMetadata(name: 'reversed_at', arabicName: 'تاريخ الإلغاء', type: 'TIMESTAMPTZ', description: 'وقت اعتماد تسوية الإلغاء'),
        ColumnMetadata(name: 'reversed_by', arabicName: 'المعتمد للإلغاء', type: 'TEXT', description: 'اسم المسؤول الذي ألغى الإيراد'),
        ColumnMetadata(name: 'sync_status', arabicName: 'حالة المزامنة', type: 'TEXT', description: 'حالة مزامنة الإيراد سحابياً'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز المسجل'),
      ],
    ),

    'workers': const TableMetadata(
      name: 'workers',
      arabicName: 'ملفات عمال وفنيي المصنع',
      description: 'قاعدة بيانات الفنيين والصنايعية (نجارين، استورجية، تنجيد، مساعدين) وقيمة يومياتهم ومواعيد عملهم.',
      module: 'شؤون العمال والرواتب',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود العامل الفريد', type: 'TEXT', description: 'كود العامل داخل المصنع'),
        ColumnMetadata(name: 'full_name', arabicName: 'اسم العامل بالكامل', type: 'TEXT', description: 'الاسم الثلاثي أو الرباعي للصنايعي'),
        ColumnMetadata(name: 'daily_wage', arabicName: 'قيمة اليومية الأساسية', type: 'NUMERIC(12, 2)', description: 'أجر اليومية الرسمية المتفق عليها بالجنيه'),
        ColumnMetadata(name: 'standard_start_time', arabicName: 'موعد الحضور الرسمي', type: 'TEXT', description: 'موعد بدء الوردية المعتمد (مثل: 08:00)'),
        ColumnMetadata(name: 'standard_end_time', arabicName: 'موعد الانصراف الرسمي', type: 'TEXT', description: 'موعد نهاية الوردية (مثل: 19:00) وما بعده إضافي'),
        ColumnMetadata(name: 'overtime_hourly_rate', arabicName: 'سعر ساعة الإضافي', type: 'NUMERIC(12, 2)', description: 'أجر ساعة العمل الإضافية (Overtime)'),
        ColumnMetadata(name: 'phone', arabicName: 'رقم هاتف العامل', type: 'TEXT', description: 'رقم المحمول للتواصل والطوارئ'),
        ColumnMetadata(name: 'status', arabicName: 'حالة العامل', type: 'TEXT', description: 'هل هو على قوة العمل (active) أم موقوف (inactive)'),
        ColumnMetadata(name: 'notes', arabicName: 'ملاحظات التعيين', type: 'TEXT', description: 'تخصص الصنعة أو بيانات الضامن'),
        ColumnMetadata(name: 'created_at', arabicName: 'تاريخ إضافة الملف', type: 'TIMESTAMPTZ', description: 'تاريخ بدء تسجيله على النظام'),
        ColumnMetadata(name: 'updated_at', arabicName: 'تاريخ آخر تحديث', type: 'TIMESTAMPTZ', description: 'وقت تعديل اليومية أو البيانات'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز المسجل'),
      ],
    ),

    'worker_attendance': const TableMetadata(
      name: 'worker_attendance',
      arabicName: 'سجل حضور وانصراف العمال',
      description: 'كشف يومي دقيق يسجل حضور كل صنايعي ومواعيد الدخول والخروج واحتساب الساعات الإضافية أو الخصم آلياً.',
      module: 'شؤون العمال والرواتب',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'معرف سجل الحضور', type: 'TEXT', description: 'الرمز الفريد للحركة'),
        ColumnMetadata(name: 'worker_id', arabicName: 'كود العامل', type: 'TEXT', description: 'معرف العامل المسجل له الحضور', relationship: 'workers(id)'),
        ColumnMetadata(name: 'attendance_date', arabicName: 'تاريخ يوم العمل', type: 'DATE', description: 'يوم التحضير الفعلي'),
        ColumnMetadata(name: 'status', arabicName: 'حالة الحضور', type: 'TEXT', description: 'حاضر (present)، غائب (absent)، إجازة (leave)'),
        ColumnMetadata(name: 'arrival_time', arabicName: 'وقت الحضور الفعلي', type: 'TEXT', description: 'توقيت دخول الورشة (مثل: 08:05)'),
        ColumnMetadata(name: 'departure_time', arabicName: 'وقت الانصراف الفعلي', type: 'TEXT', description: 'توقيت الخروج الفعلي (مثل: 21:00)'),
        ColumnMetadata(name: 'total_duration_minutes', arabicName: 'إجمالي مدة العمل بالدقائق', type: 'INTEGER', description: 'زمن التواجد الفعلي بالورشة'),
        ColumnMetadata(name: 'overtime_duration_minutes', arabicName: 'مدة الإضافي بالدقائق', type: 'INTEGER', description: 'الساعات المحتسبة بعد موعد الانصراف الرسمي'),
        ColumnMetadata(name: 'overtime_pay', arabicName: 'مستحق الأجر الإضافي', type: 'NUMERIC(12, 2)', description: 'القيمة المالية المحتسبة لساعات الإضافي'),
        ColumnMetadata(name: 'daily_wage_applied', arabicName: 'اليومية المحتسبة لليوم', type: 'NUMERIC(12, 2)', description: 'قيمة اليومية المطبقة لهذا اليوم'),
        ColumnMetadata(name: 'notes', arabicName: 'ملاحظات الحضور', type: 'TEXT', description: 'سبب التأخير أو إذن الانصراف المبكر'),
        ColumnMetadata(name: 'created_by', arabicName: 'المشرف القائم بالتحضير', type: 'TEXT', description: 'اسم المشرف/المدير الذي سجل الحضور'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت التسجيل', type: 'TIMESTAMPTZ', description: 'وقت الإدخال'),
        ColumnMetadata(name: 'updated_at', arabicName: 'وقت التعديل', type: 'TIMESTAMPTZ', description: 'وقت التعديل'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'worker_financial_items': const TableMetadata(
      name: 'worker_financial_items',
      arabicName: 'السلف والمكافآت والجزاءات للعمال',
      description: 'دفتر الحركات المالية الفردية لكل عامل على مدار الأسبوع (سلف نقدية، مكافأة إجادة، خصومات وجزاءات تأخير).',
      module: 'شؤون العمال والرواتب',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'معرف السند المالي', type: 'TEXT', description: 'الكود الفريد للحركة'),
        ColumnMetadata(name: 'worker_id', arabicName: 'كود العامل', type: 'TEXT', description: 'العامل صاحب المعاملة المالية', relationship: 'workers(id)'),
        ColumnMetadata(name: 'type', arabicName: 'نوع الحركة', type: 'TEXT', description: 'سلفة (advance)، مكافأة (bonus)، خصم (deduction)'),
        ColumnMetadata(name: 'amount', arabicName: 'قيمة المعاملة', type: 'NUMERIC(12, 2)', description: 'المبلغ بالجنيه المصري'),
        ColumnMetadata(name: 'transaction_date', arabicName: 'تاريخ المعاملة', type: 'DATE', description: 'يوم صرف السلفة أو توقيع الجزاء'),
        ColumnMetadata(name: 'reason_notes', arabicName: 'السبب والتفاصيل', type: 'TEXT', description: 'بيان سبب السلفة أو المكافأة أو مخالفة الجزاء'),
        ColumnMetadata(name: 'is_settled_in_payroll', arabicName: 'هل تم تسويتها بالراتب', type: 'BOOLEAN', description: 'هل خُصمت في كشف الرواتب الأسبوعي أم معلقة'),
        ColumnMetadata(name: 'payroll_settlement_id', arabicName: 'كود تسوية الراتب', type: 'TEXT', description: 'رقم إقفال الأسبوع المرتبط به البند', relationship: 'worker_payroll_settlements(id)'),
        ColumnMetadata(name: 'linked_expense_id', arabicName: 'كود المصروف المقترن', type: 'TEXT', description: 'ربط السلفة بحركة الخزينة بجدول المشتريات', relationship: 'purchases(id)'),
        ColumnMetadata(name: 'created_by', arabicName: 'معتمد الحركة', type: 'TEXT', description: 'المسؤول الذي اعتمد الصرف أو الجزاء'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت التسجيل', type: 'TIMESTAMPTZ', description: 'وقت الإدخال'),
        ColumnMetadata(name: 'updated_at', arabicName: 'وقت التعديل', type: 'TIMESTAMPTZ', description: 'وقت التعديل'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'worker_payroll_settlements': const TableMetadata(
      name: 'worker_payroll_settlements',
      arabicName: 'كشوف تصفية رواتب العمال الأسبوعية',
      description: 'خلاصة حساب الأسبوع (يوم الخميس) لكل عامل: احتساب إجمالي الأيام والساعات والإضافي والمكافآت مع طرح السلف والخصومات لحساب صافي الصرف.',
      module: 'شؤون العمال والرواتب',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود التسوية الفريد', type: 'TEXT', description: 'رقم تصفية الراتب'),
        ColumnMetadata(name: 'worker_id', arabicName: 'كود العامل', type: 'TEXT', description: 'العامل صاحب الكشف', relationship: 'workers(id)'),
        ColumnMetadata(name: 'week_start_date', arabicName: 'بداية أسبوع المحاسبة', type: 'DATE', description: 'تاريخ أول يوم عمل في الأسبوع (السبت)'),
        ColumnMetadata(name: 'week_end_date', arabicName: 'نهاية أسبوع المحاسبة', type: 'DATE', description: 'تاريخ إقفال الحساب (الخميس)'),
        ColumnMetadata(name: 'days_attended', arabicName: 'عدد أيام الحضور', type: 'INTEGER', description: 'إجمالي الأيام التي حضرها العامل فعلياً'),
        ColumnMetadata(name: 'daily_wages_total', arabicName: 'إجمالي مستحق اليوميات', type: 'NUMERIC(12, 2)', description: 'مجموع أجور أيام الحضور'),
        ColumnMetadata(name: 'overtime_hours_total', arabicName: 'إجمالي ساعات الإضافي', type: 'NUMERIC(12, 2)', description: 'مجموع ساعات العمل الإضافي طوال الأسبوع'),
        ColumnMetadata(name: 'overtime_pay_total', arabicName: 'إجمالي أجر الإضافي', type: 'NUMERIC(12, 2)', description: 'قيمة الساعات الإضافية المالية'),
        ColumnMetadata(name: 'bonuses_total', arabicName: 'إجمالي المكافآت', type: 'NUMERIC(12, 2)', description: 'أي حوافز مستحقة للعامل خلال الأسبوع'),
        ColumnMetadata(name: 'advances_total', arabicName: 'إجمالي السلف المخصومة', type: 'NUMERIC(12, 2)', description: 'مجموع السلف التي استلمها العامل وتخصم الآن'),
        ColumnMetadata(name: 'deductions_total', arabicName: 'إجمالي الجزاءات', type: 'NUMERIC(12, 2)', description: 'مجموع الغيابات والخصومات المطبقة'),
        ColumnMetadata(name: 'gross_earnings', arabicName: 'إجمالي الاستحقاقات', type: 'NUMERIC(12, 2)', description: 'المستحق الإجمالي قبل الخصومات'),
        ColumnMetadata(name: 'net_due', arabicName: 'صافي الأجر المستحق', type: 'NUMERIC(12, 2)', description: 'المبلغ النهائي المستحق للعامل في نهاية الأسبوع'),
        ColumnMetadata(name: 'amount_paid', arabicName: 'المبلغ المنصرف فعلياً', type: 'NUMERIC(12, 2)', description: 'ما تم تسليمه للعامل نقداً'),
        ColumnMetadata(name: 'remaining_balance', arabicName: 'الرصيد المتبقي للعامل', type: 'NUMERIC(12, 2)', description: 'المتبقي إذا لم يتم الصرف بالكامل'),
        ColumnMetadata(name: 'payment_date', arabicName: 'تاريخ صرف الراتب', type: 'DATE', description: 'اليوم الذي تم فيه تسليم النقدية'),
        ColumnMetadata(name: 'payment_method', arabicName: 'طريقة الدفع', type: 'TEXT', description: 'وسيلة التسليم (cash نقدي، محفظة...)'),
        ColumnMetadata(name: 'notes', arabicName: 'ملاحظات التقفيل', type: 'TEXT', description: 'أي تسويات مرحلة للأسبوع القادم'),
        ColumnMetadata(name: 'is_settled', arabicName: 'هل الراتب مسدد بالكامل', type: 'BOOLEAN', description: 'هل تم سداد صافي الأسبوع كاملاً للعامل'),
        ColumnMetadata(name: 'linked_expense_id', arabicName: 'كود المصروف المرتبط', type: 'TEXT', description: 'كود بند المصروف المالي بالخزينة', relationship: 'purchases(id)'),
        ColumnMetadata(name: 'created_by', arabicName: 'معتمد التقفيل', type: 'TEXT', description: 'اسم المدير الذي راجع واعتمد الراتب'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت إنشاء الكشف', type: 'TIMESTAMPTZ', description: 'الطابع الزمني'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'contractors': const TableMetadata(
      name: 'contractors',
      arabicName: 'مقاولو الباطن والورش الخارجية',
      description: 'بيانات الورش الخارجية الشريكة (ورش دهانات دوكو/أستر، ماكينات راوتر CNC، تقطيع ليزر، مخارط خشب).',
      module: 'مقاولو الباطن والورش',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود المقاول الفريد', type: 'TEXT', description: 'المعرف المرجعي للورشة'),
        ColumnMetadata(name: 'name', arabicName: 'اسم المقاول / الورشة', type: 'TEXT', description: 'الاسم التجاري أو اسم صاحب الورشة'),
        ColumnMetadata(name: 'service_type', arabicName: 'نوع الخدمة المقدمة', type: 'TEXT', description: 'تخصص الورشة (دهانات، CNC، تقطيع ليزر، زجاج ومرايات...)'),
        ColumnMetadata(name: 'phone', arabicName: 'رقم هاتف الورشة', type: 'TEXT', description: 'رقم التواصل والواتساب للمتابعة'),
        ColumnMetadata(name: 'notes', arabicName: 'العنوان والملاحظات', type: 'TEXT', description: 'موقع الورشة، شروط التعامل، وأسعار الخدمات'),
        ColumnMetadata(name: 'status', arabicName: 'حالة التعامل', type: 'TEXT', description: 'نشط (active) أم موقوف (inactive)'),
        ColumnMetadata(name: 'created_at', arabicName: 'تاريخ إضافة الورشة', type: 'TIMESTAMPTZ', description: 'تاريخ فتح الحساب'),
        ColumnMetadata(name: 'updated_at', arabicName: 'تاريخ آخر تحديث', type: 'TIMESTAMPTZ', description: 'وقت التعديل'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'contractor_payments': const TableMetadata(
      name: 'contractor_payments',
      arabicName: 'دفعات وحسابات الورش ومقاولي الباطن',
      description: 'سندات صرف النقدية المحولة للورش الخارجية مقابل تشغيل قطع الأثاث.',
      module: 'مقاولو الباطن والورش',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود الدفعة الفريد', type: 'TEXT', description: 'رقم إيصال الصرف'),
        ColumnMetadata(name: 'contractor_id', arabicName: 'كود المقاول / الورشة', type: 'TEXT', description: 'الورشة المستلمة للدفعة', relationship: 'contractors(id)'),
        ColumnMetadata(name: 'description', arabicName: 'بيان الخدمة المؤداة', type: 'TEXT', description: 'تفاصيل الشغل (مثل: دهان غرفة نوم رئيسية مط)'),
        ColumnMetadata(name: 'amount', arabicName: 'قيمة الدفعة', type: 'NUMERIC(12, 2)', description: 'المبلغ المدفوع بالجنيه'),
        ColumnMetadata(name: 'payment_date', arabicName: 'تاريخ سداد الدفعة', type: 'DATE', description: 'يوم الصرف الفعلي'),
        ColumnMetadata(name: 'related_order', arabicName: 'رقم طلبية العميل', type: 'TEXT', description: 'الطلبية التي تنتمي إليها هذه القطعة'),
        ColumnMetadata(name: 'notes', arabicName: 'ملاحظات الإيصال', type: 'TEXT', description: 'رقم إيصال الاستلام أو الشيك'),
        ColumnMetadata(name: 'linked_expense_id', arabicName: 'كود المصروف بالخزينة', type: 'TEXT', description: 'ربط الصرف بحسابات المشتريات بالخزينة', relationship: 'purchases(id)'),
        ColumnMetadata(name: 'created_by', arabicName: 'القائم بالصرف', type: 'TEXT', description: 'اسم من قام بسداد المبلغ'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت التسجيل', type: 'TIMESTAMPTZ', description: 'الطابع الزمني'),
        ColumnMetadata(name: 'updated_at', arabicName: 'وقت التعديل', type: 'TIMESTAMPTZ', description: 'وقت التعديل'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'customer_orders': const TableMetadata(
      name: 'customer_orders',
      arabicName: 'طلبيات وعقود العملاء',
      description: 'العمود الفقري للمصنع؛ يسجل اتفاقات العملاء لتصنيع الأثاث، ومواصفات وتفاصيل الغرف، والتواريخ والمبالغ المالية.',
      module: 'العملاء والطلبيات',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود الطلب الفريد', type: 'TEXT', description: 'المعرف المرجعي الأساسي للطلب'),
        ColumnMetadata(name: 'customer_name', arabicName: 'اسم العميل بالكامل', type: 'TEXT', description: 'اسم العميل أو المعرض المتعاقد'),
        ColumnMetadata(name: 'phone', arabicName: 'رقم هاتف العميل', type: 'TEXT', description: 'رقم المحمول والواتساب لإرسال الفواتير والتنبيهات'),
        ColumnMetadata(name: 'order_description', arabicName: 'الوصف العام للطلبية', type: 'TEXT', description: 'ملخص الاتفاق والبنود الأساسية'),
        ColumnMetadata(name: 'start_date', arabicName: 'تاريخ بدء الطلب والتعاقد', type: 'DATE', description: 'اليوم الذي تم فيه الاتفاق ودفع العربون'),
        ColumnMetadata(name: 'delivery_date', arabicName: 'تاريخ التسليم المتفق عليه', type: 'DATE', description: 'الموعد النهائي لتسليم الأثاث للعميل'),
        ColumnMetadata(name: 'total_amount', arabicName: 'إجمالي قيمة الطلبية', type: 'NUMERIC(12, 2)', description: 'السعر المتفق عليه لتصنيع الطلبية بالكامل'),
        ColumnMetadata(name: 'status', arabicName: 'حالة تنفيذ الطلب', type: 'TEXT', description: 'قيد التنفيذ (in_progress)، جاهز (ready)، تم التسليم (delivered)، ملغي (cancelled)'),
        ColumnMetadata(name: 'notes', arabicName: 'مواصفات تفصيلية وتقسيمات', type: 'TEXT', description: 'يحفظ تفاصيل القطع والأقسام وبيانات الصور JSON'),
        ColumnMetadata(name: 'created_by', arabicName: 'مدخل الطلب / البائع', type: 'TEXT', description: 'اسم وتوقيع من حرر العقد مع العميل'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت إنشاء العقد', type: 'TIMESTAMPTZ', description: 'الطابع الزمني للتعاقد'),
        ColumnMetadata(name: 'updated_at', arabicName: 'وقت آخر تحديث', type: 'TIMESTAMPTZ', description: 'وقت تعديل الحالة أو المواصفات'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'order_payments': const TableMetadata(
      name: 'order_payments',
      arabicName: 'دفعات وعرابين طلبيات العملاء',
      description: 'كشف الدفعات المالية المسددة من قبل العميل على دفعات (عربون التعاقد، دفعة النجارة، دفعة الدهان، تسوية التسليم).',
      module: 'العملاء والطلبيات',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود إيصال الدفعة', type: 'TEXT', description: 'رقم إيصال التحصيل'),
        ColumnMetadata(name: 'order_id', arabicName: 'كود طلبية العميل', type: 'TEXT', description: 'الطلبية التابعة لها هذه الدفعة', relationship: 'customer_orders(id)'),
        ColumnMetadata(name: 'amount', arabicName: 'قيمة الدفعة المسددة', type: 'NUMERIC(12, 2)', description: 'المبلغ المحصل بالجنيه المصري'),
        ColumnMetadata(name: 'payment_date', arabicName: 'تاريخ التحصيل', type: 'DATE', description: 'يوم سداد المبلغ'),
        ColumnMetadata(name: 'payment_method', arabicName: 'طريقة الدفع', type: 'TEXT', description: 'نقدي، إنستاباي، فودافون كاش، تحويل بنكي، شيك'),
        ColumnMetadata(name: 'notes', arabicName: 'ملاحظات الإيصال', type: 'TEXT', description: 'رقم الحوالة أو اسم صاحب المحفظة المحول منها'),
        ColumnMetadata(name: 'linked_income_id', arabicName: 'كود الإيراد بالخزينة', type: 'TEXT', description: 'ربط الدفعة بحسابات الإيراد العام للمصنع', relationship: 'incomes(id)'),
        ColumnMetadata(name: 'created_by', arabicName: 'محرر الإيصال والمحصل', type: 'TEXT', description: 'اسم المدير الذي استلم المبلغ'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت تسجيل الدفعة', type: 'TIMESTAMPTZ', description: 'وقت الإدخال'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'debts_advances': const TableMetadata(
      name: 'debts_advances',
      arabicName: 'الديون والسلف والأمانات الخارجية',
      description: 'إدارة المبالغ الآجلة مع جهات وأشخاص خارج الورشة (ديون على المصنع لتجار أخشاب، ديون للمصنع لدى معارض، سلف خارجية).',
      module: 'الديون والأمانات',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود السجل الفريد', type: 'TEXT', description: 'المعرف المرجعي'),
        ColumnMetadata(name: 'person_name', arabicName: 'اسم الطرف الآخر', type: 'TEXT', description: 'اسم الشخص أو التاجر أو الشركة صاحبة الدين'),
        ColumnMetadata(name: 'phone', arabicName: 'رقم هاتف الطرف الآخر', type: 'TEXT', description: 'رقم المحمول للمطالبة والمتابعة'),
        ColumnMetadata(name: 'type', arabicName: 'تصنيف الدين', type: 'TEXT', description: 'سلفة (advance)، دين لنا (debt_receivable)، دين علينا (debt_payable)'),
        ColumnMetadata(name: 'amount', arabicName: 'أصل مبلغ الدين', type: 'NUMERIC(12, 2)', description: 'إجمالي القيمة الأصلية بالجنيه'),
        ColumnMetadata(name: 'paid_amount', arabicName: 'إجمالي ما تم سداده', type: 'NUMERIC(12, 2)', description: 'المجموع التراكمي للأقساط المسددة'),
        ColumnMetadata(name: 'transaction_date', arabicName: 'تاريخ نشوء الدين', type: 'DATE', description: 'يوم الاتفاق أو الشراء الآجل'),
        ColumnMetadata(name: 'due_date', arabicName: 'موعد استحقاق السداد', type: 'DATE', description: 'الموعد النهائي المتفق عليه للوفاء بالدين'),
        ColumnMetadata(name: 'status', arabicName: 'حالة الدين', type: 'TEXT', description: 'قائم ومستمر (active) أم تم السداد والإقفال (settled)'),
        ColumnMetadata(name: 'notes', arabicName: 'التفاصيل والضمانات', type: 'TEXT', description: 'شروط السداد، البضاعة المقابلة، أو تفاصيل الشيك'),
        ColumnMetadata(name: 'created_by', arabicName: 'القائم بالتسجيل', type: 'TEXT', description: 'المسؤول عن تسجيل الحركة'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت الإنشاء', type: 'TIMESTAMPTZ', description: 'الطابع الزمني'),
        ColumnMetadata(name: 'updated_at', arabicName: 'وقت التعديل', type: 'TIMESTAMPTZ', description: 'وقت التعديل'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'debt_advance_payments': const TableMetadata(
      name: 'debt_advance_payments',
      arabicName: 'دفعات وأقساط سداد الديون الخارجية',
      description: 'كشف تفصيلي بحركات سداد الأقساط سواء كانت مبالغ يدفعها المصنع للغير، أو مبالغ يستلمها المصنع من مدينين.',
      module: 'الديون والأمانات',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود دفعة السداد', type: 'TEXT', description: 'رقم سند السداد'),
        ColumnMetadata(name: 'debt_advance_id', arabicName: 'كود أصل الدين', type: 'TEXT', description: 'الدين المسدد منه هذا القسط', relationship: 'debts_advances(id)'),
        ColumnMetadata(name: 'amount', arabicName: 'قيمة القسط المسدد', type: 'NUMERIC(12, 2)', description: 'المبلغ المدفوع بالجنيه'),
        ColumnMetadata(name: 'payment_date', arabicName: 'تاريخ السداد', type: 'DATE', description: 'يوم دفع أو قبض القسط'),
        ColumnMetadata(name: 'notes', arabicName: 'ملاحظات الإيصال', type: 'TEXT', description: 'رقم التحويل أو إيصال السداد'),
        ColumnMetadata(name: 'created_by', arabicName: 'مستلم / منفذ السداد', type: 'TEXT', description: 'اسم القائم بالعملية'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت التسجيل', type: 'TIMESTAMPTZ', description: 'الطابع الزمني'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'inventory_items': const TableMetadata(
      name: 'inventory_items',
      arabicName: 'أصناف وخامات المخزون',
      description: 'كشف كميات الخامات المتوفرة في المخزن (ألواح خشب، أبلكاش، سويد، زان، مسامير، دهانات، مفصلات ومقابض) مع حدود الأمان للتنبيه بالنقص.',
      module: 'المخازن والخامات',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود الخامة الفريد', type: 'TEXT / UUID', description: 'المعرف المرجعي للصنف'),
        ColumnMetadata(name: 'material_name', arabicName: 'اسم الخامة / الصنف', type: 'TEXT', description: 'المسمى التجاري (مثل: خشب زان روماني، أبلكاش 12مم)'),
        ColumnMetadata(name: 'category', arabicName: 'تصنيف الخامة', type: 'TEXT', description: 'قسم المخزن (أخشاب، إكسسوارات، أقمشة، دهانات)', relationship: 'categories(name)'),
        ColumnMetadata(name: 'unit', arabicName: 'وحدة القياس', type: 'TEXT', description: 'وحدة الحساب (لوح، متر، قطعة، كجم، علبة، لفة)'),
        ColumnMetadata(name: 'current_stock', arabicName: 'الرصيد الفعلي الحالي', type: 'NUMERIC(12, 2)', description: 'الكمية الموجودة على أرض المخزن فعلياً'),
        ColumnMetadata(name: 'reserved_stock', arabicName: 'الرصيد المحجوز للشغل', type: 'NUMERIC(12, 2)', description: 'كميات مجنبة لأوامر تصنيع معتمدة بالورشة'),
        ColumnMetadata(name: 'minimum_stock_level', arabicName: 'حد الطلب الأدنى للتنبيه', type: 'NUMERIC(12, 2)', description: 'كمية الأمان؛ إذا قل الرصيد عنها يرسل النظام إنذار نقص'),
        ColumnMetadata(name: 'unit_cost', arabicName: 'تكلفة الوحدة التقديرية', type: 'NUMERIC(12, 2)', description: 'متوسط سعر شراء الوحدة بالجنيه'),
        ColumnMetadata(name: 'notes', arabicName: 'تفاصيل وموقع التخزين', type: 'TEXT', description: 'مكان التخزين في الورشة أو ملاحظات الجودة'),
        ColumnMetadata(name: 'created_at', arabicName: 'تاريخ إضافة الصنف', type: 'TIMESTAMPTZ', description: 'تاريخ فتح كارت الصنف'),
        ColumnMetadata(name: 'updated_at', arabicName: 'تاريخ آخر جرد/تعديل', type: 'TIMESTAMPTZ', description: 'وقت تحديث الرصيد'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'inventory_movements': const TableMetadata(
      name: 'inventory_movements',
      arabicName: 'سجل حركات المخزن (الوارد والمنصرف)',
      description: 'دفتر حركات المخزن يسجل كل إضافة أو صرف خامات للورشة أو تسوية جرد أو مرتجع.',
      module: 'المخازن والخامات',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود الحركة الفريد', type: 'TEXT', description: 'رقم إذن المخزن'),
        ColumnMetadata(name: 'inventory_item_id', arabicName: 'كود صنف المخزن', type: 'TEXT / UUID', description: 'الخامة التي تمت عليها الحركة', relationship: 'inventory_items(id)'),
        ColumnMetadata(name: 'movement_type', arabicName: 'نوع حركة المخزن', type: 'TEXT', description: 'وارد (receipt)، منصرف تصنيع (issue)، تسوية (adjustment)، مرتجع (return)'),
        ColumnMetadata(name: 'quantity', arabicName: 'الكمية', type: 'NUMERIC(12, 2)', description: 'الكمية المضافة أو المنصرفة'),
        ColumnMetadata(name: 'reference_type', arabicName: 'نوع المستند المرجعي', type: 'TEXT', description: 'نوع السند (شراء، أمر تصنيع، يدوي)'),
        ColumnMetadata(name: 'reference_id', arabicName: 'رقم المستند المرجعي', type: 'TEXT', description: 'كود أمر التصنيع أو كود الفاتورة التابع لها الصرف'),
        ColumnMetadata(name: 'reason_notes', arabicName: 'سبب الحركة', type: 'TEXT', description: 'بيان سبب الصرف أو تسوية عجز/زيادة الجرد'),
        ColumnMetadata(name: 'created_by', arabicName: 'أمين المخزن / القائم بالصرف', type: 'TEXT', description: 'اسم الموظف المسؤول'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت تنفيذ الحركة', type: 'TIMESTAMPTZ', description: 'وقت الصرف أو الاستلام'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'inventory_reservations': const TableMetadata(
      name: 'inventory_reservations',
      arabicName: 'حجوزات الخامات لأوامر التشغيل',
      description: 'حجز وتخصيص كميات من الأخشاب والخامات لأمر تشغيل معين حتى لا يقوم فني آخر باستهلاكها في قطعة أخرى.',
      module: 'المخازن والخامات',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'معرف الحجز الفريد', type: 'TEXT', description: 'كود الحجز'),
        ColumnMetadata(name: 'manufacturing_order_id', arabicName: 'كود أمر التصنيع', type: 'TEXT', description: 'أمر التشغيل المحجوز له الخامات', relationship: 'manufacturing_orders(id)'),
        ColumnMetadata(name: 'inventory_item_id', arabicName: 'كود صنف المخزن', type: 'TEXT / UUID', description: 'الخامة المحجوزة', relationship: 'inventory_items(id)'),
        ColumnMetadata(name: 'reserved_quantity', arabicName: 'الكمية المحجوزة', type: 'NUMERIC(12, 2)', description: 'عدد الألواح أو الوحدات المحجوزة للقطعة'),
        ColumnMetadata(name: 'status', arabicName: 'حالة الحجز', type: 'TEXT', description: 'محجوز ساري (active)، تم الاستهلاك (consumed)، تم فك الحجز (released)'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت الحجز', type: 'TIMESTAMPTZ', description: 'تاريخ ووقت تخصيص الكمية'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'material_shortages': const TableMetadata(
      name: 'material_shortages',
      arabicName: 'كشف النواقص والخامات المطلوبة',
      description: 'شاشة إشعارات النواقص لمدير المشتريات؛ يسجل الخامات غير المتوفرة التي تعطل خط الإنتاج لشرائها فوراً.',
      module: 'المخازن والخامات',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود النقص الفريد', type: 'TEXT', description: 'رقم إشعار النقص'),
        ColumnMetadata(name: 'material_name', arabicName: 'اسم الخامة الناقصة', type: 'TEXT', description: 'وصف الصنف المطلوب شراؤه عاجلاً'),
        ColumnMetadata(name: 'quantity', arabicName: 'الكمية المطلوبة', type: 'NUMERIC(12, 2)', description: 'الكمية اللازمة لإكمال العمل'),
        ColumnMetadata(name: 'unit', arabicName: 'وحدة القياس', type: 'TEXT', description: 'لوح، متر، كجم، علبة...'),
        ColumnMetadata(name: 'specifications', arabicName: 'المواصفات والأبعاد', type: 'TEXT', description: 'التخانة أو اللون أو الجودة المطلوبة'),
        ColumnMetadata(name: 'notes', arabicName: 'ملاحظات الأهمية', type: 'TEXT', description: 'درجة الاستعجال والورشة التابعة لها'),
        ColumnMetadata(name: 'manufacturing_order_id', arabicName: 'كود أمر التشغيل المعطل', type: 'TEXT', description: 'أمر التصنيع المتوقف على هذه الخامة', relationship: 'manufacturing_orders(id)'),
        ColumnMetadata(name: 'manufacturing_order_number', arabicName: 'رقم أمر التشغيل', type: 'TEXT', description: 'الكود المكتبي لأمر التشغيل'),
        ColumnMetadata(name: 'status', arabicName: 'حالة النقص', type: 'TEXT', description: 'عجز مطلوب شراؤه (shortage)، جاري الشراء (in_progress)، تم التوريد (resolved)'),
        ColumnMetadata(name: 'recorded_by', arabicName: 'مُبلّغ النقص', type: 'TEXT', description: 'الصنايعي أو المشرف الذي أبلغ عن العجز'),
        ColumnMetadata(name: 'recorded_at', arabicName: 'وقت الإبلاغ', type: 'TIMESTAMPTZ', description: 'تاريخ ووقت تسجيل الإشعار'),
        ColumnMetadata(name: 'resolved_by', arabicName: 'القائم بالشراء والحل', type: 'TEXT', description: 'من قام بتوفير الخامة في الورشة'),
        ColumnMetadata(name: 'resolved_at', arabicName: 'وقت توفير الخامة', type: 'TIMESTAMPTZ', description: 'وقت حل المشكلة'),
        ColumnMetadata(name: 'updated_at', arabicName: 'وقت التعديل', type: 'TIMESTAMPTZ', description: 'وقت التعديل'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'manufacturing_orders': const TableMetadata(
      name: 'manufacturing_orders',
      arabicName: 'أوامر تشغيل وتصنيع الموبيليا بالورشة',
      description: 'كارت تشغيل الموبيليا داخل الورشة لكل قطعة أثاث (غرفة نوم، دولاب، دريسينج، بوفيه، أنتريه) لمتابعة خط الإنتاج من النجارة للدهان والتنجيد.',
      module: 'أوامر التصنيع والإنتاج',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود أمر التشغيل الفريد', type: 'TEXT', description: 'المعرف المرجعي الداخلي'),
        ColumnMetadata(name: 'order_number', arabicName: 'رقم أمر التشغيل الرسمي', type: 'TEXT', description: 'كود التشغيل المطبوع بالورشة (مثل: MO-2026-001)'),
        ColumnMetadata(name: 'customer_order_id', arabicName: 'كود طلبية العميل', type: 'TEXT', description: 'الطلبية التابع لها هذا الأمر', relationship: 'customer_orders(id)'),
        ColumnMetadata(name: 'customer_name', arabicName: 'اسم العميل', type: 'TEXT', description: 'اسم صاحب الطلب لسهولة التعرف'),
        ColumnMetadata(name: 'product_name', arabicName: 'اسم القطعة المطلوبة', type: 'TEXT', description: 'اسم الموديل (غرفة نوم ماستر خشب زان، دولاب جرار 3 ضلفة...)'),
        ColumnMetadata(name: 'product_category', arabicName: 'تصنيف المنتج', type: 'TEXT', description: 'أثاث خشبي، تنجيد وصالون، مطابخ...'),
        ColumnMetadata(name: 'quantity', arabicName: 'الكمية', type: 'INTEGER', description: 'عدد القطع المطلوب تصنيعها'),
        ColumnMetadata(name: 'manufacturing_date', arabicName: 'تاريخ بدء التصنيع', type: 'DATE', description: 'يوم تسليم الخامات للصنايعي بالورشة'),
        ColumnMetadata(name: 'expected_completion_date', arabicName: 'الموعد المتوقع للانتهاء', type: 'DATE', description: 'موعد خروج القطعة للتسليم'),
        ColumnMetadata(name: 'assigned_worker_id', arabicName: 'كود الفني المسؤول', type: 'TEXT', description: 'الأسطى أو النجار المسؤول عن تنفيذ القطعة', relationship: 'workers(id)'),
        ColumnMetadata(name: 'assigned_worker_name', arabicName: 'اسم الفني المسؤول', type: 'TEXT', description: 'اسم النجار للتيسير في الطباعة والتقارير'),
        ColumnMetadata(name: 'status', arabicName: 'مرحلة تصنيع القطعة', type: 'TEXT', description: 'جديد (new)، انتظار خامات (awaiting_materials)، جاهز للتجميع (ready_to_build)، جاري العمل (in_progress)، مكتمل (completed)'),
        ColumnMetadata(name: 'notes', arabicName: 'ملاحظات التصنيع', type: 'TEXT', description: 'تعليمات خاصة بالنجارة أو الدهان'),
        ColumnMetadata(name: 'sections_data', arabicName: 'بيانات التقسيم والصور', type: 'JSONB', description: 'بنية تفصيلية تحتوي أبعاد وموديلات وصور القطعة بتنسيق JSON'),
        ColumnMetadata(name: 'created_by', arabicName: 'محرر أمر التشغيل', type: 'TEXT', description: 'اسم المدير الذي أصدر الأمر'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت إصدار الأمر', type: 'TIMESTAMPTZ', description: 'الطابع الزمني'),
        ColumnMetadata(name: 'updated_at', arabicName: 'وقت آخر تحديث', type: 'TIMESTAMPTZ', description: 'وقت تعديل المرحلة'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'manufacturing_order_dimensions': const TableMetadata(
      name: 'manufacturing_order_dimensions',
      arabicName: 'المقاسات والأبعاد الهندسية للقطع',
      description: 'كشف المقاسات الهندسية الدقيقة للقطعة (الارتفاع، العرض، العمق، التخانة) لضمان دقة التقطيع في ورشة النجارة.',
      module: 'أوامر التصنيع والإنتاج',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود المقاس الفريد', type: 'TEXT', description: 'المعرف المرجعي'),
        ColumnMetadata(name: 'manufacturing_order_id', arabicName: 'كود أمر التشغيل', type: 'TEXT', description: 'أمر التصنيع التابع له هذا البُعد', relationship: 'manufacturing_orders(id)'),
        ColumnMetadata(name: 'height', arabicName: 'الارتفاع', type: 'NUMERIC(8, 2)', description: 'ارتفاع القطعة (مثلاً 220 سم)'),
        ColumnMetadata(name: 'width', arabicName: 'العرض', type: 'NUMERIC(8, 2)', description: 'عرض القطعة (مثلاً 280 سم)'),
        ColumnMetadata(name: 'depth', arabicName: 'العمق / التخانة', type: 'NUMERIC(8, 2)', description: 'عمق القطعة (مثلاً 60 سم للدولاب)'),
        ColumnMetadata(name: 'unit', arabicName: 'وحدة القياس', type: 'TEXT', description: 'سم، متر، مم'),
        ColumnMetadata(name: 'additional_notes', arabicName: 'ملاحظات هندسية', type: 'TEXT', description: 'تعليمات خاصة بالبروز أو الشطف أو الأدراج'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت التسجيل', type: 'TIMESTAMPTZ', description: 'الطابع الزمني'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'manufacturing_order_materials': const TableMetadata(
      name: 'manufacturing_order_materials',
      arabicName: 'خامات ومستهلكات أمر التشغيل (BOM)',
      description: 'بوم المواد (Bill of Materials) لكل قطعة موبيليا؛ يحدد كل لوح ونوع خشب ومفصلة لازمة لتصنيع القطعة.',
      module: 'أوامر التصنيع والإنتاج',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'معرف خامة الأمر', type: 'TEXT', description: 'كود البند'),
        ColumnMetadata(name: 'manufacturing_order_id', arabicName: 'كود أمر التشغيل', type: 'TEXT', description: 'أمر التصنيع التابع له', relationship: 'manufacturing_orders(id)'),
        ColumnMetadata(name: 'inventory_item_id', arabicName: 'كود الصنف بالمخزن', type: 'TEXT / UUID', description: 'الربط بصنف المخزن لخصم الرصيد تلقائياً', relationship: 'inventory_items(id)'),
        ColumnMetadata(name: 'material_name', arabicName: 'اسم الخامة', type: 'TEXT', description: 'وصف الخامة المطلوبة'),
        ColumnMetadata(name: 'required_quantity', arabicName: 'الكمية المقررة', type: 'NUMERIC(12, 2)', description: 'الكمية المحددة لتصنيع هذه القطعة'),
        ColumnMetadata(name: 'unit', arabicName: 'وحدة القياس', type: 'TEXT', description: 'لوح، قطعة، طقم، متر...'),
        ColumnMetadata(name: 'specifications', arabicName: 'المواصفات الفنية', type: 'TEXT', description: 'نوع الأبلكاش، ماركة المفصلات (باكم، بلوم...)'),
        ColumnMetadata(name: 'notes', arabicName: 'ملاحظات الاستهلاك', type: 'TEXT', description: 'توجيهات للنجار أثناء التقطيع'),
        ColumnMetadata(name: 'thickness_grade', arabicName: 'التخانة / الدرجة', type: 'TEXT', description: 'سمك اللوح أو درجة نقاء الخشب'),
        ColumnMetadata(name: 'color_code', arabicName: 'كود اللون', type: 'TEXT', description: 'كود لون الدهان أو كود القماش المعتمد'),
        ColumnMetadata(name: 'linked_piece', arabicName: 'الجزء المرتبط بالقطعة', type: 'TEXT', description: 'الباب، الدرج، القرصة، الظهر، القاعدة'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت الإضافة', type: 'TIMESTAMPTZ', description: 'الطابع الزمني'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'manufacturing_checklist': const TableMetadata(
      name: 'manufacturing_checklist',
      arabicName: 'قائمة مراجعة وجاهزية الخامات',
      description: 'كشف تأكيد لجودة وجاهزية خامات القطعة قبل إعطاء الإذن للنجار ببدء التصنيع لتجنب توقف الشغل في منتصفه.',
      module: 'أوامر التصنيع والإنتاج',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'معرف بند الفحص', type: 'TEXT', description: 'الرمز الفريد'),
        ColumnMetadata(name: 'manufacturing_order_id', arabicName: 'كود أمر التشغيل', type: 'TEXT', description: 'أمر التصنيع المرتبط', relationship: 'manufacturing_orders(id)'),
        ColumnMetadata(name: 'material_name', arabicName: 'اسم الخامة المطلوب فحصها', type: 'TEXT', description: 'وصف المادة المراد التأكد من وجودها'),
        ColumnMetadata(name: 'required_quantity', arabicName: 'الكمية المطلوبة', type: 'NUMERIC(12, 2)', description: 'الكمية الكافية للشغل'),
        ColumnMetadata(name: 'unit', arabicName: 'وحدة القياس', type: 'TEXT', description: 'لوح، قطعة...'),
        ColumnMetadata(name: 'status', arabicName: 'حالة الجاهزية', type: 'TEXT', description: 'مطلوبة (required)، تم طلبها (ordered)، وصلت الورشة (received)، جاهزة (prepared)'),
        ColumnMetadata(name: 'is_prepared', arabicName: 'هل جاهزة لبدء الشغل', type: 'BOOLEAN', description: 'علامة صح سريعة لتأكيد جاهزية الخامة'),
        ColumnMetadata(name: 'notes', arabicName: 'ملاحظات المشرف', type: 'TEXT', description: 'ملاحظات الاستلام أو الجودة'),
        ColumnMetadata(name: 'updated_at', arabicName: 'وقت آخر تحديث', type: 'TIMESTAMPTZ', description: 'الطابع الزمني للتحديث'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الجهاز'),
      ],
    ),

    'audit_logs': const TableMetadata(
      name: 'audit_logs',
      arabicName: 'سجل العمليات والرقابة الإدارية',
      description: 'سجل أمان وتدقيق إداري محمي يوثق بالثانية كل حركة إدخال أو تعديل أو حذف أو تصدير تمت على النظام من أي مستخدم أو جهاز.',
      module: 'الأمان والرقابة',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود السجل الفريد', type: 'TEXT', description: 'المعرف المرجعي للحركة'),
        ColumnMetadata(name: 'user_name', arabicName: 'اسم المستخدم المنفذ', type: 'TEXT', description: 'اسم المالك أو المدير الذي قام بالحركة'),
        ColumnMetadata(name: 'user_role', arabicName: 'رتبة المستخدم', type: 'TEXT', description: 'المالك أو مدير المصنع (owner, manager)'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز', type: 'TEXT', description: 'بصمة الموبايل أو اللابتوب المنفذ'),
        ColumnMetadata(name: 'action', arabicName: 'نوع الإجراء', type: 'TEXT', description: 'تسجيل دخول، إضافة، تعديل، حذف، تصدير CSV...'),
        ColumnMetadata(name: 'module', arabicName: 'القسم المتأثر', type: 'TEXT', description: 'العملاء، الخزينة، المخازن، الأمان، النظام...'),
        ColumnMetadata(name: 'entity_table', arabicName: 'الجدول المعني', type: 'TEXT', description: 'اسم الجدول الذي طرأ عليه التغيير'),
        ColumnMetadata(name: 'entity_id', arabicName: 'معرف السجل المتأثر', type: 'TEXT', description: 'كود الطلبية أو السند المالي المتأثر'),
        ColumnMetadata(name: 'details', arabicName: 'تفاصيل التغيير', type: 'JSONB', description: 'البيانات السابقة والجديدة المخزنة بتنسيق JSON'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت وتاريخ العملية', type: 'TIMESTAMPTZ', description: 'الطابع الزمني بالثانية للعملية'),
      ],
    ),

    'backup_records': const TableMetadata(
      name: 'backup_records',
      arabicName: 'سجلات النسخ الاحتياطي',
      description: 'جدول حماية وتتبع لكافة نقاط النسخ الاحتياطي المأخوذة للنظام محلياً وسحابياً مع بصمات التشفير SHA-256 وحالة الاستعادة.',
      module: 'الأمان والنظام',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود النسخة الفريد', type: 'TEXT', description: 'الرمز المرجعي للنسخة'),
        ColumnMetadata(name: 'filename', arabicName: 'اسم ملف النسخة', type: 'TEXT', description: 'اسم الملف المضغوط (مثل: STARS_HOMES_BACKUP_2026-11-10.zip)'),
        ColumnMetadata(name: 'backup_type', arabicName: 'نوع النسخة', type: 'TEXT', description: 'يدوي (manual)، مجدول (automatic)، وقائي قبل الاستعادة (before_restore)'),
        ColumnMetadata(name: 'storage_destination', arabicName: 'مكان التخزين', type: 'TEXT', description: 'محلي (local)، سحابي (cloud)، جوجل درايف (google_drive)'),
        ColumnMetadata(name: 'file_size', arabicName: 'حجم الملف بالبايت', type: 'BIGINT', description: 'حجم الملف الفعلي لتقدير المساحة'),
        ColumnMetadata(name: 'sha256_hash', arabicName: 'البصمة المشفرة SHA-256', type: 'TEXT', description: 'البصمة الرياضية للتحقق من عدم تلاعب أو تلف الملف عند الاستعادة'),
        ColumnMetadata(name: 'device_id', arabicName: 'معرف الجهاز المنشئ', type: 'TEXT', description: 'بصمة الجهاز الذي أخذ النسخة'),
        ColumnMetadata(name: 'created_by', arabicName: 'اسم المسؤول', type: 'TEXT', description: 'اسم من قام بإنشاء النسخة'),
        ColumnMetadata(name: 'status', arabicName: 'حالة النسخة', type: 'TEXT', description: 'مكتملة (completed)، فشلت (failed)، تم استعادتها (restored)'),
        ColumnMetadata(name: 'details', arabicName: 'بيانات وصفية JSON', type: 'JSONB', description: 'إحصائيات عدد الجداول والسجلات وإصدار التطبيق'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت أخذ النسخة', type: 'TIMESTAMPTZ', description: 'تاريخ ووقت النسخة'),
      ],
    ),

    'sync_queue': const TableMetadata(
      name: 'sync_queue',
      arabicName: 'طابور المزامنة دون اتصال',
      description: 'جدول وسيط لحفظ العمليات التي تمت في وضع عدم الاتصال (Offline) لرفعها ومزامنتها مع سيرفر Supabase فور توفر الإنترنت.',
      module: 'المزامنة والنظام',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود حركة المزامنة', type: 'TEXT', description: 'الرمز المرجعي للحركة المعلقة'),
        ColumnMetadata(name: 'table_name', arabicName: 'اسم الجدول المستهدف', type: 'TEXT', description: 'الجدول المراد تحديثه سحابياً (مثل: customer_orders)'),
        ColumnMetadata(name: 'operation', arabicName: 'نوع العملية', type: 'TEXT', description: 'إضافة (insert)، تعديل (update)، حذف (delete)'),
        ColumnMetadata(name: 'record_id', arabicName: 'كود السجل الأصلي', type: 'TEXT', description: 'معرف السجل المتأثر بالعملية'),
        ColumnMetadata(name: 'payload', arabicName: 'بيانات التعديل مشفرة', type: 'TEXT / JSON', description: 'البيانات الكاملة المطلوب كتابتها بالسيرفر السحابي'),
        ColumnMetadata(name: 'status', arabicName: 'حالة المعالجة', type: 'TEXT', description: 'معلق (pending)، جاري (in_progress)، فاشل (failed)، مكتمل (synced)'),
        ColumnMetadata(name: 'retry_count', arabicName: 'عداد إعادة المحاولة', type: 'INTEGER', description: 'عدد المحاولات عند ضعف الإنترنت'),
        ColumnMetadata(name: 'last_error', arabicName: 'رسالة آخر خطأ', type: 'TEXT', description: 'نص الخطأ إن وجد لإعلام الإدارة به في شاشة المزامنة'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت تسجيل الحركة', type: 'TIMESTAMPTZ', description: 'الطابع الزمني لإنشاء الحركة محلياً'),
      ],
    ),

    // ── AUTH SCHEMA ─────────────────────────────────────────────
    'auth.users': const TableMetadata(
      name: 'auth.users',
      arabicName: 'حسابات المستخدمين المركزية',
      description: 'جدول حسابات تسجيل الدخول للمصنع مع تشفير كلمات المرور بحماية bcrypt.',
      schema: 'auth',
      module: 'محرك المصادقة والأمان',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'المعرف الأساسي للمستخدم', type: 'UUID', description: 'المعرف الفريد لحساب المستخدم'),
        ColumnMetadata(name: 'email', arabicName: 'البريد الإلكتروني', type: 'VARCHAR', description: 'إيميل الدخول للمصنع (owner@starshomes.factory)'),
        ColumnMetadata(name: 'encrypted_password', arabicName: 'كلمة المرور المشفرة', type: 'VARCHAR', description: 'تشفير رياضي غير قابل للعكس ببروتوكول bcrypt'),
        ColumnMetadata(name: 'role', arabicName: 'دور المصادقة', type: 'VARCHAR', description: 'الدور في محرك الأمان (authenticated)'),
        ColumnMetadata(name: 'last_sign_in_at', arabicName: 'آخر تسجيل دخول ناجح', type: 'TIMESTAMPTZ', description: 'تاريخ ووقت آخر مرة فتح فيها المستخدم التطبيق'),
        ColumnMetadata(name: 'raw_user_meta_data', arabicName: 'بيانات المستخدم الوصفية', type: 'JSONB', description: 'الاسم والصفة وتوقيع المستخدم'),
        ColumnMetadata(name: 'created_at', arabicName: 'تاريخ إنشاء الحساب', type: 'TIMESTAMPTZ', description: 'وقت إنشاء الحساب'),
        ColumnMetadata(name: 'updated_at', arabicName: 'تاريخ تعديل الحساب', type: 'TIMESTAMPTZ', description: 'وقت آخر تعديل أمني'),
      ],
    ),

    'auth.sessions': const TableMetadata(
      name: 'auth.sessions',
      arabicName: 'جلسات الأجهزة النشطة',
      description: 'متابعة كافة أجهزة الموبايل واللابتوب المتصلة بالنظام حالياً مع معرف الجلسة وعنوان IP.',
      schema: 'auth',
      module: 'محرك المصادقة والأمان',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود الجلسة الفريد', type: 'UUID', description: 'معرف الجلسة الحالية على الجهاز'),
        ColumnMetadata(name: 'user_id', arabicName: 'كود المستخدم', type: 'UUID', description: 'صاحب الجلسة', relationship: 'auth.users(id)'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت فتح الجلسة', type: 'TIMESTAMPTZ', description: 'موعد تسجيل الدخول من هذا الجهاز'),
        ColumnMetadata(name: 'updated_at', arabicName: 'وقت آخر نشاط للجهاز', type: 'TIMESTAMPTZ', description: 'وقت إرسال آخر استعلام للنظام'),
        ColumnMetadata(name: 'user_agent', arabicName: 'نوع الجهاز والتطبيق', type: 'TEXT', description: 'نظام تشغيل الجهاز (Windows / Android)'),
        ColumnMetadata(name: 'ip', arabicName: 'عنوان IP المتصل', type: 'INET', description: 'عنوان اتصال الجهاز بالمصنع'),
      ],
    ),

    'auth.refresh_tokens': const TableMetadata(
      name: 'auth.refresh_tokens',
      arabicName: 'رموز تجديد الجلسات',
      description: 'توكنات الأمان المشفرة التي تسمح لتطبيق الهاتف والكمبيوتر بالبقاء متصلاً دون الحاجة لإعادة كتابة كلمة السر في كل مرة.',
      schema: 'auth',
      module: 'محرك المصادقة والأمان',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود التوكن الرقمي', type: 'BIGSERIAL', description: 'تسلسل رقمي فريد'),
        ColumnMetadata(name: 'token', arabicName: 'رمز التجديد المشفر', type: 'VARCHAR', description: 'كود التوكن المشفر المحفوظ في الجهاز بأمان'),
        ColumnMetadata(name: 'user_id', arabicName: 'كود المستخدم', type: 'VARCHAR', description: 'المستخدم صاحب الرمز'),
        ColumnMetadata(name: 'revoked', arabicName: 'هل الرمز ملغي/مسحوب', type: 'BOOLEAN', description: 'تصبح TRUE عند تسجيل الخروج أو سحب صلاحية الجهاز'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت إصدار الرمز', type: 'TIMESTAMPTZ', description: 'تاريخ التوليد'),
        ColumnMetadata(name: 'session_id', arabicName: 'كود الجلسة المرتبطة', type: 'UUID', description: 'الجلسة التابع لها هذا التوكن', relationship: 'auth.sessions(id)'),
      ],
    ),

    // ── STORAGE SCHEMA ──────────────────────────────────────────
    'storage.buckets': const TableMetadata(
      name: 'storage.buckets',
      arabicName: 'حاويات الملفات والمجلدات السحابية',
      description: 'الحاويات والمجلدات الرئيسية المخصصة لحفظ ملفات المصنع (مثل حاوية صور الطلبيات customer_orders_photos).',
      schema: 'storage',
      module: 'التخزين السحابي والصور',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'اسم الحاوية الفريد', type: 'TEXT', description: 'الكود التعريفي للمجلد'),
        ColumnMetadata(name: 'name', arabicName: 'الاسم التوضيحي للحاوية', type: 'TEXT', description: 'اسم الحاوية المعروض في لوحة التحكم'),
        ColumnMetadata(name: 'public', arabicName: 'هل الحاوية عامة', type: 'BOOLEAN', description: 'هل يمكن قراءة الصور بروابط عامة أم خاصة بمصادقة'),
        ColumnMetadata(name: 'file_size_limit', arabicName: 'الحد الأقصى لحجم الملف', type: 'BIGINT', description: 'أقصى حجم للصورة الواحدة بالبايت'),
        ColumnMetadata(name: 'allowed_mime_types', arabicName: 'الصيغ المسموح برفعها', type: 'TEXT[]', description: 'الصيغ المعتمدة (JPEG, PNG, PDF)'),
        ColumnMetadata(name: 'created_at', arabicName: 'تاريخ إنشاء الحاوية', type: 'TIMESTAMPTZ', description: 'وقت الإنشاء'),
      ],
    ),

    'storage.objects': const TableMetadata(
      name: 'storage.objects',
      arabicName: 'سجل الصور والملفات المرفوعة',
      description: 'كشف بجميع صور الأثاث، موديلات الغرف، والملفات المرفوعة مع روابطها وأحجامها وبصماتها.',
      schema: 'storage',
      module: 'التخزين السحابي والصور',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود الملف الفريد', type: 'UUID', description: 'المعرف الداخلي للملف'),
        ColumnMetadata(name: 'bucket_id', arabicName: 'كود الحاوية الحاضنة', type: 'TEXT', description: 'المجلد المخزن فيه الملف', relationship: 'storage.buckets(id)'),
        ColumnMetadata(name: 'name', arabicName: 'مسار واسم الملف', type: 'TEXT', description: 'اسم الملف على السيرفر (مثل: order_101/bedroom_master.jpg)'),
        ColumnMetadata(name: 'metadata', arabicName: 'البيانات الوصفية للملف', type: 'JSONB', description: 'نوع الملف، الحجم، أبعاد الصورة'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت رفع الملف', type: 'TIMESTAMPTZ', description: 'الطابع الزمني للرفع'),
      ],
    ),

    // ── REALTIME SCHEMA ─────────────────────────────────────────
    'realtime.subscription': const TableMetadata(
      name: 'realtime.subscription',
      arabicName: 'قنوات واشتراكات المزامنة اللحظية',
      description: 'تتبع الأجهزة المتصلة بالقنوات الفورية لتلقي التنبيهات وإشعارات الطلبيات الجديدة لحظة تسجيلها.',
      schema: 'realtime',
      module: 'البث الحي الفوري',
      columns: [
        ColumnMetadata(name: 'id', arabicName: 'كود الاشتراك التسلسلي', type: 'BIGINT', description: 'الرقم المرجعي للاشتراك'),
        ColumnMetadata(name: 'subscription_id', arabicName: 'معرف الاشتراك الفريد', type: 'UUID', description: 'كود القناة المفتوحة مع الجهاز'),
        ColumnMetadata(name: 'entity', arabicName: 'الجدول أو الكيان المراقب', type: 'REGCLASS', description: 'اسم الجدول المراقب حياً'),
        ColumnMetadata(name: 'created_at', arabicName: 'وقت فتح القناة', type: 'TIMESTAMPTZ', description: 'الطابع الزمني لبدء الاستماع'),
      ],
    ),
  };
}
