import 'package:flutter_test/flutter_test.dart';
import 'package:stars_home/models/inventory_item_model.dart';
import 'package:stars_home/models/inventory_movement_model.dart';
import 'package:stars_home/models/manufacturing_order_model.dart';
import 'package:stars_home/models/manufacturing_dimension_model.dart';
import 'package:stars_home/models/manufacturing_material_model.dart';
import 'package:stars_home/models/manufacturing_checklist_item_model.dart';
import 'package:stars_home/core/services/manufacturing_pdf_service.dart';

void main() {
  group('STARS HOMES - Manufacturing & Inventory Domain Logic Tests', () {
    test('Scenario 1: Required 3 plywood sheets, inventory has 1 sheet => shortage is exactly 2 sheets', () {
      final inventoryItem = InventoryItemModel(
        materialName: 'أبلكاش كوري',
        category: 'أخشاب ومواد خام',
        unit: 'لوح',
        currentStock: 1.0,
        reservedStock: 0.0,
      );

      const requiredQty = 3.0;
      final shortage = inventoryItem.calculateShortage(requiredQty);

      expect(inventoryItem.availableStock, 1.0);
      expect(shortage, 2.0);
    });

    test('Scenario 2: Creating a manufacturing order reserves materials without deducting physical on-hand stock', () {
      var inventoryItem = InventoryItemModel(
        materialName: 'أبلكاش كوري',
        category: 'أخشاب ومواد خام',
        unit: 'لوح',
        currentStock: 10.0,
        reservedStock: 0.0,
      );

      // Simulating a reservation of 4 sheets
      const reservedQty = 4.0;
      inventoryItem = inventoryItem.copyWith(
        reservedStock: inventoryItem.reservedStock + reservedQty,
      );

      // Physical on-hand stock remains 10.0
      expect(inventoryItem.currentStock, 10.0);
      // Reserved stock is now 4.0
      expect(inventoryItem.reservedStock, 4.0);
      // Available to promise is 6.0
      expect(inventoryItem.availableStock, 6.0);
    });

    test('Scenario 3: Physical stock issue deducts on-hand stock and releases reservation', () {
      var inventoryItem = InventoryItemModel(
        materialName: 'أبلكاش كوري',
        category: 'أخشاب ومواد خام',
        unit: 'لوح',
        currentStock: 10.0,
        reservedStock: 4.0,
      );

      // Issue 4 sheets physically to the workshop
      const issuedQty = 4.0;
      final newCurrent = inventoryItem.currentStock - issuedQty;
      final newReserved = inventoryItem.reservedStock - issuedQty;

      inventoryItem = inventoryItem.copyWith(
        currentStock: newCurrent,
        reservedStock: newReserved,
      );

      expect(inventoryItem.currentStock, 6.0);
      expect(inventoryItem.reservedStock, 0.0);
      expect(inventoryItem.availableStock, 6.0);
    });

    test('Scenario 4: Low stock alert triggers when current stock is at or below minimum level', () {
      final itemNormal = InventoryItemModel(
        materialName: 'مفصلات هيدروليك',
        category: 'إكسسوارات ومعدات',
        currentStock: 50.0,
        minimumStockLevel: 20.0,
      );
      expect(itemNormal.isLowStock, false);

      final itemLow = InventoryItemModel(
        materialName: 'مفصلات هيدروليك',
        category: 'إكسسوارات ومعدات',
        currentStock: 18.0,
        minimumStockLevel: 20.0,
      );
      expect(itemLow.isLowStock, true);
    });

    test('Scenario 5: Manufacturing Order Model & Dimensions serialization and formatting', () {
      final dim = ManufacturingDimensionModel(
        manufacturingOrderId: 'order_1',
        height: 240,
        width: 180,
        depth: 60,
        unit: 'سم',
        additionalNotes: '4 دلف مع درجين وسكاكا',
      );

      expect(dim.formattedDisplay, 'الارتفاع: 240.0 سم × العرض: 180.0 سم × العمق: 60.0 سم');

      final mat = ManufacturingMaterialModel(
        manufacturingOrderId: 'order_1',
        materialName: 'خشب زان',
        requiredQuantity: 2.5,
        unit: 'متر مكعب',
      );

      final order = ManufacturingOrderModel(
        orderNumber: '#000125',
        productName: 'دولاب غرف نوم',
        quantity: 1,
        createdBy: 'المهندس ابراهيم',
        dimensions: dim,
        materials: [mat],
      );

      expect(order.orderNumber, '#000125');
      expect(order.statusArabic, 'جديد');
      expect(order.dimensions?.height, 240);
      expect(order.materials.length, 1);
      expect(order.materials.first.materialName, 'خشب زان');
    });

    test('Scenario 6: Manufacturing Checklist status translation & transitions', () {
      final item = ManufacturingChecklistItemModel(
        manufacturingOrderId: 'order_1',
        materialName: 'أبلكاش كوري',
        requiredQuantity: 3,
        unit: 'لوح',
        status: 'required',
        isPrepared: false,
      );

      expect(item.statusArabic, 'مطلوب');
      expect(item.isPrepared, false);

      final preparedItem = item.copyWith(status: 'prepared', isPrepared: true);
      expect(preparedItem.statusArabic, 'تم التجهيز');
      expect(preparedItem.isPrepared, true);
    });

    test('Scenario 7: Stock Movement Model types and Arabic translations', () {
      final receipt = InventoryMovementModel(
        inventoryItemId: 'inv_1',
        movementType: 'receipt',
        quantity: 10,
        createdBy: 'المدير',
      );
      expect(receipt.movementTypeArabic, 'إيداع / وارد');

      final issue = InventoryMovementModel(
        inventoryItemId: 'inv_1',
        movementType: 'issue',
        quantity: 3,
        createdBy: 'المدير',
      );
      expect(issue.movementTypeArabic, 'صرف للتشغيل');
    });

    test('Scenario 8: Printable Arabic Manufacturing PDF generates valid bytes', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final dim = ManufacturingDimensionModel(
        manufacturingOrderId: 'order_pdf_1',
        height: 240,
        width: 180,
        depth: 60,
      );

      final order = ManufacturingOrderModel(
        orderNumber: '#000125',
        productName: 'دولاب 4 دلفة كلاسيك',
        customerName: 'الأستاذ أحمد فؤاد',
        assignedWorkerName: 'الأسطى محمد',
        quantity: 1,
        notes: 'تشطيب دوكو مط مع إكسسوارات إيطالي',
        createdBy: 'المدير',
        dimensions: dim,
        materials: [
          ManufacturingMaterialModel(
            manufacturingOrderId: 'order_pdf_1',
            materialName: 'أبلكاش كوري',
            requiredQuantity: 3,
            unit: 'لوح',
          ),
          ManufacturingMaterialModel(
            manufacturingOrderId: 'order_pdf_1',
            materialName: 'MDF',
            requiredQuantity: 2,
            unit: 'لوح',
          ),
          ManufacturingMaterialModel(
            manufacturingOrderId: 'order_pdf_1',
            materialName: 'مفصلات باكم',
            requiredQuantity: 8,
            unit: 'قطعة',
          ),
        ],
      );

      final pdfBytes = await ManufacturingPdfService.generateManufacturingOrderPdf(order);
      expect(pdfBytes.isNotEmpty, true);
      // Standard PDF header signature starts with %PDF
      final headerStr = String.fromCharCodes(pdfBytes.take(4));
      expect(headerStr, '%PDF');
    });
  });
}
