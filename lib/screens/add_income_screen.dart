// lib/screens/add_income_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/sourceIncome.dart';
import '../services/income_service.dart';
import '../utils/app_theme.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen>
    with SingleTickerProviderStateMixin {
  // ─── Form ──────────────────────────────────────────────────────────────────
  final _formKey          = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController   = TextEditingController();

  DateTime _selectedDate   = DateTime.now();
  SourceIncome? _selectedSource;
  List<SourceIncome> _sources = [];

  bool _isLoadingSources = true;
  bool _isSaving         = false;

  final _service = IncomeService();

  // ─── Animación de entrada ──────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
    _loadSources();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ─── Carga de fuentes ──────────────────────────────────────────────────────
  Future<void> _loadSources() async {
    try {
      final sources = await _service.getSourceIncomesByUser();
      if (mounted) {
        setState(() {
          _sources        = sources;
          _selectedSource = sources.length == 1 ? sources.first : null;
          _isLoadingSources = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSources = false);
    }
  }

  // ─── DatePicker ────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary:   AppColors.primary,
            onPrimary: AppColors.accent,
            surface:   AppColors.surface2,
            onSurface: AppColors.accent,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.tealAccent),
          ),
          dialogBackgroundColor: AppColors.surface2,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ─── Guardar ───────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSource == null) {
      _snack('Selecciona una fuente de ingreso.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.addIncome(
        amount:      double.parse(_amountController.text.replaceAll(',', '.')),
        date:        _selectedDate,
        sourceId:    _selectedSource!.id,
        description: _descController.text.trim(),
      );
      if (mounted) {
        _snack('¡Ingreso registrado!', success: true);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) _snack('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.primary : AppColors.error,
      ),
    );
  }

  // ─── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAmountField(),
                          const SizedBox(height: 12),
                          _buildDateField(),
                          const SizedBox(height: 12),
                          _buildSourceField(),
                          const SizedBox(height: 12),
                          _buildDescField(),
                          const SizedBox(height: 32),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      child: Row(
        children: [
          // Botón volver — estilo idéntico al home
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.accentDim,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NUEVO INGRESO',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: AppColors.accentMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat("d 'de' MMMM, yyyy", 'es').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Monto ─────────────────────────────────────────────────────
  Widget _buildAmountField() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('MONTO', required: true),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '\$',
                style: TextStyle(
                  fontSize: 28,
                  color: AppColors.tealAccent,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
                  ],
                  style: const TextStyle(
                    fontSize: 32,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    // Sobreescribe el tema global para que no haya borde en este campo
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    errorStyle: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'El monto es obligatorio.';
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null) return 'Ingresa un número válido.';
                    if (n <= 0)   return 'Debe ser mayor a cero.';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Fecha ─────────────────────────────────────────────────────
  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: _Card(
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 17,
                color: AppColors.tealAccent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('FECHA', required: true),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat("d 'de' MMMM, yyyy", 'es').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.accentMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Fuente de ingreso ─────────────────────────────────────────
  Widget _buildSourceField() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('FUENTE DE INGRESO', required: true),
          const SizedBox(height: 10),
          if (_isLoadingSources)
            Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.tealAccent,
                ),
              ),
            )
          else
            DropdownButtonFormField<SourceIncome>(
              value: _selectedSource,
              dropdownColor: AppColors.surface2,
              iconEnabledColor: AppColors.tealAccent,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                errorStyle: TextStyle(color: AppColors.error, fontSize: 11),
              ),
              hint: const Text(
                'Selecciona una fuente',
                style: TextStyle(color: AppColors.accentMuted, fontSize: 14),
              ),
              items: _sources.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.name),
              )).toList(),
              onChanged: (v) => setState(() => _selectedSource = v),
              validator: (v) =>
                  v == null ? 'Selecciona una fuente.' : null,
            ),
        ],
      ),
    );
  }

  // ── Descripción ───────────────────────────────────────────────
  Widget _buildDescField() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('DESCRIPCIÓN', required: false),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descController,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              hintText: 'Ej: Pago de nómina, proyecto freelance...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón guardar ─────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        // ElevatedButtonTheme ya está configurado en AppTheme.dark()
        // — color primary, texto accent, radius 12, sin elevación
        onPressed: _isSaving ? null : _save,
        child: _isSaving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.accent,
                ),
              )
            : const Text('Registrar ingreso'),
      ),
    );
  }
}

// ─── Widgets de apoyo ─────────────────────────────────────────────────────────

/// Card contenedor — mismo color/borde que los cards del HomeScreen
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Etiqueta de campo — estilo idéntico a _buildSectionLabel() del HomeScreen
class _Label extends StatelessWidget {
  final String text;
  final bool required;
  const _Label(this.text, {required this.required});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            color: AppColors.accentMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          const Text(
            '•',
            style: TextStyle(
              color: AppColors.tealAccent,
              fontSize: 14,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}