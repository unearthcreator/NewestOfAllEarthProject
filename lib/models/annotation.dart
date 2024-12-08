class Annotation {
  final String id;
  final String title;
  final String iconName;
  final DateTime date;
  final String note;
  final List<String> images;
  final double latitude;
  final double longitude;

  Annotation({
    required this.id,
    required this.title,
    required this.iconName,
    required this.date,
    required this.note,
    required this.images,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'iconName': iconName,
      'date': date.toIso8601String(),
      'note': note,
      'images': images,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Annotation.fromJson(Map<String, dynamic> json) {
    return Annotation(
      id: json['id'] as String,
      title: json['title'] as String,
      iconName: json['iconName'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String,
      images: List<String>.from(json['images'] as List),
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
    );
  }

  @override
  String toString() {
    return 'Annotation(id: $id, title: $title, iconName: $iconName, date: $date, note: $note, images: $images, latitude: $latitude, longitude: $longitude)';
  }
}