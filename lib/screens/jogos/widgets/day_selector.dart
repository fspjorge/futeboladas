import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DaySelector extends StatelessWidget {
  final List<DateTime> allDays;
  final DateTime? selectedDay;
  final Function(DateTime?) onDaySelected;

  const DaySelector({
    super.key,
    required this.allDays,
    this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (allDays.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final displayDate = selectedDay ?? allDays.first;
    final monthDisplay = DateFormat(
      'MMMM yyyy',
      'pt_PT',
    ).format(displayDate).toUpperCase();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            monthDisplay,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: cs.primary.withValues(alpha: 0.5),
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(
          height: 62,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allDays.length,
            itemBuilder: (context, i) {
              final day = allDays[i];
              final isToday =
                  day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final selected =
                  selectedDay != null &&
                  day.year == selectedDay!.year &&
                  day.month == selectedDay!.month &&
                  day.day == selectedDay!.day;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => onDaySelected(selected ? null : day),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary
                          : isToday
                          ? cs.primary.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? cs.primary
                            : isToday
                            ? cs.primary.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.07),
                        width: isToday && !selected ? 1.5 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isToday && !selected)
                          Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          DateFormat.d('pt_PT').format(day),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? const Color(0xFF0F172A)
                                : isToday
                                ? cs.primary
                                : Colors.white,
                          ),
                        ),
                        Text(
                          DateFormat.E(
                            'pt_PT',
                          ).format(day).toUpperCase().substring(0, 3),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: selected
                                ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                : isToday
                                ? cs.primary.withValues(alpha: 0.7)
                                : Colors.white30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
