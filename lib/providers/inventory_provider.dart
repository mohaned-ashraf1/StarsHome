import 'package:flutter/material.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_movement_model.dart';
import '../core/services/inventory_service.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryService _inventoryService = InventoryService.instance;

  List<InventoryItemModel> _items = [];
  List<InventoryMovementModel> _movements = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  InventoryProvider() {
    loadAll();
  }

  List<InventoryItemModel> get items => _items;
  List<InventoryMovementModel> get movements => _movements;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<InventoryItemModel> get filteredItems {
    return _items.where((item) {
      final matchesCategory = _selectedCategory == 'الكل' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.materialName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<InventoryItemModel> get lowStockItems {
    return _items.where((item) => item.isLowStock).toList();
  }

  int get lowStockCount => lowStockItems.length;

  List<String> get availableCategories {
    final set = {'الكل'};
    for (var it in _items) {
      set.add(it.category);
    }
    return set.toList();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _inventoryService.getAllItems();
      _movements = await _inventoryService.getAllMovements(limit: 50);
    } catch (e) {
      debugPrint('Error loading inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> saveItem(InventoryItemModel item) async {
    await _inventoryService.saveItem(item);
    await loadAll();
  }

  Future<void> deleteItem(String id) async {
    await _inventoryService.deleteItem(id);
    await loadAll();
  }

  Future<void> recordMovement({
    required String inventoryItemId,
    required String movementType,
    required double quantity,
    String? referenceType,
    String? referenceId,
    String? reasonNotes,
    required String createdBy,
  }) async {
    await _inventoryService.recordMovement(
      inventoryItemId: inventoryItemId,
      movementType: movementType,
      quantity: quantity,
      referenceType: referenceType,
      referenceId: referenceId,
      reasonNotes: reasonNotes,
      createdBy: createdBy,
    );
    await loadAll();
  }

  // Calculate stock availability and shortage for a given material
  Map<String, double> getStockAnalysis(String materialName, double requiredQty) {
    final normalized = materialName.trim().toLowerCase();
    InventoryItemModel? match;
    for (var item in _items) {
      if (item.materialName.trim().toLowerCase() == normalized) {
        match = item;
        break;
      }
    }

    if (match == null) {
      // Not in inventory => full amount is shortage
      return {
        'available': 0.0,
        'onHand': 0.0,
        'reserved': 0.0,
        'shortage': requiredQty,
      };
    }

    final available = match.availableStock;
    final shortage = match.calculateShortage(requiredQty);
    return {
      'available': available,
      'onHand': match.currentStock,
      'reserved': match.reservedStock,
      'shortage': shortage,
    };
  }
}
