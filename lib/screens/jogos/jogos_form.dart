import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/places_service.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class JogosForm extends StatefulWidget {
  const JogosForm({super.key});

  @override
  State<JogosForm> createState() => _JogosFormState();
}

class _JogosFormState extends State<JogosForm> {
  final _formKey = GlobalKey<FormState>();
  final _localCtrl = TextEditingController();
  final _jogadoresCtrl = TextEditingController(text: '10');
  DateTime? _data;
  bool _busy = false;
  // Google Places (session-based autocomplete)
  final _restPlaces = PlacesService();
  // Prefer native SDK; fallback to REST if unavailable
  late final FlutterGooglePlacesSdk _placesSdk = FlutterGooglePlacesSdk(
    const String.fromEnvironment(
      'PLACES_API_KEY',
      defaultValue: 'AIzaSyAPRZImkhwXKE0lqBhYAUvlBXKLN-UbnYk',
    ),
  );
  String? _placesToken;
  List<AutocompletePrediction> _sugestoes = [];
  double? _selLat;
  double? _selLon;

  @override
  void dispose() {
    _localCtrl.dispose();
    _jogadoresCtrl.dispose();
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
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() {
      _data = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Seleciona data e hora.')));
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
          // geocoding pode falhar no web; ignorar erro
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

      await FirebaseFirestore.instance.collection('jogos').add(data);

      if (!mounted) return;
      // Devolver resultado ao ecrã anterior; mostrar SnackBar lá
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Falha ao agendar jogo')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar Jogo')),
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
                    onChanged: (txt) async {
                      // Prefer SDK; if it fails, fallback to REST service
                      if (txt.trim().length < 3) {
                        setState(() => _sugestoes = []);
                        return;
                      }
                      _placesToken ??= DateTime.now().millisecondsSinceEpoch.toString();
                      try {
                        final res = await _placesSdk.findAutocompletePredictions(
                          txt.trim(),
                          countries: const ['pt'],
                          sessionToken: _placesToken,
                        );
                        if (!mounted) return;
                        setState(() => _sugestoes = res.predictions);
                      } catch (_) {
                        if (!_restPlaces.isConfigured) return;
                        final preds = await _restPlaces.autocomplete(txt.trim(), sessionToken: _placesToken);
                        if (!mounted) return;
                        setState(() => _sugestoes = preds
                            .map((p) => AutocompletePrediction(placeId: p.placeId, fullText: p.description))
                            .toList());
                      }
                    },
                  ),
                  if (_sugestoes.isNotEmpty)
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(8),
                        child: ListView(
                          shrinkWrap: true,
                          children: _sugestoes
                              .map((s) => ListTile(
                                    dense: true,
                                    title: Text(s.fullText),
                                    onTap: () async {
                                      _localCtrl.text = s.fullText;
                                      double? lat;
                                      double? lon;
                                      try {
                                        final det = await _placesSdk.fetchPlace(
                                          s.placeId,
                                          fields: const [PlaceField.Location],
                                          sessionToken: _placesToken,
                                        );
                                        lat = det.place?.latLng?.lat;
                                        lon = det.place?.latLng?.lng;
                                      } catch (_) {
                                        final loc = await _restPlaces.fetchPlaceLatLng(s.placeId, sessionToken: _placesToken);
                                        lat = loc?.lat;
                                        lon = loc?.lon;
                                      }
                                      _placesToken = null; // close session
                                      setState(() {
                                        _sugestoes = [];
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
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text('Agendar'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}




