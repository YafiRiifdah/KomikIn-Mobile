// lib/models/history_model.dart - Updated untuk match dengan history screen baru
class History {
  final String mangaId;
  final String chapterId;
  final int lastPage;
  final String updatedAt;
  final String mangaTitle;
  final String? mangaCoverUrl;

  History({
    required this.mangaId,
    required this.chapterId,
    required this.lastPage,
    required this.updatedAt,
    required this.mangaTitle,
    this.mangaCoverUrl,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      mangaId: json['manga_id']?.toString() ?? json['mangaId']?.toString() ?? '',
      chapterId: json['chapter_id']?.toString() ?? json['chapterId']?.toString() ?? '',
      lastPage: int.tryParse(json['last_page']?.toString() ?? json['lastPage']?.toString() ?? '0') ?? 0,
      updatedAt: json['updated_at']?.toString() ?? json['updatedAt']?.toString() ?? '',
      mangaTitle: json['mangaTitle']?.toString() ?? json['manga_title']?.toString() ?? 'N/A',
      mangaCoverUrl: json['mangaCoverUrl']?.toString() ?? json['manga_cover_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'manga_id': mangaId,
      'chapter_id': chapterId,
      'last_page': lastPage,
      'updated_at': updatedAt,
      'mangaTitle': mangaTitle,
      'mangaCoverUrl': mangaCoverUrl,
    };
  }
}

class HistoryPagination {
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final int totalItems;

  HistoryPagination({
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.totalItems,
  });

  factory HistoryPagination.fromJson(Map<String, dynamic> json) {
    return HistoryPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      itemsPerPage: json['itemsPerPage'] ?? 10,
      totalItems: json['totalItems'] ?? 0,
    );
  }
}