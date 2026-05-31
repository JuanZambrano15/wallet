import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/models/balance.dart';
import 'package:wallet/services/balance_service.dart';
import 'package:wallet/utils/balance_calculator.dart';
import 'package:wallet/utils/app_theme.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  final BalanceService _balanceService = BalanceService();
  
  // Períodos disponibles definidos en la HU
  final List<Map<String, String>> _periods = [
    {'value': 'quincenal', 'label': 'Quincenal'},
    {'value': 'mensual', 'label': 'Mensual'},
    {'value': 'semestral', 'label': 'Semestral'},
    {'value': 'anual', 'label': 'Anual'},
  ];

  String _selectedPeriod = 'mensual';
  bool _isLoading = false;

  // Variables de estado para los 3 tipos de datos requeridos
  Balance? _currentBalance;
  double _totalIncomes = 0.0;
  double _totalExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateBalance();
  }

  /// Ejecuta de forma integrada el servicio y calcula los desgloses para la UI
  Future<void> _fetchAndCalculateBalance() async {
    setState(() => _isLoading = true);
    try {
      // 1. Calcula y guarda el balance general del periodo en Firestore
      final balance = await _balanceService.calculateAndSavePeriodBalance(_selectedPeriod);

      // 2. Para mostrar el desglose de "Total Ingresos" y "Total Gastos" en la UI,
      // consultamos las sumatorias correspondientes al mismo rango de fechas.
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final range = BalanceCalculator.calculateDateRange(_selectedPeriod);

      final incomeSnapshot = await FirebaseFirestore.instance
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
          .get();

      final expenseSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
          .get();

      double incomesSum = incomeSnapshot.docs.fold(0.0, (sum, doc) => sum + (doc.data()['amount'] ?? 0.0));
      double expensesSum = expenseSnapshot.docs.fold(0.0, (sum, doc) => sum + (doc.data()['amount'] ?? 0.0));

      setState(() {
        _currentBalance = balance;
        _totalIncomes = incomesSum;
        _totalExpenses = expensesSum;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al calcular finanzas: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Helper simple para formatear fechas sin depender de librerías externas (intl)
  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  /// Helper para dar formato de moneda amigable
  String _formatCurrency(double amount) {
    return "\$ ${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";
  }

  @override
  Widget build(BuildContext context) {
    // Determinar color semántico del balance (Verde si es positivo o cero, Rojo si es negativo)
    final bool isPositive = (_currentBalance?.amount ?? 0.0) >= 0;
    final Color balanceColor = isPositive ? AppColors.tealAccent : AppColors.redAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Balance Patrimonial',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            
            // ── SECTOR 1: SELECTOR DE PERÍODOS ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _periods.map((p) {
                final isSelected = _selectedPeriod == p['value'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedPeriod != p['value']) {
                          setState(() => _selectedPeriod = p['value']!);
                          _fetchAndCalculateBalance();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border2,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          p['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.accent : AppColors.gray,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),

            // ── CONTROL DE ESTADO DE CARGA (SPINNER O LOGICA DE PROCESO) ──
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              )
            else if (_currentBalance == null)
              const Expanded(
                child: Center(
                  child: Text('No se pudieron recuperar datos financieros.'),
                ),
              )
            else ...[
              
              // ── SECTOR 2: RANGO DE FECHAS CUBIERTO ────────────────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.gray),
                    const SizedBox(width: 10),
                    Text(
                      "Cobertura: ${_formatDate(_currentBalance!.InitialDate)} al ${_formatDate(_currentBalance!.finalDate)}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.accentDim,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // ── SECTOR 3: CARD PRINCIPAL DE BALANCE PATRIMONIAL ───────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border2, width: 1.5),
                ),
                child: Column(
                  children: [
                    const Text(
                      'BALANCE PATRIMONIAL NETO',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatCurrency(_currentBalance!.amount),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: balanceColor, // Aplicación de color dinámico verde/rojo
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPositive ? 'Finanzas estables y saludables' : 'Déficit en el periodo seleccionado',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accentMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── SECTOR 4: DESGLOSE DE INGRESOS Y GASTOS REALES ────────
              Row(
                children: [
                  // CARD TOTAL INGRESOS
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_upward_rounded, color: AppColors.tealAccent, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Ingresos',
                                style: TextStyle(color: AppColors.gray, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _formatCurrency(_totalIncomes),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tealAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 14),

                  // CARD TOTAL GASTOS
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_downward_rounded, color: AppColors.redAccent, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Gastos',
                                style: TextStyle(color: AppColors.gray, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _formatCurrency(_totalExpenses),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),

              // BOTÓN DE ACCIÓN: RECALCULAR / ACTUALIZAR FORZADO
              OutlinedButton.icon(
                onPressed: _fetchAndCalculateBalance,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Sincronizar Balance'),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}