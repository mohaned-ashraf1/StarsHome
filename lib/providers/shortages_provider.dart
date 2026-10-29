import 'package:flutter/material.dart';
import '../models/material_shortage_model.dart';
import '../core/services/shortages_service.dart';

class ShortagesProvider with ChangeNotifier {
  final ShortagesService _service = ShortagesService.instance;

  List<MaterialShortageModel> _shortages = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedStatusFilter = 'الكل'; // 'الكل', 'ناقص', 'جارٍ المتابعة', 'تم الحل', 'أعيد فتحه'

  List<MaterialShortageModel> get shortages => _shortages;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedStatusFilter => _selectedStatusFilter;

  int get activeCount => _shortages.where((s) => s.isActive).length;
  int get resolvedCount => _shortages.where((s) => s.isResolved).length;

  List<MaterialShortageModel> get filteredShortages {
    return _shortages.where((item) {
      // 1. Status Filter
      bool matchesStatus = true;
      if (_selectedStatusFilter == 'ناقص') {
        matchesStatus = item.status == 'shortage';
      } else if (_selectedStatusFilter == 'جارٍ المتابعة') {
        matchesStatus = item.status == 'in_progress';
      } else if (_selectedStatusFilter == 'تم الحل') {
        matchesStatus = item.status == 'resolved';
      } else if (_selectedStatusFilter == 'أعيد فتحه') {
        matchesStatus = item.status == 'reopened';
      } else if (_selectedStatusFilter == 'النشطة فقط') {
        matchesStatus = item.isActive;
      }

      // 2. Search Query Filter
      bool matchesSearch = true;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        matchesSearch = item.materialName.toLowerCase().contains(q) ||
            (item.specifications != null && item.specifications!.toLowerCase().contains(q)) ||
            (item.notes != null && item.notes!.toLowerCase().contains(q)) ||
            (item.manufacturingOrderNumber != null && item.manufacturingOrderNumber!.toLowerCase().contains(q)) ||
            item.recordedBy.toLowerCase().contains(q);
      }

      return matchesStatus && matchesSearch;
    }).toList();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _shortages = await _service.getAllShortages();
    } catch (e) {
      debugPrint('Error loading shortages in provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _selectedStatusFilter = filter;
    notifyListeners();
  }

  Future<void> addShortage(MaterialShortageModel shortage) async {
    await _service.addShortage(shortage);
    await loadAll();
  }

  Future<void> updateShortage(MaterialShortageModel shortage) async {
    await _service.updateShortage(shortage);
    await loadAll();
  }

  Future<void> resolveShortage({
    required String shortageId,
    required String resolvedBy,
  }) async {
    await _service.resolveShortage(shortageId: shortageId, resolvedBy: resolvedBy);
    await loadAll();
  }

  Future<void> reopenShortage(String shortageId) async {
    await _service.reopenShortage(shortageId: shortageId);
    await loadAll();
  }

  Future<void> deleteShortage(String id) async {
    await _service.deleteShortage(id);
    await loadAll();
  }
}
