import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/osm_service.dart';
import 'jogo_detalhe.dart';

class _Suggestion {
  final String local;
  final double lat;
  final double lon;
  const _Suggestion(this.local, this.lat, this.lon);
}

class JogosForm extends StatefulWidget {
  const JogosForm({super.key});

  @override
  State<JogosForm> createState() => _JogosFormState();
}

class _JogosFormState extends State<JogosForm> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _jogadoresCtrl = TextEditingController(text: '10');
  DateTime? _data;
  bool _busy = false;
  final _osmService = OsmService();
  List<_Suggestion> _sugestoes = [];
  double? _selLat;
  double? _selLon;
  bool _showSuggestions = false;
  String? _searchError;
  final FocusNode _localFocusNode = FocusNode();
  Timer? _debounceSug;
  String? _lastQuery;

  @override
  void initState() {
    super.initState();
    _localFocusNode.addListener(() {
      if (!_localFocusNode.hasFocus) {
        // Pequeno delay para permitir o clique nas sugestões antes de fechar o menu
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_localFocusNode.hasFocus) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceSug?.cancel();
    _tituloCtrl.dispose();
    _localCtrl.dispose();
    _jogadoresCtrl.dispose();
    _localFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
      initialDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: const Color(0xFF0F172A),
              surface: const Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: const Color(0xFF0F172A),
              surface: const Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;
    setState(() {
      _data = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    _debounceSug?.cancel();
    _debounceSug = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _doFetchSuggestions(query);
      } catch (e) {
        debugPrint('Debounce Timer Error: $e');
        if (mounted) {
          setState(() {
            _searchError = 'Erro ao pesquisar local.';
            _showSuggestions = true;
          });
        }
      }
    });
  }

  Future<void> _doFetchSuggestions(String query) async {
    final q = query.trim();
    if (q.length < 3) {
      setState(() {
        _sugestoes = [];
        _showSuggestions = false;
        _searchError = null;
      });
      return;
    }

    _lastQuery = q;
    try {
      setState(() {
        _searchError = null;
        if (_sugestoes.isEmpty) _showSuggestions = true;
      });

      final results = await _osmService.search(q);

      if (_lastQuery != q) return; // Proteção race condition

      if (!mounted) return;
      setState(() {
        _sugestoes = results
            .map((r) => _Suggestion(r.displayName, r.lat, r.lon))
            .toList();
        _searchError = _sugestoes.isEmpty ? 'Nenhum local encontrado.' : null;
        _showSuggestions = true;
      });
    } catch (e) {
      debugPrint('OSM Fetch Error: $e');
      if (mounted && _lastQuery == q) {
        setState(() {
          _searchError = 'Erro na pesquisa de locais.';
          _showSuggestions = true;
        });
      }
    }
  }

  Future<void> _selectSuggestion(_Suggestion suggestion) async {
    setState(() {
      _localCtrl.text = suggestion.local;
      _sugestoes = [];
      _showSuggestions = false;
      _selLat = suggestion.lat;
      _selLon = suggestion.lon;
    });
    _localFocusNode.unfocus();
  }

  Future<void> _submit() async {
    setState(() => _showSuggestions = false);
    _localFocusNode.unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, indica a data e hora.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final titulo = _tituloCtrl.text.trim();
      final local = _localCtrl.text.trim();
      final jogadores = int.tryParse(_jogadoresCtrl.text.trim()) ?? 0;

      double? lat = _selLat;
      double? lon = _selLon;
      if (lat == null || lon == null) {
        try {
          final results = await locationFromAddress('$local, Portugal');
          if (results.isNotEmpty) {
            lat = results.first.latitude;
            lon = results.first.longitude;
          }
        } catch (_) {}
      }

      final user = FirebaseAuth.instance.currentUser;
      final data = <String, dynamic>{
        'ativo': true,
        'titulo': titulo,
        'local': local,
        'jogadores': jogadores,
        'data': Timestamp.fromDate(_data!),
        'createdBy': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        if (user?.displayName != null) 'createdByName': user!.displayName,
        if (user?.photoURL != null) 'createdByPhoto': user!.photoURL,
        if (lat != null && lon != null) 'lat': lat,
        if (lat != null && lon != null) 'lon': lon,
      };

      final docRef = await FirebaseFirestore.instance
          .collection('jogos')
          .add(data);
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => JogoDetalhe(jogoId: docRef.id)),
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
        elevation: 0,
        title: Text(
          'Agendar Partida',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFF0F172A))),
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(painter: _GridBackdropPainter()),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepTitle('DEFINIR DETALHES'),
                    const SizedBox(height: 16),
                    _buildGlassInput(
                      controller: _tituloCtrl,
                      label: 'Nome da Partida',
                      hint: 'ex: Futebolada Semanal',
                      icon: Icons.sports_soccer,
                      validator: (v) =>
                          v!.isEmpty ? 'Título obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildAutocompleteLocal(cs),
                    const SizedBox(height: 16),
                    _buildGlassInput(
                      controller: _jogadoresCtrl,
                      label: 'Nº de Jogadores',
                      hint: 'ex: 10',
                      icon: Icons.people_outline,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    _buildStepTitle('QUANDO'),
                    const SizedBox(height: 16),
                    _buildDateTimePicker(cs),
                    const SizedBox(height: 48),
                    _buildSubmitButton(cs),
                  ],
                ),
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

  Widget _buildStepTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.white38,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    void Function(String)? onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(icon, color: Colors.white38, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildAutocompleteLocal(ColorScheme cs) {
    return Column(
      children: [
        _buildGlassInput(
          controller: _localCtrl,
          focusNode: _localFocusNode,
          label: 'Localização',
          hint: 'ex: Urban Pitch Alvalade',
          icon: Icons.place_outlined,
          onChanged: _fetchSuggestions,
          validator: (v) => v!.isEmpty ? 'Local obrigatório' : null,
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: _searchError != null
                ? ListTile(
                    title: Text(
                      _searchError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      ..._sugestoes.map(
                        (s) => ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: Colors.white38,
                          ),
                          title: Text(
                            s.local,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () => _selectSuggestion(s),
                        ),
                      ),
                      if (_sugestoes.isEmpty && _searchError == null)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
      ],
    );
  }

  Widget _buildDateTimePicker(ColorScheme cs) {
    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_month_outlined, color: cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DATA E HORA',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _data == null
                        ? 'Selecione o horário'
                        : DateFormat(
                            "EEEE, d 'de' MMMM 'às' HH:mm",
                            'pt_PT',
                          ).format(_data!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
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

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const GlassCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GridBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
