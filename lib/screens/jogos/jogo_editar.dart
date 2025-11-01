import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/places_service.dart';
\nclass _Suggestion {\n  final String placeId;\n  final String description;\n  const _Suggestion(this.placeId, this.description);\n}\n\n
class JogoEditar extends StatefulWidget {
  final String jogoId;
  const JogoEditar({super.key, required this.jogoId});

  @override
  State<JogoEditar> createState() => _JogoEditarState();
}

class _JogoEditarState extends State<JogoEditar> {
  final _formKey = GlobalKey<FormState>();
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

  // sugestões simples baseadas em locais já usados (gratuito)
  List<String> _locaisHistorico = [];
  List<String> _sugestoes = [];

  @override
  void initState() {
    super.initState();
    _carregarInicial();
    _localCtrl.addListener(_filtrarSugestoes);
  }

  void _filtrarSugestoes() async {
    final q = _localCtrl.text.trim();
    if (q.length < 3) {
      setState(() => _placesSug = []);
      return;
    }
    _placesToken ??= DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final res = await _placesSdk.findAutocompletePredictions(q, countries: const ['pt']);
      if (!mounted) return;
      setState(() => _placesSug = res.predictions.map((p) => _Suggestion(p.placeId, p.fullText ?? ([p.primaryText, p.secondaryText].whereType<String>().join(' ').trim()))).toList());
    } catch (_) {
      if (!_restPlaces.isConfigured) return;
      final preds = await _restPlaces.autocomplete(q, sessionToken: _placesToken);
      if (!mounted) return;
      setState(() => _placesSug = preds.map((p) => _Suggestion(p.placeId, p.description)).toList());
    }
  }

  Future<void> _carregarInicial() async {
    final ref = FirebaseFirestore.instance.collection('jogos').doc(widget.jogoId);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    _localCtrl.text = (data['local'] as String?) ?? '';
    final j = (data['jogadores'] as num?)?.toInt() ?? 0;
    _jogadoresCtrl.text = j.toString();
    _data = (data['data'] as Timestamp?)?.toDate();

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
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(init));
    if (time == null) return;
    setState(() {
      _data = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona data e hora.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
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

      final update = <String, dynamic>{
        'local': local,
        'jogadores': jogadores,
        'data': Timestamp.fromDate(_data!),
        if (lat != null && lon != null) 'lat': lat,
        if (lat != null && lon != null) 'lon': lon,
      };

      await FirebaseFirestore.instance.collection('jogos').doc(widget.jogoId).update(update);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Falha ao guardar')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Jogo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  TextFormField(
                    controller: _localCtrl,
                    decoration: const InputDecoration(labelText: 'Local'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Indica o local' : null,
                    onChanged: (_) => _filtrarSugestoes(),
                  ),
                  if (_placesSug.isNotEmpty)
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(8),
                        child: ListView(
                          shrinkWrap: true,
                          children: _placesSug
                              .map((s) => ListTile(
                                    dense: true,
                                    title: Text(s.description),
                                    onTap: () async {
                                      _localCtrl.text = s.description;
                                      double? lat;
                                      double? lon;
                                      try {
                                        final det = await _placesSdk.fetchPlace(s.placeId, fields: const [PlaceField.Location]);
                                        lat = det.place?.latLng?.lat;
                                        lon = det.place?.latLng?.lng;
                                      } catch (_) {
                                        final loc = await _restPlaces.fetchPlaceLatLng(s.placeId, sessionToken: _placesToken);
                                        lat = loc?.lat;
                                        lon = loc?.lon;
                                      }
                                      _placesToken = null; // close session
                                      setState(() {
                                        _placesSug = [];
                                        _selLat = lat;
                                        _selLon = lon;
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jogadoresCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'N.º de jogadores'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _data == null
                          ? 'Sem data selecionada'
                          : '${_data!.day.toString().padLeft(2, '0')}/${_data!.month.toString().padLeft(2, '0')} ${_data!.hour.toString().padLeft(2, '0')}:${_data!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Escolher data/hora'),
                  )
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _guardar,
                  icon: _busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: const Text('Guardar alterações'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}


