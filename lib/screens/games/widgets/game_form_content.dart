import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/osm_service.dart';
import '../../../widgets/glass_card.dart';

class _Suggestion {
  final String location;
  final double lat;
  final double lon;
  const _Suggestion(this.location, this.lat, this.lon);
}

class GameFormContent extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController tituloCtrl;
  final TextEditingController localCtrl;
  final TextEditingController jogadoresCtrl;
  final TextEditingController precoCtrl;
  final DateTime? initialDate;
  final String? initialField;
  final double? initialLat;
  final double? initialLon;
  final Function(DateTime?) onDateChanged;
  final Function(String?) onFieldChanged;
  final Function(double? lat, double? lon) onLocationChanged;

  const GameFormContent({
    super.key,
    required this.formKey,
    required this.tituloCtrl,
    required this.localCtrl,
    required this.jogadoresCtrl,
    required this.precoCtrl,
    this.initialDate,
    this.initialField,
    this.initialLat,
    this.initialLon,
    required this.onDateChanged,
    required this.onFieldChanged,
    required this.onLocationChanged,
  });

  @override
  State<GameFormContent> createState() => _GameFormContentState();
}

class _GameFormContentState extends State<GameFormContent> {
  DateTime? _data;
  final _osmService = OsmService();
  List<_Suggestion> _sugestoes = [];
  bool _showSuggestions = false;
  String? _searchError;
  final FocusNode _localFocusNode = FocusNode();
  Timer? _debounceSug;
  String? _lastQuery;
  String? _campoSelected;

  final List<String> _campoOptions = [
    'Pavilhão',
    'Relva Sintética',
    'Relva Natural',
    'Terra Batida',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _data = widget.initialDate;
    _campoSelected = widget.initialField;
    _localFocusNode.addListener(() {
      if (!_localFocusNode.hasFocus) {
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
    _localFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
      initialDate: _data ?? now,
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
      initialTime: TimeOfDay.fromDateTime(_data ?? now),
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
    widget.onDateChanged(_data);
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
            _searchError = 'Erro ao pesquisar localização.';
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
      if (_lastQuery != q) return;
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

  void _selectSuggestion(_Suggestion suggestion) {
    setState(() {
      widget.localCtrl.text = suggestion.location;
      _sugestoes = [];
      _showSuggestions = false;
    });
    widget.onLocationChanged(suggestion.lat, suggestion.lon);
    _localFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('DEFINIR DETALHES'),
          const SizedBox(height: 16),
          _buildGlassInput(
            controller: widget.tituloCtrl,
            label: 'Nome do Jogo',
            hint: 'ex: Futebolada Semanal',
            icon: Icons.sports_soccer,
            validator: (v) => v!.isEmpty ? 'Título obrigatório' : null,
          ),
          const SizedBox(height: 16),
          _buildAutocompleteLocal(cs),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildGlassInput(
                  controller: widget.jogadoresCtrl,
                  label: 'Jogadores',
                  hint: 'ex: 10',
                  icon: Icons.people_outline,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Obrigatório';
                    final val = int.tryParse(v.trim());
                    if (val == null || val <= 0) return 'Inválido';
                    if (val > 99) return 'Máx 99';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGlassInput(
                      controller: widget.precoCtrl,
                      label: 'Preço Total',
                      hint: '0.00',
                      icon: Icons.euro_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (v) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obrigatório';
                        final val = double.tryParse(
                          v.trim().replaceFirst(',', '.'),
                        );
                        if (val == null || val < 0) return 'Inválido';
                        if (val > 999) return 'Máx 999';
                        return null;
                      },
                    ),
                    if (widget.precoCtrl.text.isNotEmpty &&
                        widget.jogadoresCtrl.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: _buildPriceInfo(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFieldTypePicker(),
          const SizedBox(height: 32),
          _buildStepTitle('QUANDO'),
          const SizedBox(height: 16),
          _buildDateTimePicker(cs),
        ],
      ),
    );
  }

  Widget _buildPriceInfo() {
    final p = int.tryParse(widget.jogadoresCtrl.text) ?? 0;
    final t =
        double.tryParse(widget.precoCtrl.text.replaceFirst(',', '.')) ?? 0;
    final unit = p > 0 ? (t / p) : 0;
    return Text(
      '≈ ${unit.toStringAsFixed(2)}€ por pessoa',
      style: GoogleFonts.outfit(
        fontSize: 12,
        color: Colors.white70,
        fontWeight: FontWeight.w600,
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
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
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
          controller: widget.localCtrl,
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
                            s.location,
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
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
      ),
    );
  }

  Widget _buildFieldTypePicker() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonFormField<String>(
            value: _campoSelected,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Tipo de Campo',
              labelStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.stadium_outlined,
                color: Colors.white38,
                size: 20,
              ),
            ),
            items: _campoOptions.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (newValue) {
              setState(() => _campoSelected = newValue);
              widget.onFieldChanged(newValue);
            },
            validator: (v) => v == null ? 'Seleção obrigatória' : null,
          ),
        ),
      ),
    );
  }
}
