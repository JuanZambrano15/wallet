// lib/screens/add_expense_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';

class AddExpenseScreen extends StatefulWidget {
  /// Si se pasa un [expense], el formulario entra en modo edición.
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ExpenseService();

  // Controladores
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _newCatCtrl = TextEditingController();

  // Estado del formulario
  ExpenseType _type = ExpenseType.variable;
  String? _selectedCategoryId;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  bool _saving = false;
  bool _loadingCategories = true;

  List<ExpenseCategory> _categories = [];

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (_isEditing) _populateFields();
  }

  void _populateFields() {
    final e = widget.expense!;
    _nameCtrl.text = e.name;
    _amountCtrl.text = e.amount.toStringAsFixed(0);
    _descCtrl.text = e.description;
    _type = e.type;
    _date = e.date;
    _dueDate = e.dueDate;
    _selectedCategoryId = e.categoryId;
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _service.getCategoriesByUser();
      if (mounted) {
        setState(() {
          _categories = cats;
          // Seleccionar la primera categoría por defecto si no hay una ya seleccionada
          if (_selectedCategoryId == null && cats.isNotEmpty) {
            _selectedCategoryId = cats.first.id;
          }
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _pickDate({bool isDueDate = false}) async {
    final initial = isDueDate ? (_dueDate ?? DateTime.now()) : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.accent,
            surface: AppColors.surface2,
            onSurface: AppColors.accent,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isDueDate) {
        _dueDate = picked;
      } else {
        _date = picked;
      }
    });
  }

  Future<void> _showAddCategoryDialog() async {
    _newCatCtrl.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nueva categoría', style: TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: _newCatCtrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.accent),
          decoration: const InputDecoration(hintText: 'Nombre de la categoría'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final name = _newCatCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final newCat = await _service.addCustomCategory(name);
                if (mounted) {
                  setState(() {
                    _categories.add(newCat);
                    _selectedCategoryId = newCat.id;
                  });
                }
              } catch (e) {
                _showSnack('Error al crear la categoría');
              }
            },
            child: const Text('Agregar', style: TextStyle(color: AppColors.tealAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showSnack('Selecciona una categoría');
      return;
    }

    setState(() => _saving = true);
    try {
      final amount = double.parse(_amountCtrl.text.trim());

      if (_isEditing) {
        await _service.updateExpense(
          id: widget.expense!.id,
          amount: amount,
          date: _date,
          type: _type,
          categoryId: _selectedCategoryId!,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          dueDate: _type == ExpenseType.fixed ? _dueDate : null,
        );
      } else {
        await _service.addExpense(
          amount: amount,
          date: _date,
          type: _type,
          categoryId: _selectedCategoryId!,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          dueDate: _type == ExpenseType.fixed ? _dueDate : null,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Error al guardar el gasto');
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar gasto', style: TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este gasto? Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.accentDim, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.deleteExpense(widget.expense!.id);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        _showSnack('Error al eliminar el gasto');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _newCatCtrl.dispose();
    super.dispose();
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.accentDim),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Editar gasto' : 'Nuevo gasto',
          style: const TextStyle(fontSize: 16, color: AppColors.accent, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.redAccent, size: 22),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Tipo de gasto ──────────────────────────────────────
                    _sectionLabel('Tipo de gasto'),
                    const SizedBox(height: 10),
                    _buildTypeToggle(),
                    const SizedBox(height: 24),

                    // ── Nombre ─────────────────────────────────────────────
                    _sectionLabel('Nombre *'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: AppColors.accent, fontSize: 14),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Ej. Netflix, Arriendo...',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Monto ──────────────────────────────────────────────
                    _sectionLabel('Monto *'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _amountCtrl,
                      style: const TextStyle(color: AppColors.accent, fontSize: 14),
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        hintText: '0',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'El monto es obligatorio';
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Ingresa un monto válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Categoría (solo variable) ──────────────────────────
                    if (_type == ExpenseType.variable) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionLabel('Categoría *'),
                          GestureDetector(
                            onTap: _showAddCategoryDialog,
                            child: const Row(
                              children: [
                                Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.tealAccent),
                                SizedBox(width: 4),
                                Text('Nueva', style: TextStyle(fontSize: 11, color: AppColors.tealAccent, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildCategoryGrid(),
                      const SizedBox(height: 20),
                    ],

                    // ── Fecha del gasto ────────────────────────────────────
                    _sectionLabel('Fecha del gasto'),
                    const SizedBox(height: 10),
                    _buildDateTile(
                      label: DateFormat('dd MMM yyyy', 'es').format(_date),
                      icon: Icons.calendar_today_rounded,
                      onTap: () => _pickDate(),
                    ),
                    const SizedBox(height: 20),

                    // ── Fecha límite (solo fijo) ───────────────────────────
                    if (_type == ExpenseType.fixed) ...[
                      _sectionLabel('Fecha límite de pago'),
                      const SizedBox(height: 10),
                      _buildDateTile(
                        label: _dueDate != null
                            ? DateFormat('dd MMM yyyy', 'es').format(_dueDate!)
                            : 'Seleccionar fecha',
                        icon: Icons.event_busy_rounded,
                        onTap: () => _pickDate(isDueDate: true),
                        muted: _dueDate == null,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Descripción ────────────────────────────────────────
                    _sectionLabel('Descripción (opcional)'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descCtrl,
                      style: const TextStyle(color: AppColors.accent, fontSize: 14),
                      maxLines: 3,
                      maxLength: 200,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Agrega una nota...',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.notes_rounded),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Botón guardar ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                              )
                            : Text(_isEditing ? 'Guardar cambios' : 'Registrar gasto'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Helpers de UI ────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Text(label.toUpperCase(),
        style: const TextStyle(fontSize: 10, letterSpacing: 1.2, color: AppColors.accentMuted, fontWeight: FontWeight.w600));
  }

  Widget _buildTypeToggle() {
    return Row(
      children: [
        _typeChip(ExpenseType.variable, 'Variable', Icons.show_chart_rounded),
        const SizedBox(width: 10),
        _typeChip(ExpenseType.fixed, 'Fijo', Icons.repeat_rounded),
      ],
    );
  }

  Widget _typeChip(ExpenseType type, String label, IconData icon) {
    final active = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          // Limpiar categoría si cambia a fijo (usa 'fixed' como id neutral)
          if (type == ExpenseType.fixed) {
            _selectedCategoryId = 'fixed';
          } else {
            _selectedCategoryId = _categories.isNotEmpty ? _categories.first.id : null;
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? AppColors.tealAccent : AppColors.accentDim),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.accent : AppColors.accentDim,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._categories.map((cat) {
          final active = _selectedCategoryId == cat.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryId = cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? AppColors.primary : AppColors.border2),
              ),
              child: Text(
                cat.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active ? AppColors.accent : AppColors.accentDim,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDateTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool muted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.gray),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: muted ? AppColors.accentMuted : AppColors.accent,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.accentMuted),
          ],
        ),
      ),
    );
  }
}
