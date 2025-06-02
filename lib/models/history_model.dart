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
      mangaId: json['manga_id']?.toString() ?? '',
      chapterId: json['chapter_id']?.toString() ?? '',
      lastPage: json['last_page'] ?? 0,
      updatedAt: json['updated_at']?.toString() ?? '',
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

  // Helper method untuk mendapatkan reading progress percentage
  double getReadingProgress(int totalPages) {
    if (totalPages == 0) return 0.0;
    return (lastPage / totalPages).clamp(0.0, 1.0);
  }

  // Helper method untuk format reading status
  String getReadingStatus(int totalPages) {
    if (totalPages == 0) return 'Unknown pages';
    
    final progress = getReadingProgress(totalPages);
    if (progress >= 1.0) {
      return 'Completed';
    } else if (progress >= 0.8) {
      return 'Almost done';
    } else if (progress >= 0.5) {
      return 'Half read';
    } else if (progress > 0) {
      return 'In progress';
    } else {
      return 'Not started';
    }
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
      totalPages: json['totalPages'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
      totalItems: json['totalItems'] ?? 0,
    );
  }
}

class HistoryResponse {
  final String message;
  final List<History> histories;
  final HistoryPagination pagination;

  HistoryResponse({
    required this.message,
    required this.histories,
    required this.pagination,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    return HistoryResponse(
      message: json['message'] ?? '',
      histories: (json['data'] as List<dynamic>?)
          ?.map((item) => History.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      pagination: HistoryPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}