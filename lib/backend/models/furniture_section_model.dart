import 'package:uuid/uuid.dart';

/// Represents an individual furniture item/piece inside a section
/// (e.g. Bed, Wardrobe, Commode, Dresser, Kitchen Base Unit, Sofa 3-seater, Dining Table, Desk, Custom piece...)
class FurnitureComponentModel {
  final String id;
  final String name; // e.g. 'سرير', 'دولاب 3 دلف جرار', 'كومود', 'تسريحة مع مراية', 'كنبة 3 مقاعد', etc.
  final String category; // e.g. 'غرف نوم رئيسية', 'غرف أطفال', 'انتريه وصالون', 'سفرة', 'مطبخ', 'مكتب', etc.
  final int quantity; // Number of units (e.g. 2 commodes, 6 dining chairs)
  final Map<String, dynamic> dimensions; // Height, width, depth, headboard, base, etc.
  final Map<String, dynamic> specs; // Materials, thickness, upholstery, fabric & code, finish, hinges, accessories
  final String? notes;

  FurnitureComponentModel({
    String? id,
    required this.name,
    required this.category,
    this.quantity = 1,
    Map<String, dynamic>? dimensions,
    Map<String, dynamic>? specs,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        dimensions = dimensions ?? {},
        specs = specs ?? {};

  String get dimensionsSummary {
    final parts = <String>[];
    final h = dimensions['height'];
    final w = dimensions['width'];
    final d = dimensions['depth'];
    final u = dimensions['unit'] ?? 'سم';

    if (h != null && h.toString().isNotEmpty) parts.add('ع: $h$u');
    if (w != null && w.toString().isNotEmpty) parts.add('ط/عرض: $w$u');
    if (d != null && d.toString().isNotEmpty) parts.add('عمق: $d$u');

    if (dimensions['headboard'] != null && dimensions['headboard'].toString().isNotEmpty) {
      parts.add('ظهر: ${dimensions['headboard']}');
    }

    return parts.isEmpty ? 'المقاسات حسب المعاينة' : parts.join(' × ');
  }

  String get specsSummary {
    final parts = <String>[];
    if (specs['wood_type'] != null && specs['wood_type'].toString().isNotEmpty) {
      parts.add('الخشب: ${specs['wood_type']}');
    }
    if (specs['thickness'] != null && specs['thickness'].toString().isNotEmpty) {
      parts.add('السمك: ${specs['thickness']}');
    }
    if (specs['fabric_type'] != null && specs['fabric_type'].toString().isNotEmpty) {
      parts.add('القماش: ${specs['fabric_type']}${specs['fabric_code'] != null ? " (${specs['fabric_code']})" : ""}');
    }
    if (specs['finish'] != null && specs['finish'].toString().isNotEmpty) {
      parts.add('التشطيب: ${specs['finish']}');
    }
    if (specs['doors_count'] != null && specs['doors_count'].toString().isNotEmpty) {
      parts.add('${specs['doors_count']} دلفة (${specs['door_type'] ?? "مفصلي"})');
    }
    if (specs['drawers_count'] != null && specs['drawers_count'].toString().isNotEmpty) {
      parts.add('${specs['drawers_count']} درج');
    }
    return parts.join(' • ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'dimensions': dimensions,
      'specs': specs,
      'notes': notes,
    };
  }

  factory FurnitureComponentModel.fromMap(Map<String, dynamic> map) {
    return FurnitureComponentModel(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'عام',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      dimensions: map['dimensions'] is Map
          ? Map<String, dynamic>.from(map['dimensions'] as Map)
          : {},
      specs: map['specs'] is Map
          ? Map<String, dynamic>.from(map['specs'] as Map)
          : {},
      notes: map['notes']?.toString(),
    );
  }

  FurnitureComponentModel copyWith({
    String? name,
    String? category,
    int? quantity,
    Map<String, dynamic>? dimensions,
    Map<String, dynamic>? specs,
    String? notes,
  }) {
    return FurnitureComponentModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      dimensions: dimensions ?? Map<String, dynamic>.from(this.dimensions),
      specs: specs ?? Map<String, dynamic>.from(this.specs),
      notes: notes ?? this.notes,
    );
  }
}

/// Represents a distinct section within a single manufacturing order
/// (e.g. Master Bedroom, Kids Bedroom, Living Room, Kitchen, Office...)
class FurnitureSectionModel {
  final String id;
  final String sectionType; // Type key, e.g. 'غرفة نوم رئيسية', 'مطبخ', 'سفرة'...
  final String sectionName; // Display name
  final List<FurnitureComponentModel> components;
  final String? notes;

  FurnitureSectionModel({
    String? id,
    required this.sectionType,
    required this.sectionName,
    List<FurnitureComponentModel>? components,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        components = components ?? [];

  int get totalPiecesCount => components.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'section_type': sectionType,
      'section_name': sectionName,
      'components': components.map((c) => c.toMap()).toList(),
      'notes': notes,
    };
  }

  factory FurnitureSectionModel.fromMap(Map<String, dynamic> map) {
    final compsRaw = map['components'] as List? ?? [];
    final comps = compsRaw
        .map((c) => FurnitureComponentModel.fromMap(Map<String, dynamic>.from(c as Map)))
        .toList();

    return FurnitureSectionModel(
      id: map['id']?.toString(),
      sectionType: map['section_type']?.toString() ?? 'أثاث مخصص',
      sectionName: map['section_name']?.toString() ?? 'قسم أثاث',
      components: comps,
      notes: map['notes']?.toString(),
    );
  }

  FurnitureSectionModel copyWith({
    String? sectionType,
    String? sectionName,
    List<FurnitureComponentModel>? components,
    String? notes,
  }) {
    return FurnitureSectionModel(
      id: id,
      sectionType: sectionType ?? this.sectionType,
      sectionName: sectionName ?? this.sectionName,
      components: components ?? List<FurnitureComponentModel>.from(this.components),
      notes: notes ?? this.notes,
    );
  }
}
