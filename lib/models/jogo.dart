import 'package:cloud_firestore/cloud_firestore.dart';

class Jogo {
  final String id;
  final String titulo;
  final String local;
  final int jogadores;
  final DateTime data;
  final String? createdBy;
  final String? createdByName;
  final String? createdByPhoto;
  final double? lat;
  final double? lon;
  final bool ativo;

  Jogo({
    required this.id,
    required this.titulo,
    required this.local,
    required this.jogadores,
    required this.data,
    this.createdBy,
    this.createdByName,
    this.createdByPhoto,
    this.lat,
    this.lon,
    this.ativo = true,
  });

  factory Jogo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Jogo(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      local: data['local'] ?? '',
      jogadores: (data['jogadores'] as num?)?.toInt() ?? 0,
      data: (data['data'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
      createdByName: data['createdByName'],
      createdByPhoto: data['createdByPhoto'],
      lat: (data['lat'] as num?)?.toDouble(),
      lon: (data['lon'] as num?)?.toDouble(),
      ativo: data['ativo'] ?? true,
    );
  }

  factory Jogo.fromQueryDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Jogo.fromFirestore(doc);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'local': local,
      'jogadores': jogadores,
      'data': Timestamp.fromDate(data),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByPhoto': createdByPhoto,
      'lat': lat,
      'lon': lon,
      'ativo': ativo,
    };
  }
}
