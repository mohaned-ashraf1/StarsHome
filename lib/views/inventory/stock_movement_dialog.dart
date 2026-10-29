import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/auth_provider.dart';

class StockMovementDialog extends StatefulWidget {
  final InventoryItemModel item;
  final String initialMovementType; // receipt, issue, adjustment

  const StockMovementDialog({
    super.key,
    required this.item,
    this.initialMovementType = 'receipt',
  });

  @override
  State<StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<StockMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _movementType;
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _movementType = widget.initialMovementType;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String get _movementTitle {
    switch (_movementType) {
      case 'receipt':
        return 'إيداع وارد مخزن (+ رصيد)';
      case 'issue':
        return 'صرف خامات للتشغيل (- رصيد)';
      case 'adjustment':
        return 'تسوية جرد يدوي (= رصيد جديد)';
      case 'return':
        return 'إرجاع خامات للمخزن (+ رصيد)';
      default:
        return 'حركة مخزن';
    }
  }

  Color get _movementColor {
    switch (_movementType) {
      case 'receipt':
      case 'return':
        return AppColors.incomeGreen;
      case 'issue':
        return AppColors.warningAmber;
      case 'adjustment':
        return AppColors.infoBlue;
      default:
        return AppColors.accentGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Row(
        children: [
          Icon(Icons.swap_horiz_rounded, color: _movementColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item.materialName,
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _movementTitle,
                  style: TextStyle(color: _movementColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current stock banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardNavy,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الرصيد الفعلي حالياً: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text(
                      '${widget.item.currentStock} ${widget.item.unit}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _movementType,
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: const InputDecoration(labelText: 'نوع الحركة', isDense: true),
                items: const [
                  DropdownMenuItem(value: 'receipt', child: Text('وارد / استلام بضاعة (+)')),
                  DropdownMenuItem(value: 'issue', child: Text('صرف لخط الإنتاج (-)')),
                  DropdownMenuItem(value: 'adjustment', child: Text('تسوية جرد فعلي (=)')),
                  DropdownMenuItem(value: 'return', child: Text('مرتجع خامات (+)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _movementType = val);
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textWhite),
                decoration: InputDecoration(
                  labelText: _movementType == 'adjustment' ? 'الرصيد الفعلي الجديد بعد الجرد *' : 'الكمية المطلوبة (${widget.item.unit}) *',
                  isDense: true,
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0) return 'أدخل كمية صحيحة';
                  if (_movementType == 'issue' && n > widget.item.currentStock) {
                    return 'الكمية المصروفة تتجاوز الرصيد المتوفر (${widget.item.currentStock})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _reasonController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: const InputDecoration(
                  labelText: 'السبب / رقم الفاتورة أو أمر التشغيل',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _movementColor),
          child: Text('تنفيذ الحركة', style: const TextStyle(color: AppColors.backgroundDark, fontWeight: FontWeight.bold)),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final auth = Provider.of<AuthProvider>(context, listen: false);
            final invProvider = Provider.of<InventoryProvider>(context, listen: false);
            final qty = double.tryParse(_qtyController.text) ?? 0.0;

            await invProvider.recordMovement(
              inventoryItemId: widget.item.id,
              movementType: _movementType,
              quantity: qty,
              referenceType: 'manual_adjustment',
              reasonNotes: _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
              createdBy: auth.currentUser?.fullName ?? 'المدير',
            );

            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
