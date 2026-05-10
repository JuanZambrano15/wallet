import 'package:flutter/material.dart';
import '../../data/expense_emojis.dart';
import '../models/expenseCategories.dart';
import '../services/expenseCategories.service.dart';
import '../../utils/app_theme.dart';

class ExpenseCategoriesScreen extends StatefulWidget {
  const ExpenseCategoriesScreen({super.key});

  @override
  State<ExpenseCategoriesScreen> createState() =>
      _ExpenseCategoriesScreenState();
}

class _ExpenseCategoriesScreenState extends State<ExpenseCategoriesScreen> {
  final _service = ExpenseCategoryService();
  List<ExpenseCategory> _userCategories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getUserCategories();
      setState(() {
        _userCategories = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ExpenseCategory> get _systemCategories => _service.getSystemCategories();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNav(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.tealAccent,
                      ),
                    )
                  : _error != null
                  ? _buildError()
                  : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ── TOP NAV ──────────────────────────────────────────────────
  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Row(
        children: [
          _squareBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Categorías de gasto',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showDialog(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BODY ─────────────────────────────────────────────────────
  Widget _buildBody() {
    return RefreshIndicator(
      color: AppColors.tealAccent,
      backgroundColor: AppColors.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        children: [
          _buildHint(),
          const SizedBox(height: 14),
          _sectionLabel('Mis categorías · ${_userCategories.length}'),
          const SizedBox(height: 10),
          if (_userCategories.isEmpty)
            _buildEmpty()
          else
            ..._userCategories.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildUserCard(c),
              ),
            ),
          const SizedBox(height: 16),
          _sectionLabel('Del sistema · ${_systemCategories.length}'),
          const SizedBox(height: 10),
          ..._systemCategories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildSystemCard(c),
            ),
          ),
        ],
      ),
    );
  }

  // ── HINT ─────────────────────────────────────────────────────
  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppColors.tealAccent,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Las categorías del sistema están siempre disponibles. '
              'Puedes crear las tuyas para personalizar tus gastos.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.tealAccent,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── USER CARD ────────────────────────────────────────────────
  Widget _buildUserCard(ExpenseCategory cat) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                _emojiBox(cat.emoji),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (cat.description.isNotEmpty)
                        Text(
                          cat.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.accentMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Editar
                _squareBtn(
                  icon: Icons.edit_outlined,
                  iconColor: AppColors.tealAccent,
                  bg: AppColors.primary.withOpacity(0.2),
                  onTap: () => _showDialog(context, category: cat),
                ),
                const SizedBox(width: 5),
                // Eliminar
                _squareBtn(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppColors.redAccent,
                  bg: AppColors.redAccent.withOpacity(0.1),
                  onTap: () => _confirmDelete(cat),
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 11,
                  color: AppColors.accentMuted,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Categoría personalizada',
                  style: TextStyle(fontSize: 10, color: AppColors.accentMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SYSTEM CARD ──────────────────────────────────────────────
  Widget _buildSystemCard(ExpenseCategory cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          _emojiBox(cat.emoji, muted: true),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cat.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.28),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 10,
                  color: AppColors.tealAccent,
                ),
                SizedBox(width: 3),
                Text(
                  'Sistema',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.tealAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── EMPTY ────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.label_off_outlined,
              size: 22,
              color: AppColors.tealAccent,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sin categorías personalizadas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.accentDim,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toca el botón + para crear tu primera\ncategoría de gasto.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.accentMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            _error ?? 'Error',
            style: const TextStyle(color: AppColors.accentDim, fontSize: 13),
          ),
          TextButton(onPressed: _load, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  // ── DIALOG CREAR / EDITAR ────────────────────────────────────
  void _showDialog(BuildContext context, {ExpenseCategory? category}) {
    final isEdit = category != null;
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();

    // Estado reactivo dentro del dialog
    String selectedEmoji = category?.emoji ?? '📦';
    String selectedTab = ExpenseEmojis.catalog.keys.first;
    bool saving = false;
    bool pickerOpen = true;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border2),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(17, 15, 13, 11),
                      child: Row(
                        children: [
                          Text(
                            isEdit ? 'Editar categoría' : 'Nueva categoría',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                          const Spacer(),
                          _squareBtn(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 0.5, color: AppColors.border),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre
                          _fieldLabel('Nombre', required: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: nameCtrl,
                            maxLength: 50,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.accent,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Ej: Mascotas, Ropa...',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'El nombre es obligatorio'
                                : null,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Debe ser único entre tus categorías',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.accentMuted,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Emoji
                          _fieldLabel('Emoji', required: true),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Preview del emoji seleccionado
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.6),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    selectedEmoji,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setModal(() => pickerOpen = !pickerOpen),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface3,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.border2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.mood_outlined,
                                          size: 14,
                                          color: AppColors.accentMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          pickerOpen
                                              ? 'Cerrar selector'
                                              : 'Cambiar emoji',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.accentDim,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Emoji picker
                          if (pickerOpen) ...[
                            const SizedBox(height: 10),
                            _buildEmojiPicker(
                              selectedTab: selectedTab,
                              selectedEmoji: selectedEmoji,
                              onTabChanged: (t) =>
                                  setModal(() => selectedTab = t),
                              onEmojiSelected: (e) =>
                                  setModal(() => selectedEmoji = e),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Descripción
                          _fieldLabel('Descripción', optional: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: descCtrl,
                            maxLines: 2,
                            maxLength: 200,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.accent,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Describe esta categoría...',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Footer
                    Container(height: 0.5, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(17, 11, 17, 15),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate())
                                        return;
                                      setModal(() => saving = true);
                                      try {
                                        if (isEdit) {
                                          await _service.updateCategory(
                                            id: category.id,
                                            name: nameCtrl.text.trim(),
                                            emoji: selectedEmoji,
                                            description: descCtrl.text.trim(),
                                          );
                                        } else {
                                          await _service.createCategory(
                                            name: nameCtrl.text.trim(),
                                            emoji: selectedEmoji,
                                            description: descCtrl.text.trim(),
                                          );
                                        }
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                        }
                                        _load();
                                      } catch (e) {
                                        setModal(() => saving = false);
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(
                                            ctx,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString()),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              icon: saving
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.background,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded, size: 15),
                              label: Text(isEdit ? 'Actualizar' : 'Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── EMOJI PICKER ─────────────────────────────────────────────
  Widget _buildEmojiPicker({
    required String selectedTab,
    required String selectedEmoji,
    required ValueChanged<String> onTabChanged,
    required ValueChanged<String> onEmojiSelected,
  }) {
    final emojis = ExpenseEmojis.catalog[selectedTab] ?? [];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        children: [
          // Tabs de categoría
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ExpenseEmojis.catalog.keys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (_, i) {
                final tab = ExpenseEmojis.catalog.keys.elementAt(i);
                final active = tab == selectedTab;
                return GestureDetector(
                  onTap: () => onTabChanged(tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: active
                            ? AppColors.accent
                            : AppColors.accentMuted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Grid de emojis
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: emojis.length,
            itemBuilder: (_, i) {
              final emoji = emojis[i];
              final isSelected = emoji == selectedEmoji;
              return GestureDetector(
                onTap: () => onEmojiSelected(emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.45)
                        : AppColors.accent.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: AppColors.primary.withOpacity(0.7))
                        : null,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── CONFIRM DELETE ───────────────────────────────────────────
  void _confirmDelete(ExpenseCategory cat) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 44),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cat.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              const Text(
                '¿Eliminar categoría?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '"${cat.name}" será eliminada permanentemente.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.accentMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await _service.deleteCategory(cat.id);
                          _load();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                      child: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────
  Widget _emojiBox(String emoji, {bool muted = false}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: muted
            ? AppColors.accentMuted.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.35),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: muted ? AppColors.border : AppColors.primary.withOpacity(0.6),
        ),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
    );
  }

  Widget _squareBtn({
    required IconData icon,
    Color iconColor = AppColors.accentDim,
    Color bg = AppColors.surface,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 15, color: iconColor),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      letterSpacing: 1.2,
      color: AppColors.accentMuted,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _fieldLabel(
    String text, {
    bool required = false,
    bool optional = false,
  }) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1,
            color: AppColors.accentMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(fontSize: 10, color: AppColors.tealAccent),
          ),
        if (optional)
          const Text(
            '  (opcional)',
            style: TextStyle(
              fontSize: 9,
              color: AppColors.accentMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    );
  }
}
