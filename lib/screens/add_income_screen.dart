// lib/screens/add_income_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/income_model.dart';
import '../services/income_service.dart';
import '../utils/app_theme.dart'; // Contains AppColors

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen>
    with SingleTickerProviderStateMixin {
  // ─── State ──────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  IncomeSource? _selectedSource;

  List<IncomeSource> _sources = [];
  bool _isLoadingSources = true;
  bool _isSaving = false;

  final IncomeService _incomeService = IncomeService();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _loadSources();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ─── Data Loading ─────────────────────────────────────────────────────────
  Future<void> _loadSources() async {
    try {
      final sources = await _incomeService.fetchIncomeSources();
      if (mounted) {
        setState(() {
          _sources = sources;
          // CA3: Default to "General" if only one source (or none).
          _selectedSource =
              sources.length == 1 ? sources.first : null;
          _isLoadingSources = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sources = [IncomeSource.general];
          _selectedSource = IncomeSource.general;
          _isLoadingSources = false;
        });
      }
    }
  }

  // ─── Interactions ─────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: AppColors.background,
              surface: AppColors.surface,
              onSurface: AppColors.primary,
            ),
            dialogBackgroundColor: AppColors.background,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSource == null) {
      _showSnackbar('Por favor selecciona una fuente de ingreso.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final income = Income(
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        date: _selectedDate,
        sourceId: _selectedSource!.id,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      await _incomeService.addIncome(income);

      if (mounted) {
        _showSnackbar('¡Ingreso registrado exitosamente!', isSuccess: true);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error al guardar: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor:
            isSuccess ? AppColors.accent : Colors.redAccent.shade200,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAmountField(),
                          const SizedBox(height: 16),
                          _buildDateField(),
                          const SizedBox(height: 16),
                          _buildSourceDropdown(),
                          const SizedBox(height: 16),
                          _buildDescriptionField(),
                          const SizedBox(height: 36),
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

  // ─── AppBar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      child: Row(
        children: [
          _MinimalBackButton(onPressed: () => Navigator.of(context).pop()),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuevo Ingreso',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now()),
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Amount Field ──────────────────────────────────────────────────────────
  Widget _buildAmountField() {
    return _FieldContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: 'Monto', isRequired: true),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '\$',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+[,.]?\d{0,2}')),
                  ],
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: AppColors.primary.withOpacity(0.2),
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    errorStyle: TextStyle(
                      color: Colors.redAccent.shade200,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // CA1: Required, numeric, positive, > 0
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El monto es obligatorio.';
                    }
                    final parsed =
                        double.tryParse(value.replaceAll(',', '.'));
                    if (parsed == null) return 'Ingresa un número válido.';
                    if (parsed <= 0) {
                      return 'El monto debe ser mayor a cero.';
                    }
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

  // ─── Date Field ────────────────────────────────────────────────────────────
  Widget _buildDateField() {
    return _FieldContainer(
      onTap: _pickDate,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: AppColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(label: 'Fecha', isRequired: true),
                const SizedBox(height: 2),
                Text(
                  DateFormat("d 'de' MMMM, yyyy", 'es').format(_selectedDate),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  // ─── Source Dropdown ───────────────────────────────────────────────────────
  Widget _buildSourceDropdown() {
    return _FieldContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: 'Fuente de Ingreso', isRequired: true),
          const SizedBox(height: 10),
          if (_isLoadingSources)
            Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            )
          else
            DropdownButtonFormField<IncomeSource>(
              value: _selectedSource,
              dropdownColor: AppColors.surface,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              iconEnabledColor: AppColors.accent,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              hint: Text(
                'Selecciona una fuente',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.35),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              items: _sources
                  .map((source) => DropdownMenuItem<IncomeSource>(
                        value: source,
                        child: Text(source.name),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedSource = value),
              validator: (value) {
                if (value == null) {
                  return 'Selecciona una fuente de ingreso.';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }

  // ─── Description Field ─────────────────────────────────────────────────────
  Widget _buildDescriptionField() {
    return _FieldContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: 'Descripción', isRequired: false),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            minLines: 1,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Ej: Pago de nómina, proyecto freelance...',
              hintStyle: TextStyle(
                color: AppColors.primary.withOpacity(0.3),
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            // CA4: Optional — no validator needed.
          ),
        ],
      ),
    );
  }

  // ─── Save Button ───────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveIncome,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
            foregroundColor: AppColors.background,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isSaving
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.background,
                  ),
                )
              : const Text(
                  'Registrar Ingreso',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Shared Sub-Widgets ──────────────────────────────────────────────────────

/// A reusable container that wraps form fields with a consistent card style.
class _FieldContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _FieldContainer({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// A small label shown above each field.
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const _FieldLabel({required this.label, required this.isRequired});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primary.withOpacity(0.45),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 3),
          Text(
            '•',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}

/// A minimal circular back button matching KAIRO's aesthetic.
class _MinimalBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MinimalBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: SizedBox(
        width: 40,
        height: 40,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppColors.surface,
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 16,
          ),
        ),
      ),
    );
  }
}