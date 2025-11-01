import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

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

      double? lat;
      double? lon;
      try {
        // geocoding pode falhar no web; ignorar erro
        final results = await locationFromAddress('$local, Portugal');
        if (results.isNotEmpty) {
          lat = results.first.latitude;
          lon = results.first.longitude;
        }
      } catch (_) {}

      final data = <String, dynamic>{
        'ativo': true,
        'local': local,
        'jogadores': jogadores,
        'data': Timestamp.fromDate(_data!),
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
              TextFormField(
                controller: _localCtrl,
                decoration: const InputDecoration(labelText: 'Local'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Indica o local' : null,
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
