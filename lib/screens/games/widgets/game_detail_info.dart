import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/attendance_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../utils/format_utils.dart';

class GameDetailInfo extends StatelessWidget {
  final String gameId;
  final Map<String, dynamic> data;
  final AttendanceService presencas;
  final VoidCallback onPickReminder;
  final int reminderMin;
  final Function(String) onOpenMaps;
  final Future<Map<String, dynamic>?>? weather;
  final String? uid;

  const GameDetailInfo({
    super.key,
    required this.gameId,
    required this.data,
    required this.presencas,
    required this.onPickReminder,
    required this.reminderMin,
    required this.onOpenMaps,
    this.weather,
    this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final location = data['location'] as String? ?? '';
    final maxJogadores = (data['players'] as num?)?.toInt() ?? 0;
    final createdByName = data['createdByName'] as String? ?? 'Desconhecido';
    final price = data['price'] as num? ?? 0;

    return GlassCard(
      child: Column(
        children: [
          _infoRow(
            Icons.place_outlined,
            'Localização',
            location,
            trailing: IconButton(
              icon: const Icon(Icons.directions, color: Colors.white70),
              onPressed: () => onOpenMaps(location),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: presencas.countConfirmados(gameId),
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    return _infoRow(
                      Icons.people_outline,
                      'Jogadores',
                      '$count / $maxJogadores',
                    );
                  },
                ),
              ),
              Container(width: 1, height: 60, color: Colors.white10),
              Expanded(
                child: _infoRow(
                  Icons.euro_rounded,
                  'Preço',
                  FormatUtils.formatarPreco(price),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 1),
          _infoRow(Icons.person_outline, 'Organizador', createdByName),
          const Divider(color: Colors.white10, height: 1),
          InkWell(
            onTap: onPickReminder,
            child: _infoRow(
              Icons.notifications_none,
              'Lembrete',
              reminderMin == 0 ? 'No momento' : '$reminderMin min antes',
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            ),
          ),
          if (uid != null)
            StreamBuilder<bool>(
              stream: presencas.minhaPresenca(gameId),
              builder: (context, meSnap) {
                if (meSnap.data != true) return const SizedBox.shrink();

                return Column(
                  children: [
                    const Divider(color: Colors.white10, height: 1),
                    _infoRow(
                      Icons.check_circle_outline,
                      'Estado',
                      'Estás convocado!',
                      labelColor: Theme.of(context).colorScheme.primary,
                      valueColor: Theme.of(context).colorScheme.primary,
                    ),
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('games')
                          .doc(gameId)
                          .collection('admin')
                          .doc('privado')
                          .get(),
                      builder: (context, privSnap) {
                        final privData = privSnap.data?.data();
                        final contacts = privData?['contactos'] as String?;
                        final notes = privData?['historico'] as String?;

                        return Column(
                          children: [
                            if (contacts != null && contacts.isNotEmpty) ...[
                              const Divider(color: Colors.white10, height: 1),
                              _infoRow(
                                Icons.contact_phone_outlined,
                                'Contactos Organização',
                                contacts,
                              ),
                            ],
                            if (notes != null && notes.isNotEmpty) ...[
                              const Divider(color: Colors.white10, height: 1),
                              _infoRow(
                                Icons.notes_outlined,
                                'Notas / Info Adicional',
                                notes,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    InkWell(
                      onTap: () => _adicionarCalendario(context),
                      child: _infoRow(
                        Icons.calendar_month_outlined,
                        'Agenda',
                        'Adicionar ao Calendário',
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          color: Colors.white24,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _adicionarCalendario(BuildContext context) async {
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final title = data['title'] as String? ?? 'Futebolada';
    final location = data['location'] as String? ?? '';

    try {
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

      final uri = Uri.parse(
        'https://www.google.com/calendar/render'
        '?action=TEMPLATE'
        '&text=${Uri.encodeComponent(title)}'
        '&dates=$start/$end'
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

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
    Color? labelColor,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.white60),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: labelColor ?? Colors.white38,
                    fontSize: 12,
                    fontWeight: labelColor != null ? FontWeight.bold : null,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
