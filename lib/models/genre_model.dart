// lib/models/genre_model.dart
class Genre {
  final String id;
  final String name;
  final String group;

  Genre({
    required this.id,
    required this.name,
    required this.group,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Genre',
      group: json['group'] ?? 'Unknown',
    );
  }
}

class GenresResponse {
  final String message;
  final List<Genre> genres;

  GenresResponse({
    required this.message,
    required this.genres,
  });

  factory GenresResponse.fromJson(Map<String, dynamic> json) {
    var genreList = (json['data'] as List? ?? [])
        .map((i) => Genre.fromJson(i as Map<String, dynamic>))
        .toList();
    return GenresResponse(
      message: json['message'] ?? '',
      genres: genreList,
    );
  }
}