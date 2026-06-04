import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/services/balance_service.dart';
import 'package:wallet/utils/balance_calculator.dart';
import '../../utils/app_theme.dart';
import '../screens/sourceIncome_screen.dart';
import '../screens/expenseCategories_screen.dart';
import '../screens/add_income_screen.dart';
import '../screens/balance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNav = 0;
  int _selectedPeriod = 0;
  final List<String> _periods = ['Este mes', 'Semana', 'Año'];

  final BalanceService _balanceService = BalanceService();

  String _firstName = '';
  double _totalIncome = 0;
  double _totalExpenses = 0;
  double _availableBalance = 0;
  bool _loadingUserData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId');

      if (uid == null) {
        if (mounted) setState(() => _loadingUserData = false);
        return;
      }

      // 1. Cargar nombre del usuario
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final rawName = (doc.data()?['nameUser'] ?? '') as String;
        _firstName = rawName.trim().split(' ').first;
      }

      // 2. Calcular balance del periodo mensual usando BalanceService
      final balance = await _balanceService.calculateAndSavePeriodBalance(
        'mensual',
      );
      final range = BalanceCalculator.calculateDateRange('mensual');

      // 3. Sumar ingresos del periodo
      final incomesSnap = await FirebaseFirestore.instance
          .collection('incomes')
          .where('userId', isEqualTo: uid)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
          .get();

      double totalIn = incomesSnap.docs.fold(
        0.0,
        (sum, d) => sum + ((d.data()['amount'] as num?) ?? 0).toDouble(),
      );

      // 4. Sumar gastos del periodo
      final expensesSnap = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: uid)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
          .get();

      double totalExp = expensesSnap.docs.fold(
        0.0,
        (sum, d) => sum + ((d.data()['amount'] as num?) ?? 0).toDouble(),
      );

      if (mounted) {
        setState(() {
          _totalIncome = totalIn;
          _totalExpenses = totalExp;
          _availableBalance = balance.amount; // ingresos - gastos del periodo
          _loadingUserData = false;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar datos: $e");
      if (mounted) setState(() => _loadingUserData = false);
    }
  }

  String _formatCurrency(double amount) {
    final parts = amount.abs().toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    int count = 0;
    for (int i = parts.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
      count++;
    }
    final formatted = buffer.toString().split('').reversed.join();
    return amount < 0 ? '-\$$formatted' : '\$$formatted';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    const SizedBox(height: 16),
                    _buildBalanceCard(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Acciones'),
                    const SizedBox(height: 10),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Fuentes de ingreso'),
                    const SizedBox(height: 10),
                    _buildSourcesList(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Categorías de gasto'),
                    const SizedBox(height: 10),
                    _buildCategoriesWidget(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'KAIRO',
            style: TextStyle(
              fontSize: 20,
              color: AppColors.accent,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _notificationIcon(),
        ],
      ),
    );
  }

  Widget _notificationIcon() {
    return Stack(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.accentDim,
            size: 20,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HOY',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            color: AppColors.accentMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _loadingUserData
              ? 'Cargando...'
              : 'Hola, ${_firstName.isNotEmpty ? _firstName : 'Usuario'} 👋',
          style: const TextStyle(
            fontSize: 22,
            color: AppColors.accent,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final bool isPositive = _availableBalance >= 0;
    final Color balanceColor = isPositive
        ? AppColors.tealAccent
        : AppColors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label superior ──────────────────────────────────────────
          const Text(
            'BALANCE DISPONIBLE',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: AppColors.accentDim,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),

          // ── Monto principal ─────────────────────────────────────────
          _loadingUserData
              ? const Text(
                  '—',
                  style: TextStyle(
                    fontSize: 36,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w300,
                  ),
                )
              : Text(
                  _formatCurrency(_availableBalance),
                  style: TextStyle(
                    fontSize: 36,
                    color: balanceColor,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),

          const SizedBox(height: 14),

          // ── Pills de ingresos y gastos ───────────────────────────────
          Row(
            children: [
              _statPill(
                _loadingUserData ? '+\$—' : '+${_formatCurrency(_totalIncome)}',
                Icons.arrow_upward_rounded,
                isIncome: true,
              ),
              const SizedBox(width: 8),
              _statPill(
                _loadingUserData
                    ? '-\$—'
                    : '-${_formatCurrency(_totalExpenses)}',
                Icons.arrow_downward_rounded,
                isIncome: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String amount, IconData icon, {required bool isIncome}) {
    final color = isIncome ? AppColors.tealAccent : AppColors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.add_rounded, 'label': 'Ingreso'},
      {'icon': Icons.remove_rounded, 'label': 'Gasto'},
      {'icon': Icons.track_changes_rounded, 'label': 'Meta'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Balance'},
    ];
    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _actionBtn(a['icon'] as IconData, a['label'] as String),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _actionBtn(IconData icon, String label) {
    return GestureDetector(
      onTap: () async {
        if (label == 'Ingreso') {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
          );
          if (saved == true) _loadUserData();
        } else if (label == 'Gasto') {
          final saved = await Navigator.pushNamed(context, '/add-expense');
          if (saved == true) _loadUserData(); // ← recarga balance al volver
        } else if (label == 'Balance') {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BalanceScreen()),
          );
          _loadUserData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.6)),
              ),
              child: Icon(icon, size: 18, color: AppColors.tealAccent),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.accentDim,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: _periods.asMap().entries.map((e) {
        final active = e.key == _selectedPeriod;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => setState(() => _selectedPeriod = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: active ? AppColors.accent : AppColors.accentMuted,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSourcesList() {
    return Column(
      children: [
        _sourceItem({
          'icon': Icons.work_outline_rounded,
          'name': 'Salario',
          'amount': 'Actualizado',
        }),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IncomeSourcesScreen()),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 16,
                  color: AppColors.accentMuted,
                ),
                SizedBox(width: 6),
                Text(
                  'Agregar fuente',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accentMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sourceItem(Map<String, dynamic> source) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(source['icon'] as IconData, color: AppColors.tealAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              source['name']!,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            source['amount']!,
            style: const TextStyle(
              color: AppColors.tealAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesWidget() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExpenseCategoriesScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune_rounded, size: 15, color: AppColors.accentMuted),
            SizedBox(width: 6),
            Text(
              'Gestionar categorías',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.accentMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 'Inicio', 0),
          _navItem(Icons.swap_horiz_rounded, 'Movimientos', 1),
          const Icon(Icons.add_box_rounded, size: 45, color: AppColors.accent),
          _navItem(Icons.bar_chart_rounded, 'Análisis', 3),
          _navItem(Icons.person_outline_rounded, 'Perfil', 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _selectedNav == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNav = index);
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BalanceScreen()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? AppColors.tealAccent : AppColors.accentDim,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: active ? AppColors.tealAccent : AppColors.accentMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 1.2,
        color: AppColors.accentMuted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
