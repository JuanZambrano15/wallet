import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/models/balance.dart';
import 'package:wallet/services/balance_service.dart';
import 'package:wallet/utils/balance_calculator.dart';
import 'package:wallet/utils/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wallet/services/expenseCategories.service.dart';

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
  // Datos para la gráfica
  Map<String, double> _expensesByCategory = {};
  Map<String, String> _categoryNames = {};

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
      final balance = await _balanceService.calculateAndSavePeriodBalance(
        _selectedPeriod,
      );

      // 2. Para mostrar el desglose de "Total Ingresos" y "Total Gastos" en la UI,
      // consultamos las sumatorias correspondientes al mismo rango de fechas.
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final range = BalanceCalculator.calculateDateRange(_selectedPeriod);

      final incomeSnapshot = await FirebaseFirestore.instance
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
          .get();

      final expenseSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
          .get();

      // Agrupar gastos por categoría
      final Map<String, double> byCategory = {};
      for (final doc in expenseSnapshot.docs) {
        final data = doc.data();
        final catId = data['categoryId'] ?? 'unknown';
        final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
        byCategory[catId] = (byCategory[catId] ?? 0.0) + amt;
      }

      // Obtener nombres de las categorías para la leyenda
      final ExpenseCategoryService catService = ExpenseCategoryService();
      final categories = await catService.getAllCategories();
      final Map<String, String> names = {};
      for (final c in categories) {
        names[c.id] = c.name;
      }

      // Agrupar categorías menores al 3% en "Otros"
      final totalExpensesForGrouping = byCategory.values.fold(
        0.0,
        (acc, b) => acc + b,
      );
      final Map<String, double> grouped = {};
      double othersSum = 0.0;
      if (totalExpensesForGrouping > 0) {
        byCategory.forEach((catId, amt) {
          final pct = (amt / totalExpensesForGrouping) * 100;
          if (pct < 3.0) {
            othersSum += amt;
          } else {
            grouped[catId] = amt;
          }
        });
      }
      if (othersSum > 0) grouped['others'] = othersSum;

      double incomesSum = incomeSnapshot.docs.fold(
        0.0,
        (acc, doc) => acc + (doc.data()['amount'] ?? 0.0),
      );
      double expensesSum = expenseSnapshot.docs.fold(
        0.0,
        (acc, doc) => acc + (doc.data()['amount'] ?? 0.0),
      );

      setState(() {
        _currentBalance = balance;
        _totalIncomes = incomesSum;
        _totalExpenses = expensesSum;
        _expensesByCategory = grouped;
        _categoryNames = names;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al calcular finanzas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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

  String get _selectedPeriodLabel {
    return _periods.firstWhere(
      (p) => p['value'] == _selectedPeriod,
      orElse: () => {'label': 'Periodo'},
    )['label']!;
  }

  // Construye la gráfica de torta usando fl_chart
  Widget _buildPieChart() {
    if (_expensesByCategory.isEmpty || _totalExpenses <= 0) {
      return const Center(
        child: Text('No hay gastos en el periodo seleccionado'),
      );
    }

    final total = _expensesByCategory.values.fold(0.0, (a, b) => a + b);

    // Paleta de colores (tonos rojos/naranjas). Repetir si hay más categorías.
    final palette = [
      const Color(0xFFEF4444), // red
      const Color(0xFFF97316), // orange
      const Color(0xFFFB923C), // orange-300
      const Color(0xFFEF9A9A),
      const Color(0xFFFCA5A5),
    ];

    final sections = <PieChartSectionData>[];
    int i = 0;
    _expensesByCategory.forEach((catId, amt) {
      final pct = total > 0 ? (amt / total) * 100 : 0.0;
      final color = catId == 'others'
          ? AppColors.gray
          : palette[i % palette.length];
      sections.add(
        PieChartSectionData(
          color: color,
          value: amt,
          title: '${pct.toStringAsFixed(0)}%',
          radius: 56,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
      i++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 28,
        sectionsSpace: 2,
        borderData: FlBorderData(show: false),
      ),
    );
  }

  // Construye la leyenda debajo de la gráfica
  Widget _buildLegend() {
    if (_expensesByCategory.isEmpty || _totalExpenses <= 0) {
      return const SizedBox.shrink();
    }

    final total = _expensesByCategory.values.fold(0.0, (a, b) => a + b);
    final palette = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFFFB923C),
      const Color(0xFFEF9A9A),
      const Color(0xFFFCA5A5),
    ];

    int i = 0;
    final items = _expensesByCategory.entries.map((e) {
      final id = e.key;
      final amt = e.value;
      final pct = total > 0 ? (amt / total) * 100 : 0.0;
      final color = id == 'others'
          ? AppColors.gray
          : palette[i % palette.length];
      final name = id == 'others'
          ? 'Otros'
          : (_categoryNames[id] ?? 'Sin categoría');
      i++;
      return Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 8),
          Text(
            '${pct.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 13, color: AppColors.accentDim),
          ),
        ],
      );
    }).toList();

    return Column(
      children: items
          .map(
            (w) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: w,
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determinar color semántico del balance (Verde si es positivo o cero, Rojo si es negativo)
    final bool isPositive = (_currentBalance?.amount ?? 0.0) >= 0;
    final Color balanceColor = isPositive
        ? AppColors.tealAccent
        : AppColors.redAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Balance Patrimonial',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
        children: [
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
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border2,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        p['label']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
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

          if (_isLoading)
            const SizedBox(
              height: 260,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else if (_currentBalance == null)
            const SizedBox(
              height: 260,
              child: Center(
                child: Text('No se pudieron recuperar datos financieros.'),
              ),
            )
          else ...[
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
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppColors.gray,
                  ),
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
                      color: balanceColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPositive
                        ? 'Finanzas estables y saludables'
                        : 'Déficit en el periodo seleccionado',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accentMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
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
                            Icon(
                              Icons.arrow_upward_rounded,
                              color: AppColors.tealAccent,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Ingresos',
                              style: TextStyle(
                                color: AppColors.gray,
                                fontSize: 13,
                              ),
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
                            Icon(
                              Icons.arrow_downward_rounded,
                              color: AppColors.redAccent,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Gastos',
                              style: TextStyle(
                                color: AppColors.gray,
                                fontSize: 13,
                              ),
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Gastos por categoría — $_selectedPeriodLabel',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(height: 220, child: _buildPieChart()),
                  const SizedBox(height: 12),
                  _buildLegend(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _fetchAndCalculateBalance,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Sincronizar Balance'),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
