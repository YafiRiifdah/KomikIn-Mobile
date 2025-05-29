// lib/models/comic_model.dart
class Comic {
  final String id;
  final String title;
  final String description;
  final String status;
  final int? year;
  final List<String> tags;
  final String coverUrl; // Ini adalah URL, bukan path asset lokal
  final String author;
  final String artist;

  Comic({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.year,
    required this.tags,
    required this.coverUrl,
    required this.author,
    required this.artist,
  });

  factory Comic.fromJson(Map<String, dynamic> json) {
    return Comic(
      id: json['id'] ?? 'N/A',
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      status: json['status'] ?? 'Unknown',
      year: json['year'],
      tags: List<String>.from(json['tags'] ?? []),
      coverUrl: json['coverUrl'] ?? 'https://placehold.co/256x362/222/fff?text=No+Cover',
      author: json['author'] ?? 'Unknown',
      artist: json['artist'] ?? 'Unknown',
    );
  }
}

class PaginatedComicsResponse {
  final String message;
  final List<Comic> comics;
  final PaginationInfo pagination;

  PaginatedComicsResponse({
    required this.message,
    required this.comics,
    required this.pagination,
  });

  factory PaginatedComicsResponse.fromJson(Map<String, dynamic> json) {
    var comicList = (json['data'] as List? ?? [])
        .map((i) => Comic.fromJson(i as Map<String, dynamic>))
        .toList();
    return PaginatedComicsResponse(
      message: json['message'] ?? '',
      comics: comicList,
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final int totalItems;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.totalItems,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 0,
      totalItems: json['totalItems'] ?? 0,
    );
  }
}