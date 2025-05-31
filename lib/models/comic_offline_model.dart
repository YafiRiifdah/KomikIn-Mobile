class ComicOffline {
  final String id;
  final String title;
  final String imageUrl;
  final String localPath; // Path lokal gambar setelah diunduh
  final DateTime downloadedAt;

  ComicOffline({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.localPath,
    required this.downloadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'localPath': localPath,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory ComicOffline.fromMap(Map<String, dynamic> map) {
    return ComicOffline(
      id: map['id'],
      title: map['title'],
      imageUrl: map['imageUrl'],
      localPath: map['localPath'],
      downloadedAt: DateTime.parse(map['downloadedAt']),
    );
  }
}