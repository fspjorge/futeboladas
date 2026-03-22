// No Firestore imports needed

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

  factory Game.fromSupabase(Map<String, dynamic> data) {
    return Game(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      players: (data['players_limit'] as num?)?.toInt() ?? 0,
      date: DateTime.parse(data['date'] as String),
      createdBy: data['created_by']?.toString(),
      // Nota: createdByName e createdByPhoto podem ser buscados via JOIN com a tabela profiles
      lat: (data['lat'] as num?)?.toDouble(),
      lon: (data['lon'] as num?)?.toDouble(),
      isActive: data['is_active'] ?? true,
      field: data['field'] as String?,
      price: (data['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'title': title,
      'location': location,
      'players_limit': players,
      'date': date.toIso8601String(),
      'created_by': createdBy,
      'lat': lat,
      'lon': lon,
      'is_active': isActive,
      'field': field,
      'price': price,
    };
  }
}
