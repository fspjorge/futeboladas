import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/places_service.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class _Suggestion {
  final String placeId;
  final String description;
  const _Suggestion(this.placeId, this.description);
}

class JogoEditar extends StatefulWidget {
  final String jogoId;
  const JogoEditar({super.key, required this.jogoId});

  @override
  State<JogoEditar> createState() => _JogoEditarState();
}

class _JogoEditarState extends State<JogoEditar> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _jogadoresCtrl = TextEditingController();
  DateTime? _data;
  bool _busy = false;
  // Google Places
  final _restPlaces = PlacesService();
  late final FlutterGooglePlacesSdk _placesSdk = FlutterGooglePlacesSdk(
    const String.fromEnvironment(
      'PLACES_API_KEY',
      defaultValue: 'AIzaSyAPRZImkhwXKE0lqBhYAUvlBXKLN-UbnYk',
    ),
  );
  String? _placesToken;
  List<_Suggestion> _placesSug = [];
  double? _selLat;
  double? _selLon;
  bool _showSuggestions = false;
  FocusNode _localFocusNode = FocusNode();

  // sugestões simples baseadas em locais já usados (gratuito)
  List<String> _locaisHistorico = [];

  @override
  void initState() {
    super.initState();
    _carregarInicial();
    _localFocusNode.addListener(() {
      if (!_localFocusNode.hasFocus) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  void _filtrarSugestoes() async {
    final q = _localCtrl.text.trim();
    if (q.length < 3) {
      setState(() {
        _placesSug = [];
        _showSuggestions = false;
      });
      return;
    }
    _placesToken ??= DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final res = await _placesSdk.findAutocompletePredictions(
        q,
        countries: const ['pt'],
      );
      debugPrint('DEBUG: SDK predictions count: ${res.predictions.length}');
      if (!mounted) return;
      setState(() {
        _placesSug = res.predictions
            .map(
              (p) => _Suggestion(
                p.placeId,
                p.fullText ??
                    ([
                      p.primaryText,
                      p.secondaryText,
                    ].whereType<String>().join(' ').trim()),
              ),
            )
            .toList();
        _showSuggestions = _placesSug.isNotEmpty;
      });
    } catch (e) {
      debugPrint('DEBUG: SDK Error: $e');
      if (!_restPlaces.isConfigured) return;
      debugPrint('DEBUG: Calling REST fallback...');
      final preds = await _restPlaces.autocomplete(
        q,
        sessionToken: _placesToken,
      );
      debugPrint('DEBUG: REST predictions count: ${preds.length}');
      if (!mounted) return;
      setState(() {
        _placesSug = preds
            .map((p) => _Suggestion(p.placeId, p.description))
            .toList();
        _showSuggestions = _placesSug.isNotEmpty;
      });
    }
  }

  Future<void> _carregarInicial() async {
    final ref = FirebaseFirestore.instance
        .collection('jogos')
        .doc(widget.jogoId);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    _tituloCtrl.text = (data['titulo'] as String?) ?? '';
    _localCtrl.text = (data['local'] as String?) ?? '';
    final j = (data['jogadores'] as num?)?.toInt() ?? 0;
    _jogadoresCtrl.text = j.toString();
    _data = (data['data'] as Timestamp?)?.toDate();
    _selLat = data['lat'] as double?;
    _selLon = data['lon'] as double?;

    // carregar histórico de locais (ultimos 50 jogos)
    final hist = await FirebaseFirestore.instance
        .collection('jogos')
        .orderBy('data', descending: true)
        .limit(50)
        .get();
    final set = <String>{};
    for (final d in hist.docs) {
      final l = d.data()['local'] as String?;
      if (l != null && l.trim().isNotEmpty) set.add(l.trim());
    }
    setState(() {
      _locaisHistorico = set.toList();
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final init = _data ?? now;
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
      initialDate: DateTime(init.year, init.month, init.day),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
    );
    if (time == null) return;
    setState(() {
      _data = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _selectSuggestion(_Suggestion suggestion) async {
    _localCtrl.text = suggestion.description;
    double? lat;
    double? lon;

    try {
      final det = await _placesSdk.fetchPlace(
        suggestion.placeId,
        fields: const [PlaceField.Location],
      );
      lat = det.place?.latLng?.lat;
      lon = det.place?.latLng?.lng;
    } catch (_) {
      try {
        final loc = await _restPlaces.fetchPlaceLatLng(
          suggestion.placeId,
          sessionToken: _placesToken,
        );
        lat = loc?.lat;
        lon = loc?.lon;
      } catch (_) {}
    }

    _placesToken = null;
    setState(() {
      _placesSug = [];
      _showSuggestions = false;
      _selLat = lat;
      _selLon = lon;
    });
    _localFocusNode.unfocus();
  }

  Future<void> _guardar() async {
    setState(() {
      _showSuggestions = false;
    });
    _localFocusNode.unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleciona data e hora.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final local = _localCtrl.text.trim();
      final titulo = _tituloCtrl.text.trim();
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

      final update = <String, dynamic>{
        'titulo': titulo,
        'local': local,
        'jogadores': jogadores,
        'data': Timestamp.fromDate(_data!),
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
      };

      await FirebaseFirestore.instance
          .collection('jogos')
          .doc(widget.jogoId)
          .update(update);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Falha ao guardar')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Editar Jogo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showSuggestions = false;
          });
          _localFocusNode.unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo Título
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[700]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _tituloCtrl,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Título do Jogo',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      suffixIcon: Icon(
                        Icons.sports_soccer,
                        color: Colors.grey[400],
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Indica um título para o jogo'
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Campo Local com autocomplete
                Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[700]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _localCtrl,
                            focusNode: _localFocusNode,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Local',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey[400],
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Indica o local'
                                : null,
                            onChanged: (_) => _filtrarSugestoes(),
                            onTap: () {
                              if (_localCtrl.text.isNotEmpty &&
                                  _placesSug.isNotEmpty) {
                                setState(() {
                                  _showSuggestions = true;
                                });
                              }
                            },
                          ),
                        ),
                        if (_showSuggestions && _placesSug.isNotEmpty)
                          SizedBox(height: _placesSug.length * 50.0),
                      ],
                    ),

                    if (_showSuggestions && _placesSug.isNotEmpty)
                      Positioned(
                        top: 60,
                        left: 0,
                        right: 0,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[600]!),
                            ),
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.4,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              itemCount: _placesSug.length,
                              itemBuilder: (context, index) {
                                final suggestion = _placesSug[index];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.place_outlined,
                                    size: 20,
                                    color: Colors.blue[400],
                                  ),
                                  title: Text(
                                    suggestion.description,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onTap: () {
                                    _selectSuggestion(suggestion);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Campo Número de Jogadores
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[700]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _jogadoresCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'N.º de jogadores',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      suffixIcon: Icon(
                        Icons.people_outline,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Seletor de Data/Hora
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[700]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data e Hora',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _data == null
                                    ? 'Sem data selecionada'
                                    : '${_data!.day.toString().padLeft(2, '0')}/${_data!.month.toString().padLeft(2, '0')} ${_data!.hour.toString().padLeft(2, '0')}:${_data!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: _pickDateTime,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 16),
                              SizedBox(width: 6),
                              Text('Alterar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botão de Guardar
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _busy ? null : _guardar,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Guardar Alterações',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
}
