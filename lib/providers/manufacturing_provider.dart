import 'package:flutter/material.dart';
import '../models/manufacturing_order_model.dart';
import '../models/manufacturing_dimension_model.dart';
import '../models/manufacturing_material_model.dart';
import '../core/services/manufacturing_service.dart';

class ManufacturingProvider with ChangeNotifier {
  final ManufacturingService _manufacturingService = ManufacturingService.instance;

  List<ManufacturingOrderModel> _orders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedStatus = 'الكل';

  List<ManufacturingOrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedStatus => _selectedStatus;

  List<ManufacturingOrderModel> get filteredOrders {
    return _orders.where((order) {
      final matchesStatus = _selectedStatus == 'الكل' || order.status == _selectedStatus;
      final matchesSearch = _searchQuery.isEmpty ||
          order.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (order.customerName != null && order.customerName!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (order.assignedWorkerName != null && order.assignedWorkerName!.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesStatus && matchesSearch;
    }).toList();
  }

  int get openOrdersCount {
    return _orders.where((o) => o.status != 'completed' && o.status != 'cancelled').length;
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await _manufacturingService.getAllOrders();
    } catch (e) {
      debugPrint('Error loading manufacturing orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  Future<String> getNextOrderNumber() async {
    return await _manufacturingService.generateNextOrderNumber();
  }

  Future<ManufacturingOrderModel> createOrder({
    required ManufacturingOrderModel order,
    ManufacturingDimensionModel? dimensions,
    required List<ManufacturingMaterialModel> materials,
    bool autoReserveStock = true,
  }) async {
    final created = await _manufacturingService.createOrder(
      order: order,
      dimensions: dimensions,
      materials: materials,
      autoReserveStock: autoReserveStock,
    );
    await loadAll();
    return created;
  }

  Future<void> updateChecklistStatus({
    required String checklistId,
    required String newStatus,
    required bool isPrepared,
  }) async {
    await _manufacturingService.updateChecklistItem(
      checklistId: checklistId,
      newStatus: newStatus,
      isPrepared: isPrepared,
    );
    await loadAll();
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    await _manufacturingService.updateOrderStatus(orderId: orderId, newStatus: newStatus);
    await loadAll();
  }

  Future<void> issueMaterialsToWorkshop({
    required String orderId,
    required String createdBy,
  }) async {
    await _manufacturingService.issueMaterialsToWorkshop(orderId: orderId, createdBy: createdBy);
    await loadAll();
  }

  Future<void> deleteOrder(String orderId) async {
    await _manufacturingService.deleteOrder(orderId);
    await loadAll();
  }
}
