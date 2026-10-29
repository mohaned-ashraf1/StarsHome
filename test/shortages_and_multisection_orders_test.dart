import 'package:flutter_test/flutter_test.dart';
import 'package:stars_home/models/furniture_section_model.dart';
import 'package:stars_home/models/manufacturing_order_model.dart';
import 'package:stars_home/models/manufacturing_material_model.dart';
import 'package:stars_home/models/material_shortage_model.dart';
import 'package:stars_home/core/utils/furniture_templates.dart';
import 'package:stars_home/core/services/manufacturing_pdf_service.dart';

void main() {
  group('STARS HOMES - Multi-Section Manufacturing & Shortages Unit Tests', () {
    test('1. Multi-Section Order supports multiple furniture sections under one order', () {
      final section1 = FurnitureSectionModel(
        sectionName: 'غرفة نوم رئيسية',
        sectionType: 'غرفة نوم رئيسية',
        components: [
          FurnitureComponentModel(
            name: 'سرير كينج',
            category: 'غرفة نوم رئيسية',
            quantity: 1,
            dimensions: {'width': 180, 'length': 200, 'height': 120, 'unit': 'سم'},
            specs: {'wood_type': 'زان', 'fabric_type': 'قطيفة', 'fabric_code': 'K-40'},
          ),
          FurnitureComponentModel(
            name: 'كومودينو',
            category: 'غرفة نوم رئيسية',
            quantity: 2,
            dimensions: {'width': 50, 'depth': 45, 'height': 55, 'unit': 'سم'},
          ),
        ],
      );

      final section2 = FurnitureSectionModel(
        sectionName: 'غرفة أطفال',
        sectionType: 'غرفة أطفال',
        components: [
          FurnitureComponentModel(
            name: 'سرير أطفال فردي',
            category: 'غرفة أطفال',
            quantity: 2,
            dimensions: {'width': 120, 'length': 195, 'height': 100, 'unit': 'سم'},
          ),
          FurnitureComponentModel(
            name: 'مكتب مذاكرة',
            category: 'غرفة أطفال',
            quantity: 1,
            dimensions: {'width': 120, 'depth': 60, 'height': 75, 'unit': 'سم'},
          ),
        ],
      );

      final order = ManufacturingOrderModel(
        orderNumber: 'MO-2026-001',
        productName: 'غرفة نوم رئيسية + غرفة أطفال',
        customerName: 'الحاج كمال الشريف',
        assignedWorkerName: 'الأسطى ناصر',
        createdBy: 'المهندس ابراهيم',
        sections: [section1, section2],
        materials: [
          ManufacturingMaterialModel(
            manufacturingOrderId: 'order_test_1',
            materialName: 'أبلكاش كوري',
            requiredQuantity: 6,
            unit: 'لوح',
            thicknessGrade: '3 مم',
          ),
          ManufacturingMaterialModel(
            manufacturingOrderId: 'order_test_1',
            materialName: 'قماش قطيفة',
            requiredQuantity: 8,
            unit: 'متر',
            colorCode: 'K-40',
            linkedPiece: 'سرير كينج',
          ),
        ],
      );

      // Verify sections are preserved under the single order
      expect(order.sections.length, 2);
      expect(order.totalPiecesCount, 6); // 1 + 2 + 2 + 1 = 6 pieces
      expect(order.displayTitle, contains('غرفة نوم رئيسية'));
      expect(order.materials.length, 2);
      expect(order.materials[1].linkedPiece, 'سرير كينج');

      // Verify JSON serialization of sections
      final map = order.toMap();
      expect(map['sections_data'], isNotNull);

      // Verify round-trip deserialization
      final restored = ManufacturingOrderModel.fromMap(map);
      expect(restored.sections.length, 2);
      expect(restored.sections.first.components.length, 2);
      expect(restored.sections.first.components.first.name, 'سرير كينج');
      expect(restored.sections.first.components.first.specs['fabric_code'], 'K-40');
    });

    test('2. FurnitureTemplates generates rich default components for all major types', () {
      final masterBed = FurnitureTemplates.generateDefaultComponents('غرفة نوم رئيسية');
      expect(masterBed.any((c) => c.name.contains('سرير')), isTrue);
      expect(masterBed.any((c) => c.name.contains('كومود')), isTrue);
      expect(masterBed.any((c) => c.name.contains('تسريحة')), isTrue);
      expect(masterBed.any((c) => c.name.contains('دولاب')), isTrue);

      final kidsRoom = FurnitureTemplates.generateDefaultComponents('غرفة أطفال');
      expect(kidsRoom.any((c) => c.name.contains('سرير أطفال')), isTrue);
      expect(kidsRoom.any((c) => c.name.contains('مكتب مذاكرة')), isTrue);

      final salon = FurnitureTemplates.generateDefaultComponents('انتريه وصالون');
      expect(salon.any((c) => c.name.contains('كنبة رئيسية')), isTrue);
      expect(salon.any((c) => c.name.contains('فوتيه')), isTrue);

      final dining = FurnitureTemplates.generateDefaultComponents('سفرة');
      expect(dining.any((c) => c.name.contains('ترابيزة سفرة')), isTrue);
      expect(dining.any((c) => c.name.contains('كراسي سفرة')), isTrue);
      expect(dining.any((c) => c.name.contains('بوفيه')), isTrue);

      final kitchen = FurnitureTemplates.generateDefaultComponents('مطبخ');
      expect(kitchen.any((c) => c.name.contains('سفلية')), isTrue);
      expect(kitchen.any((c) => c.name.contains('حوض')), isTrue);
      expect(kitchen.any((c) => c.name.contains('علوية')), isTrue);

      final desk = FurnitureTemplates.generateDefaultComponents('مكتب');
      expect(desk.any((c) => c.name.contains('مكتب مذاكرة') || c.name.contains('مكتب')), isTrue);

      final custom = FurnitureTemplates.generateDefaultComponents('أثاث مخصص');
      expect(custom.length, 1);
      expect(custom.first.name, contains('تصميم خاص'));
    });

    test('3. MaterialShortageModel supports standalone shortages without order links', () {
      final standaloneShortage = MaterialShortageModel(
        materialName: 'أبلكاش كوري 3 مم',
        quantity: 5,
        unit: 'لوح',
        specifications: 'فرز أول كوري أصلي',
        recordedBy: 'الأسطى سعيد النجار',
        notes: 'الورشة متوقفة على الأبلكاش',
      );

      expect(standaloneShortage.status, 'shortage');
      expect(standaloneShortage.isActive, isTrue);
      expect(standaloneShortage.isResolved, isFalse);
      expect(standaloneShortage.manufacturingOrderId, isNull);
      expect(standaloneShortage.statusArabic, 'ناقص');

      // Test status transitions
      final inProgress = standaloneShortage.copyWith(status: 'in_progress');
      expect(inProgress.isActive, isTrue);
      expect(inProgress.statusArabic, 'جارٍ المتابعة');

      final resolved = standaloneShortage.copyWith(
        status: 'resolved',
        resolvedBy: 'صاحب المصنع',
        resolvedAt: DateTime.now(),
      );
      expect(resolved.isActive, isFalse);
      expect(resolved.isResolved, isTrue);
      expect(resolved.status, 'resolved');
      expect(resolved.statusArabic, 'تم الحل');
      expect(resolved.resolvedBy, 'صاحب المصنع');
      expect(resolved.resolvedAt, isNotNull);

      // Test reopen
      final reopened = resolved.copyWith(
        status: 'reopened',
        notes: '${resolved.notes ?? ""}\n[أعيد فتح النقص بواسطة مدير الإنتاج]',
        resolvedBy: null,
        resolvedAt: null,
      );
      expect(reopened.isActive, isTrue);
      expect(reopened.isResolved, isFalse);
      expect(reopened.status, 'reopened');
      expect(reopened.statusArabic, 'أعيد فتحه');
      expect(reopened.notes, contains('أعيد فتح النقص بواسطة مدير الإنتاج'));
    });

    test('4. MaterialShortageModel supports optional manufacturing order link and optional quantity', () {
      final linkedShortage = MaterialShortageModel(
        materialName: 'مفصلات باكم سوفت كلوز',
        unit: 'قطعة', // Quantity is omitted/null
        manufacturingOrderId: 'order_123',
        manufacturingOrderNumber: 'MO-2026-001',
        recordedBy: 'الفني أحمد',
      );

      expect(linkedShortage.quantity, isNull);
      expect(linkedShortage.manufacturingOrderId, 'order_123');
      expect(linkedShortage.manufacturingOrderNumber, 'MO-2026-001');

      // Test SQLite map round-trip
      final map = linkedShortage.toMap();
      final restored = MaterialShortageModel.fromMap(map);
      expect(restored.materialName, 'مفصلات باكم سوفت كلوز');
      expect(restored.manufacturingOrderId, 'order_123');
      expect(restored.manufacturingOrderNumber, 'MO-2026-001');
      expect(restored.quantity, isNull);
    });

    test('5. MultiPage PDF with Multi-Section furniture & manual materials generation', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final sectionBed = FurnitureSectionModel(
        sectionName: 'غرفة نوم رئيسية',
        sectionType: 'غرفة نوم رئيسية',
        components: [
          FurnitureComponentModel(
            name: 'سرير كينج 180×200',
            category: 'غرفة نوم',
            quantity: 1,
            dimensions: {'width': 180, 'length': 200, 'height': 120, 'unit': 'سم'},
            specs: {'wood_type': 'زان روماني', 'finish': 'دوكو أبيض مط'},
          ),
          FurnitureComponentModel(
            name: 'دولاب 3 دلف جرار',
            category: 'غرفة نوم',
            quantity: 1,
            dimensions: {'width': 260, 'depth': 65, 'height': 240, 'unit': 'سم'},
            specs: {'door_type': 'جرار تركي', 'doors_count': 3, 'shelves_count': 6},
          ),
        ],
      );

      final sectionKitchen = FurnitureSectionModel(
        sectionName: 'مطبخ مودرن',
        sectionType: 'مطبخ',
        components: [
          FurnitureComponentModel(
            name: 'وحدات سفلية',
            category: 'مطبخ',
            quantity: 3,
            dimensions: {'width': 280, 'depth': 60, 'height': 90, 'unit': 'سم'},
            specs: {'wood_type': 'HPL مقاوم للرطوبة', 'drawers_count': 6},
          ),
        ],
      );

      final order = ManufacturingOrderModel(
        orderNumber: 'MO-2026-999',
        productName: 'غرفة نوم رئيسية + مطبخ مودرن',
        customerName: 'المهندس كريم عبد العزيز',
        assignedWorkerName: 'الأسطى ناصر',
        createdBy: 'المدير',
        notes: 'مطلوب الالتزام بالأبعاد بدقة والتشطيب عالي الجودة',
        sections: [sectionBed, sectionKitchen],
        materials: [
          ManufacturingMaterialModel(
            manufacturingOrderId: 'order_pdf_1',
            materialName: 'أبلكاش كوري',
            requiredQuantity: 10,
            unit: 'لوح',
            thicknessGrade: '3 مم',
          ),
          ManufacturingMaterialModel(
            manufacturingOrderId: 'order_pdf_1',
            materialName: 'ألواح HPL',
            requiredQuantity: 4,
            unit: 'لوح',
            thicknessGrade: '18 مم',
            linkedPiece: 'وحدات مطبخ سفلية',
          ),
          ManufacturingMaterialModel(
            manufacturingOrderId: 'order_pdf_1',
            materialName: 'مفصلات باكم سوفت كلوز',
            requiredQuantity: 24,
            unit: 'قطعة',
          ),
        ],
      );

      final pdfBytes = await ManufacturingPdfService.generateManufacturingOrderPdf(order);
      expect(pdfBytes.isNotEmpty, true);
      // Valid PDF format header check
      final header = String.fromCharCodes(pdfBytes.take(4));
      expect(header, '%PDF');
    });
  });
}
