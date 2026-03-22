import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/game.dart';
import '../../services/game_service.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import 'game_detail.dart';
import '../../widgets/grid_backdrop.dart';
import 'widgets/game_form_content.dart';

class GameForm extends StatefulWidget {
  const GameForm({super.key});

  @override
  State<GameForm> createState() => _JogosFormState();
}

class _JogosFormState extends State<GameForm> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _jogadoresCtrl = TextEditingController(text: '10');
  final _precoCtrl = TextEditingController();
  DateTime? _data;
  String? _campoSelected;
  double? _selLat;
  double? _selLon;
  bool _busy = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _localCtrl.dispose();
    _jogadoresCtrl.dispose();
    _precoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, indica a data e hora.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final title = _tituloCtrl.text.trim();
      final location = _localCtrl.text.trim();
      final players = int.tryParse(_jogadoresCtrl.text.trim()) ?? 0;
      final total =
          double.tryParse(_precoCtrl.text.trim().replaceFirst(',', '.')) ?? 0.0;
      final price = (players > 0) ? (total / players) : 0.0;
      final field = _campoSelected ?? 'Relva Sintética';

      final user = AuthService.instance.currentUser;
      final game = Game(
        id: '', // Supabase gera o UUID
        title: title,
        location: location,
        players: players,
        date: _data!,
        createdBy: user?.id,
        lat: _selLat,
        lon: _selLon,
        field: field,
        price: price,
      );

      final gameId = await GameService.instance.criarJogo(game);

      // Marcar presença automática do criador
      await AttendanceService().markAttendance(gameId, true);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => GameDetail(gameId: gameId)),
        (route) => route.isFirst,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jogo agendado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar jogo: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Agendar Jogo',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFF0F172A))),
          Positioned.fill(child: const GridBackdrop()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GameFormContent(
                    formKey: _formKey,
                    tituloCtrl: _tituloCtrl,
                    localCtrl: _localCtrl,
                    jogadoresCtrl: _jogadoresCtrl,
                    precoCtrl: _precoCtrl,
                    onDateChanged: (d) => _data = d,
                    onFieldChanged: (f) => _campoSelected = f,
                    onLocationChanged: (lat, lon) {
                      _selLat = lat;
                      _selLon = lon;
                    },
                  ),
                  const SizedBox(height: 48),
                  _buildSubmitButton(cs),
                ],
              ),
            ),
          ),
          if (_busy)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _busy ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'CRIAR JOGO AGORA',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
