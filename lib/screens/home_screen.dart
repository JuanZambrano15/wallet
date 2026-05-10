import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme.dart';
import '../screens/sourceIncome_screen.dart';
import '../screens/expenseCategories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNav = 0;
  int _selectedPeriod = 0;
  final List<String> _periods = ['Este mes', 'Semana', 'Año'];

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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomNav()),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────
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
          Stack(
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
          ),
        ],
      ),
    );
  }

  // ── GREETING ─────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DOMINGO, 10 DE MAYO',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            color: AppColors.accentMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hola, Daniel 👋',
          style: TextStyle(
            fontSize: 22,
            color: AppColors.accent,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ── BALANCE CARD ─────────────────────────────────────────────
  Widget _buildBalanceCard() {
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
          Text(
            'BALANCE TOTAL',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: AppColors.accentDim,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '\$1,240,500',
            style: TextStyle(
              fontSize: 36,
              color: AppColors.accent,
              fontWeight: FontWeight.w300,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statPill(
                '+\$3,200,000',
                Icons.arrow_upward_rounded,
                isIncome: true,
              ),
              const SizedBox(width: 8),
              _statPill(
                '−\$1,959,500',
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

  // ── QUICK ACTIONS ────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.add_rounded, 'label': 'Ingreso'},
      {'icon': Icons.remove_rounded, 'label': 'Gasto'},
      {'icon': Icons.track_changes_rounded, 'label': 'Meta'},
      {'icon': Icons.pie_chart_outline_rounded, 'label': 'Reportes'},
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
      onTap: () {},
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

  // ── PERIOD SELECTOR ──────────────────────────────────────────
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

  // ── SOURCES LIST ─────────────────────────────────────────────
  Widget _buildSourcesList() {
    final sources = [
      {
        'icon': Icons.work_outline_rounded,
        'name': 'Salario',
        'sub': 'Ingreso fijo',
        'amount': '+\$2,800,000',
      },
      {
        'icon': Icons.laptop_rounded,
        'name': 'Freelance',
        'sub': 'Proyectos',
        'amount': '+\$400,000',
      },
      {
        'icon': Icons.account_balance_outlined,
        'name': 'Inversiones',
        'sub': 'Rendimientos',
        'amount': '+\$0',
      },
    ];

    return Column(
      children: [
        ...sources.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _sourceItem(s),
          ),
        ),

        // ── Botón "Agregar fuente" → navega a IncomeSourcesScreen ──
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 16,
                  color: AppColors.accentMuted,
                ),
                const SizedBox(width: 6),
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
        const SizedBox(height: 10),
      ],
    );
  }

  // En home_screen.dart — reemplaza _buildCategoriesWidget() completo

  Widget _buildCategoriesWidget() {
    // Preview combinado: sistema + personalizadas del usuario
    // Cuando integres el servicio real, reemplaza esta lista
    final categories = [
      {'emoji': '🏠', 'name': 'Vivienda'},
      {'emoji': '🍔', 'name': 'Alimentación'},
      {'emoji': '💊', 'name': 'Salud'},
      {'emoji': '🚗', 'name': 'Transporte'},
      {'emoji': '🎬', 'name': 'Entret.'},
      {'emoji': '📱', 'name': 'Suscripc.'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Scroll horizontal ──────────────────────────────────
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = categories[i];
              return _categoryCard(emoji: cat['emoji']!, name: cat['name']!);
            },
          ),
        ),
        const SizedBox(height: 10),

        // ── Botón gestionar ────────────────────────────────────
        GestureDetector(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 15,
                  color: AppColors.accentMuted,
                ),
                const SizedBox(width: 6),
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
        ),
      ],
    );
  }

  // ── Tarjeta individual del scroll ──────────────────────────
  Widget _categoryCard({required String emoji, required String name}) {
    return Container(
      width: 68,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 5),
          Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.accent,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Icon(
              source['icon'] as IconData,
              size: 20,
              color: AppColors.tealAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source['name']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  source['sub']!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accentMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            source['amount']!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.tealAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM NAV ───────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 24, left: 10, right: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _navItem(Icons.home_rounded, 'Inicio', 0),
          _navItem(Icons.swap_horiz_rounded, 'Movimientos', 1),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.background,
                size: 26,
              ),
            ),
          ),
          _navItem(Icons.bar_chart_rounded, 'Análisis', 3),
          _navItem(Icons.person_outline_rounded, 'Perfil', 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _selectedNav == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNav = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.tealAccent : AppColors.accentDim,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: active ? AppColors.tealAccent : AppColors.accentMuted,
              ),
            ),
          ],
        ),
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
