import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/filter_mode.dart';

class FilterSheet extends StatelessWidget {
  final FilterMode currentMode;
  final String? selectedCampo;
  final bool hasActiveFilter;
  final Function(FilterMode) onModeChanged;
  final Function(String?) onCampoChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onLoadJogosOndeVou;

  const FilterSheet({
    super.key,
    required this.currentMode,
    this.selectedCampo,
    required this.hasActiveFilter,
    required this.onModeChanged,
    required this.onCampoChanged,
    required this.onClearFilters,
    required this.onLoadJogosOndeVou,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                        selected: currentMode == FilterMode.todos,
                        onTap: () {
                          onModeChanged(FilterMode.todos);
                          setSheetState(() {});
                        },
                        cs: cs,
                      ),
                      _SheetChip(
                        label: 'Meus',
                        icon: Icons.person_outline_rounded,
                        selected: currentMode == FilterMode.meus,
                        onTap: () {
                          onModeChanged(
                            currentMode == FilterMode.meus
                                ? FilterMode.todos
                                : FilterMode.meus,
                          );
                          setSheetState(() {});
                        },
                        cs: cs,
                      ),
                      _SheetChip(
                        label: 'Confirmados',
                        icon: Icons.check_circle_outline_rounded,
                        selected: currentMode == FilterMode.participo,
                        onTap: () {
                          final newMode = currentMode == FilterMode.participo
                              ? FilterMode.todos
                              : FilterMode.participo;
                          onModeChanged(newMode);
                          if (newMode == FilterMode.participo)
                            onLoadJogosOndeVou();
                          setSheetState(() {});
                        },
                        cs: cs,
                      ),
                      _SheetChip(
                        label: 'Gratuitos',
                        icon: Icons.money_off_csred_outlined,
                        selected: currentMode == FilterMode.gratuitos,
                        onTap: () {
                          onModeChanged(
                            currentMode == FilterMode.gratuitos
                                ? FilterMode.todos
                                : FilterMode.gratuitos,
                          );
                          setSheetState(() {});
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
                        selected: selectedCampo == 'Pavilhão',
                        onTap: () {
                          onCampoChanged(
                            selectedCampo == 'Pavilhão' ? null : 'Pavilhão',
                          );
                          setSheetState(() {});
                        },
                        cs: cs,
                      ),
                      _SheetChip(
                        label: 'Sintética',
                        icon: Icons.grass,
                        selected: selectedCampo == 'Relva Sintética',
                        onTap: () {
                          onCampoChanged(
                            selectedCampo == 'Relva Sintética'
                                ? null
                                : 'Relva Sintética',
                          );
                          setSheetState(() {});
                        },
                        cs: cs,
                      ),
                      _SheetChip(
                        label: 'Natural',
                        icon: Icons.eco_outlined,
                        selected: selectedCampo == 'Relva Natural',
                        onTap: () {
                          onCampoChanged(
                            selectedCampo == 'Relva Natural'
                                ? null
                                : 'Relva Natural',
                          );
                          setSheetState(() {});
                        },
                        cs: cs,
                      ),
                    ],
                  ),
                  if (hasActiveFilter) ...[
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () {
                        onClearFilters();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close_rounded, size: 14),
                      label: Text(
                        'Limpar filtros',
                        style: GoogleFonts.outfit(fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
