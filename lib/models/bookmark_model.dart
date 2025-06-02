// lib/models/bookmark_model.dart
class Bookmark {
  final String mangaId;
  final String createdAt;
  final String title;
  final String? coverUrl;
  final String author;
  final String status;

  Bookmark({
    required this.mangaId,
    required this.createdAt,
    required this.title,
    this.coverUrl,
    required this.author,
    required this.status,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      mangaId: json['manga_id'] ?? '',
      createdAt: json['created_at'] ?? '',
      title: json['title'] ?? 'N/A',
      coverUrl: json['coverUrl'],
      author: json['author'] ?? 'N/A',
      status: json['status'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'manga_id': mangaId,
      'created_at': createdAt,
      'title': title,
      'coverUrl': coverUrl,
      'author': author,
      'status': status,
    };
  }
}

class BookmarkPagination {
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final int totalItems;

  BookmarkPagination({
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.totalItems,
  });

  factory BookmarkPagination.fromJson(Map<String, dynamic> json) {
    return BookmarkPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
      totalItems: json['totalItems'] ?? 0,
    );
  }
}

class BookmarkResponse {
  final String message;
  final List<Bookmark> bookmarks;
  final BookmarkPagination pagination;

  BookmarkResponse({
    required this.message,
    required this.bookmarks,
    required this.pagination,
  });

  factory BookmarkResponse.fromJson(Map<String, dynamic> json) {
    return BookmarkResponse(
      message: json['message'] ?? '',
      bookmarks: (json['data'] as List<dynamic>?)
          ?.map((item) => Bookmark.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      pagination: BookmarkPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}