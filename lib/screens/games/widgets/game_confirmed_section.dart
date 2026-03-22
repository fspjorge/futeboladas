import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class GameConfirmedSection extends StatelessWidget {
  final String title;
  final DateTime date;
  final String location;
  final String? field;
  final double? price;
  final String? contactosPrivados;
  final String? notasPrivadas;

  const GameConfirmedSection({
    super.key,
    required this.title,
    required this.date,
    required this.location,
    this.field,
    this.price,
    this.contactosPrivados,
    this.notasPrivadas,
  });

  Future<void> _adicionarCalendario(BuildContext context) async {
    try {
      // Google Calendar template link
      final start =
          date
              .toUtc()
              .toIso8601String()
              .replaceAll('-', '')
              .replaceAll(':', '')
              .split('.')
              .first +
          'Z';
      final end =
          date
              .add(const Duration(hours: 1, minutes: 30))
              .toUtc()
              .toIso8601String()
              .replaceAll('-', '')
              .replaceAll(':', '')
              .split('.')
              .first +
          'Z';

      final details = StringBuffer()
        ..writeln('⚽ Futebolada: $title')
        ..writeln('📍 Local: $location')
        ..writeln('🏟️ Campo: ${field ?? "N/A"}')
        ..writeln('💰 Preço: ${price ?? 0}€')
        ..writeln('')
        ..writeln('📞 Contactos: ${contactosPrivados ?? ""}')
        ..writeln('📝 Notas: ${notasPrivadas ?? ""}');

      final uri = Uri.parse(
        'https://www.google.com/calendar/render'
        '?action=TEMPLATE'
        '&text=${Uri.encodeComponent(title)}'
        '&dates=$start/$end'
        '&details=${Uri.encodeComponent(details.toString())}'
        '&location=${Uri.encodeComponent(location)}',
      );

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Não foi possível abrir o calendário');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao abrir calendário: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.15),
                  cs.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF0F172A),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ESTÁS CONVOCADO!',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (contactosPrivados != null &&
                    contactosPrivados!.isNotEmpty) ...[
                  _buildSectionTitle('CONTACTOS DO ORGANIZADOR'),
                  Text(
                    contactosPrivados!,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                ],
                if (notasPrivadas != null && notasPrivadas!.isNotEmpty) ...[
                  _buildSectionTitle('NOTAS / INFO ADICIONAL'),
                  Text(
                    notasPrivadas!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _adicionarCalendario(context),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('ADICIONAR AO CALENDÁRIO'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.white24,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
