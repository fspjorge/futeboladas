import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/grid_backdrop.dart';
import 'widgets/game_form_content.dart';

class EditGame extends StatefulWidget {
  final String gameId;
  const EditGame({super.key, required this.gameId});

  @override
  State<EditGame> createState() => _JogoEditarState();
}

class _JogoEditarState extends State<EditGame> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _jogadoresCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  DateTime? _data;
  String? _campoSelected;
  double? _selLat;
  double? _selLon;
  bool _busy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarInicial();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _localCtrl.dispose();
    _jogadoresCtrl.dispose();
    _precoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarInicial() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .get();
      if (snap.exists) {
        final data = snap.data()!;
        _tituloCtrl.text = (data['title'] as String?) ?? '';
        _localCtrl.text = (data['location'] as String?) ?? '';
        final pCount = (data['players'] as num?)?.toInt() ?? 0;
        _jogadoresCtrl.text = pCount.toString();

        final unitPrice = data['price'] as num? ?? 0;
        final totalPrice = unitPrice * pCount;
        _precoCtrl.text = totalPrice > 0 ? totalPrice.toStringAsFixed(2) : '';

        _data = (data['date'] as Timestamp?)?.toDate();
        _campoSelected = data['field'] as String?;
        _selLat = data['lat'] as double?;
        _selLon = data['lon'] as double?;
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, indica a data e hora.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final location = _localCtrl.text.trim();
      final title = _tituloCtrl.text.trim();
      final players = int.tryParse(_jogadoresCtrl.text.trim()) ?? 0;
      final total =
          double.tryParse(_precoCtrl.text.trim().replaceFirst(',', '.')) ?? 0.0;
      final price = (players > 0) ? (total / players) : 0.0;

      final update = <String, dynamic>{
        'title': title,
        'location': location,
        'players': players,
        'price': price,
        'date': Timestamp.fromDate(_data!),
        'field': _campoSelected ?? 'Relva Sintética',
        if (_selLat != null) 'lat': _selLat,
        if (_selLon != null) 'lon': _selLon,
      };

      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .update(update);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Editar Jogo',
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
                    initialDate: _data,
                    initialField: _campoSelected,
                    initialLat: _selLat,
                    initialLon: _selLon,
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
        onPressed: _busy ? null : _guardar,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'GUARDAR ALTERAÇÕES',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
