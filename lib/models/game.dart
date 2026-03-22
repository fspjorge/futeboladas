import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String title;
  final String location;
  final int players;
  final DateTime date;
  final String? createdBy;
  final String? createdByName;
  final String? createdByPhoto;
  final double? lat;
  final double? lon;
  final List<String> participants;
  final bool isActive;
  final String? field; // ← NOVO
  final double? price; // ← NOVO

  Game({
    required this.id,
    required this.title,
    required this.location,
    required this.players,
    required this.date,
    this.createdBy,
    this.createdByName,
    this.createdByPhoto,
    this.lat,
    this.lon,
    this.participants = const [],
    this.isActive = true,
    this.field,
    this.price,
  });

  factory Game.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Game(
      id: doc.id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      players: (data['players'] as num?)?.toInt() ?? 0,
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.parse(data['date'] as String),
      createdBy: data['createdBy'],
      createdByName: data['createdByName'],
      createdByPhoto: data['createdByPhoto'],
      lat: (data['lat'] as num?)?.toDouble(),
      lon: (data['lon'] as num?)?.toDouble(),
      participants: List<String>.from(data['participants'] ?? []),
      isActive: data['isActive'] ?? true,
      field: data['field'] as String?,
      price: (data['price'] as num?)?.toDouble(),
    );
  }

  factory Game.fromQueryDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Game.fromFirestore(doc);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'location': location,
      'players': players,
      'date': Timestamp.fromDate(date),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByPhoto': createdByPhoto,
      'lat': lat,
      'lon': lon,
      'participants': participants,
      'isActive': isActive,
      'field': field,
      'price': price,
    };
  }
}
