import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/attendance_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../utils/format_utils.dart';
import 'weather_section.dart';

class GameDetailInfo extends StatelessWidget {
  final String gameId;
  final Map<String, dynamic> data;
  final AttendanceService presencas;
  final VoidCallback onPickReminder;
  final int reminderMin;
  final Function(String) onOpenMaps;

  const GameDetailInfo({
    super.key,
    required this.gameId,
    required this.data,
    required this.presencas,
    required this.onPickReminder,
    required this.reminderMin,
    required this.onOpenMaps,
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
          _infoRow(
            Icons.stadium_outlined,
            'Tipo de Campo',
            data['field'] as String? ?? 'Relva Sintética',
          ),
          const Divider(color: Colors.white10, height: 1),
          _infoRow(Icons.person_outline, 'Organizador', createdByName),
          const Divider(color: Colors.white10, height: 1),
          if (data['lat'] != null &&
              data['lon'] != null &&
              data['date'] != null) ...[
            WeatherSection(
              lat: (data['lat'] as num).toDouble(),
              lon: (data['lon'] as num).toDouble(),
              date: (data['date'] as Timestamp).toDate(),
              infoRowBuilder: _infoRow,
            ),
          ],
          InkWell(
            onTap: onPickReminder,
            child: _infoRow(
              Icons.notifications_none,
              'Lembrete',
              reminderMin == 0 ? 'No momento' : '$reminderMin min antes',
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
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
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
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
