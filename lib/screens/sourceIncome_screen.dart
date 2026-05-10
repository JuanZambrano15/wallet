// lib/screens/income_sources/income_sources_screen.dart

import 'package:flutter/material.dart';
import '../models/sourceIncome.dart';
import '../services/sourceIncome.service.dart';
import '../../utils/app_theme.dart';

class IncomeSourcesScreen extends StatefulWidget {
  const IncomeSourcesScreen({super.key});

  @override
  State<IncomeSourcesScreen> createState() => _IncomeSourcesScreenState();
}

class _IncomeSourcesScreenState extends State<IncomeSourcesScreen> {
  final SourceIncomeService _service = SourceIncomeService();
  List<SourceIncome> _sources = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    setState(() { _loading = true; _error = null; });
    try {
      final sources = await _service.getSourceIncomesByUser();
      setState(() { _sources = sources; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<SourceIncome> get _personalized =>
      _sources.where((s) => s.personalized).toList();
  SourceIncome? get _generic =>
      _sources.where((s) => !s.personalized).firstOrNull;

  // ─────────────────────────────────────────────────────────────
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
                          color: AppColors.tealAccent))
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
          _squareIconBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Fuentes de ingreso',
              style: TextStyle(
                fontSize: 20, color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showSourceDialog(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.accent, size: 20),
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
      onRefresh: _loadSources,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        children: [
          _buildHintBanner(),
          const SizedBox(height: 14),
          _sectionLabel('Fuentes personalizadas · ${_personalized.length}'),
          const SizedBox(height: 10),
          if (_personalized.isEmpty)
            _buildEmptyState()
          else
            ..._personalized.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSourceCard(s),
            )),
          const SizedBox(height: 16),
          _sectionLabel('Fuente del sistema'),
          const SizedBox(height: 10),
          if (_generic != null) _buildGenericCard(_generic!),
        ],
      ),
    );
  }

  // ── HINT BANNER ──────────────────────────────────────────────
  Widget _buildHintBanner() {
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
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.tealAccent),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Si no creas ninguna fuente, el sistema asignará General a tus ingresos automáticamente.',
              style: TextStyle(fontSize: 11, color: AppColors.tealAccent,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── SOURCE CARD ──────────────────────────────────────────────
  Widget _buildSourceCard(SourceIncome source) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                _sourceAvatar(source),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(source.name,
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.accent),
                          overflow: TextOverflow.ellipsis),
                      if (source.description.isNotEmpty)
                        Text(source.description,
                            style: const TextStyle(fontSize: 11,
                                color: AppColors.accentMuted),
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    _squareIconBtn(
                      icon: Icons.edit_outlined,
                      iconColor: AppColors.tealAccent,
                      bg: AppColors.primary.withOpacity(0.2),
                      onTap: () => _showSourceDialog(context, source: source),
                    ),
                    const SizedBox(width: 6),
                    _squareIconBtn(
                      icon: Icons.delete_outline_rounded,
                      iconColor: AppColors.redAccent,
                      bg: AppColors.redAccent.withOpacity(0.12),
                      onTap: () => _confirmDelete(source),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 12, color: AppColors.accentMuted),
                const SizedBox(width: 5),
                const Text('Fuente personalizada',
                    style: TextStyle(fontSize: 10,
                        color: AppColors.accentMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── GENERIC CARD ─────────────────────────────────────────────
  Widget _buildGenericCard(SourceIncome source) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentMuted.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.circle_outlined,
                size: 20, color: AppColors.accentMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('General',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w500, color: AppColors.accent)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 10, color: AppColors.tealAccent),
                      SizedBox(width: 3),
                      Text('Sistema',
                          style: TextStyle(fontSize: 10,
                              color: AppColors.tealAccent,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Text('Solo lectura',
              style: TextStyle(fontSize: 10, color: AppColors.accentMuted)),
        ],
      ),
    );
  }

  // ── EMPTY STATE ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.note_add_outlined,
                size: 24, color: AppColors.tealAccent),
          ),
          const SizedBox(height: 10),
          const Text('Sin fuentes personalizadas',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColors.accentDim)),
          const SizedBox(height: 4),
          const Text(
            'Toca el botón + para crear tu\nprimera fuente de ingreso.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.accentMuted,
                height: 1.5),
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
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 40),
          const SizedBox(height: 12),
          Text(_error ?? 'Error al cargar',
              style: const TextStyle(color: AppColors.accentDim,
                  fontSize: 13)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadSources,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // ── DIALOG CREAR / EDITAR ────────────────────────────────────
  void _showSourceDialog(BuildContext context, {SourceIncome? source}) {
    final isEditing = source != null;
    final nameCtrl = TextEditingController(text: source?.name ?? '');
    final descCtrl = TextEditingController(text: source?.description ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border2),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
                    child: Row(
                      children: [
                        Text(
                          isEditing ? 'Editar fuente' : 'Nueva fuente',
                          style: const TextStyle(fontSize: 17,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        _squareIconBtn(
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 0.5, color: AppColors.border),

                  // Fields
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Nombre', required: true),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nameCtrl,
                          maxLength: 50,
                          style: const TextStyle(fontSize: 13,
                              color: AppColors.accent),
                          decoration: const InputDecoration(
                            hintText: 'Ej: Salario, Freelance...',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'El nombre es obligatorio'
                              : null,
                        ),
                        const Text(
                          'Debe ser único entre tus fuentes',
                          style: TextStyle(fontSize: 10,
                              color: AppColors.accentMuted),
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel('Descripción', optional: true),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: descCtrl,
                          maxLines: 3,
                          maxLength: 200,
                          style: const TextStyle(fontSize: 13,
                              color: AppColors.accent),
                          decoration: const InputDecoration(
                            hintText: 'Describe esta fuente de ingreso...',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  Container(height: 0.5, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
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
                            onPressed: saving ? null : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModal(() => saving = true);
                              try {
                                if (isEditing) {
                                  await _service.updateSourceIncome(
                                    id: source.id,
                                    name: nameCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                  );
                                } else {
                                  await _service.createSourceIncome(
                                    name: nameCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                  );
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadSources();
                              } catch (e) {
                                setModal(() => saving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              }
                            },
                            icon: saving
                                ? const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.background),
                                  )
                                : const Icon(Icons.check_rounded, size: 16),
                            label: Text(
                                isEditing ? 'Actualizar' : 'Guardar fuente'),
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
    );
  }

  // ── CONFIRM DELETE ───────────────────────────────────────────
  void _confirmDelete(SourceIncome source) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
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
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 24, color: AppColors.redAccent),
              ),
              const SizedBox(height: 12),
              const Text('¿Eliminar fuente?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.accent)),
              const SizedBox(height: 6),
              Text(
                '"${source.name}" será eliminada permanentemente.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12,
                    color: AppColors.accentMuted, height: 1.5),
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
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await _service.deleteSourceIncome(source.id);
                          _loadSources();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
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
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 10, letterSpacing: 1.2,
          color: AppColors.accentMuted, fontWeight: FontWeight.w600),
    ),
  );

  Widget _fieldLabel(String text,
      {bool required = false, bool optional = false}) {
    return Row(
      children: [
        Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 10, letterSpacing: 1,
                color: AppColors.accentMuted, fontWeight: FontWeight.w600)),
        if (required)
          const Text(' *',
              style: TextStyle(fontSize: 10, color: AppColors.tealAccent)),
        if (optional)
          const Text('  (opcional)',
              style: TextStyle(fontSize: 9, color: AppColors.accentMuted)),
      ],
    );
  }

  Widget _sourceAvatar(SourceIncome source) {
    // Rota entre 3 pares color-icono según inicial del nombre
    final variants = [
      [AppColors.primary.withOpacity(0.45), AppColors.tealAccent,
       Icons.work_outline_rounded],
      [AppColors.amberAccent.withOpacity(0.2), AppColors.amberAccent,
       Icons.device_unknown_outlined],
      [Colors.blue.withOpacity(0.2), const Color(0xFF85B7EB),
       Icons.account_balance_outlined],
    ];
    final v = variants[source.name.codeUnitAt(0) % 3];
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: v[0] as Color,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: (v[0] as Color).withOpacity(0.2)),
      ),
      child: Icon(v[2] as IconData, size: 20, color: v[1] as Color),
    );
  }

  Widget _squareIconBtn({
    required IconData icon,
    Color iconColor = AppColors.accentDim,
    Color bg = AppColors.surface,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}