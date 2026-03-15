import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/filter_mode.dart';

class FilterSheet extends StatefulWidget {
  final FilterMode currentMode;
  final String? selectedCampo;
  final bool hasActiveFilter;
  final Function(FilterMode) onModeChanged;
  final Function(String?) onCampoChanged;
  final VoidCallback onClearFilters;

  const FilterSheet({
    super.key,
    required this.currentMode,
    this.selectedCampo,
    required this.hasActiveFilter,
    required this.onModeChanged,
    required this.onCampoChanged,
    required this.onClearFilters,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late FilterMode _localMode;
  late String? _localCampo;

  @override
  void initState() {
    super.initState();
    _localMode = widget.currentMode;
    _localCampo = widget.selectedCampo;
  }

  bool get _localHasActiveFilter =>
      _localMode != FilterMode.todos || _localCampo != null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'FILTROS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white38,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  _SheetChip(
                    label: 'Todos',
                    icon: Icons.grid_view_rounded,
                    selected: _localMode == FilterMode.todos,
                    onTap: () {
                      setState(() => _localMode = FilterMode.todos);
                      widget.onModeChanged(_localMode);
                    },
                    cs: cs,
                  ),
                  _SheetChip(
                    label: 'Meus',
                    icon: Icons.person_outline_rounded,
                    selected: _localMode == FilterMode.meus,
                    onTap: () {
                      setState(() {
                        _localMode = _localMode == FilterMode.meus
                            ? FilterMode.todos
                            : FilterMode.meus;
                      });
                      widget.onModeChanged(_localMode);
                    },
                    cs: cs,
                  ),
                  _SheetChip(
                    label: 'Confirmados',
                    icon: Icons.check_circle_outline_rounded,
                    selected: _localMode == FilterMode.participo,
                    onTap: () {
                      setState(() {
                        _localMode = _localMode == FilterMode.participo
                            ? FilterMode.todos
                            : FilterMode.participo;
                      });
                      widget.onModeChanged(_localMode);
                    },
                    cs: cs,
                  ),
                  _SheetChip(
                    label: 'Gratuitos',
                    icon: Icons.money_off_csred_outlined,
                    selected: _localMode == FilterMode.gratuitos,
                    onTap: () {
                      setState(() {
                        _localMode = _localMode == FilterMode.gratuitos
                            ? FilterMode.todos
                            : FilterMode.gratuitos;
                      });
                      widget.onModeChanged(_localMode);
                    },
                    cs: cs,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'TIPO DE CAMPO',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white38,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  _SheetChip(
                    label: 'Pavilhão',
                    icon: Icons.stairs_outlined,
                    selected: _localCampo == 'Pavilhão',
                    onTap: () {
                      setState(() {
                        _localCampo = _localCampo == 'Pavilhão'
                            ? null
                            : 'Pavilhão';
                      });
                      widget.onCampoChanged(_localCampo);
                    },
                    cs: cs,
                  ),
                  _SheetChip(
                    label: 'Sintética',
                    icon: Icons.grass,
                    selected: _localCampo == 'Relva Sintética',
                    onTap: () {
                      setState(() {
                        _localCampo = _localCampo == 'Relva Sintética'
                            ? null
                            : 'Relva Sintética';
                      });
                      widget.onCampoChanged(_localCampo);
                    },
                    cs: cs,
                  ),
                  _SheetChip(
                    label: 'Natural',
                    icon: Icons.eco_outlined,
                    selected: _localCampo == 'Relva Natural',
                    onTap: () {
                      setState(() {
                        _localCampo = _localCampo == 'Relva Natural'
                            ? null
                            : 'Relva Natural';
                      });
                      widget.onCampoChanged(_localCampo);
                    },
                    cs: cs,
                  ),
                ],
              ),
              if (_localHasActiveFilter) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _localMode = FilterMode.todos;
                      _localCampo = null;
                    });
                    widget.onClearFilters();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: Text(
                    'Limpar filtros',
                    style: GoogleFonts.outfit(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(foregroundColor: Colors.white38),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _SheetChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? cs.primary : Colors.white38),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                color: selected ? cs.primary : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
