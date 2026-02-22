import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/places_service.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'jogo_detalhe.dart'; // ou o nome do teu ficheiro

class _Suggestion {
  final String placeId;
  final String description;
  const _Suggestion(this.placeId, this.description);
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
  final _restPlaces = PlacesService();
  late final FlutterGooglePlacesSdk _placesSdk = FlutterGooglePlacesSdk(
    const String.fromEnvironment('PLACES_API_KEY'),
  );
  String? _placesToken;
  List<_Suggestion> _sugestoes = [];
  double? _selLat;
  double? _selLon;
  bool _showSuggestions = false;
  String? _searchError;
  FocusNode _localFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _localFocusNode.addListener(() {
      if (!_localFocusNode.hasFocus) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
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
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _data = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _sugestoes = [];
        _showSuggestions = false;
      });
      return;
    }

    _placesToken ??= DateTime.now().millisecondsSinceEpoch.toString();
    const key = String.fromEnvironment('PLACES_API_KEY');
    debugPrint('DEBUG: PLACES_API_KEY length: ${key.length}');
    if (key.isNotEmpty) {
      final showCount = key.length < 6 ? key.length : 6;
      debugPrint(
        'DEBUG: PLACES_API_KEY starts with: ${key.substring(0, showCount)}...',
      );
    } else {
      debugPrint('DEBUG: PLACES_API_KEY is EMPTY in Dart environment!');
    }
    List<_Suggestion> list = [];

    try {
      setState(() => _searchError = null);
      final res = await _placesSdk.findAutocompletePredictions(
        query.trim(),
        countries: const ['pt'],
      );
      debugPrint('DEBUG: SDK predictions count: ${res.predictions.length}');
      list = res.predictions
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
    } catch (e) {
      debugPrint('DEBUG: SDK Error (Attempting REST): $e');
    }

    // Tentar REST se o list estiver vazio (ou se o SDK falhou no catch acima)
    if (list.isEmpty && _restPlaces.isConfigured) {
      try {
        debugPrint('DEBUG: Calling REST fallback...');
        final preds = await _restPlaces.autocomplete(
          query.trim(),
          sessionToken: _placesToken,
        );
        debugPrint('DEBUG: REST predictions count: ${preds.length}');
        list = preds.map((p) => _Suggestion(p.placeId, p.description)).toList();
      } catch (e) {
        debugPrint('DEBUG: REST fallback failed: $e');
        final errorMsg = PlacesService.mapError(e);
        if (mounted) setState(() => _searchError = errorMsg);
      }
    }

    if (!mounted) return;
    setState(() {
      _sugestoes = list;
      _showSuggestions = list.isNotEmpty || _searchError != null;
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
      _sugestoes = [];
      _showSuggestions = false;
      _selLat = lat;
      _selLon = lon;
    });
    _localFocusNode.unfocus();
  }

  Future<void> _submit() async {
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
      final novoJogoId = docRef.id;

      if (!mounted) return;

      // Fechar TODOS os ecrãs até chegar à lista principal
      // e depois abrir os detalhes do novo jogo
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => JogoDetalhe(jogoId: novoJogoId)),
        (route) => false, // Remove todas as rotas anteriores
      );

      // Opcional: Mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jogo criado com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Falha ao agendar jogo')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro inesperado: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Agendar Jogo'),
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

                // Campo Local com autocomplete - CORRIGIDO PARA FICAR POR CIMA
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
                            onChanged: (txt) async {
                              await _fetchSuggestions(txt);
                            },
                            onTap: () {
                              if (_localCtrl.text.isNotEmpty &&
                                  _sugestoes.isNotEmpty) {
                                setState(() {
                                  _showSuggestions = true;
                                });
                              }
                            },
                          ),
                        ),
                        // ESPAÇO RESERVADO PARA AS SUGESTÕES
                        if (_showSuggestions &&
                            (_sugestoes.isNotEmpty || _searchError != null))
                          SizedBox(
                            height: _searchError != null
                                ? 80.0
                                : _sugestoes.length * 50.0,
                          ),
                      ],
                    ),

                    // Sugestões do Google Maps - AGORA FICAM POR CIMA
                    if (_showSuggestions &&
                        (_sugestoes.isNotEmpty || _searchError != null))
                      Positioned(
                        top: 60, // Ajuste para ficar logo abaixo do campo
                        left: 0,
                        right: 0,
                        child: Material(
                          elevation: 8, // Elevação maior para ficar por cima
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
                            child: _searchError != null
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _searchError!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: _sugestoes.length,
                                    itemBuilder: (context, index) {
                                      final suggestion = _sugestoes[index];
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          Icons.place_outlined,
                                          size: 20,
                                          color: Colors.blue[400],
                                        ),
                                        title: Text(
                                          suggestion.description,
                                          style: const TextStyle(
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
                              Text('Escolher'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botão de Agendar
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
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
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Agendar Jogo',
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
