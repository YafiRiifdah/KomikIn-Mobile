class Chapter {
  final String id;
  final String? volume; // Bisa null
  final String? chapter; // Nomor chapter, bisa null atau string seperti "oneshot"
  final String? title; // Judul chapter, bisa null
  final String language;
  final int pages; // Jumlah halaman
  final String publishAt; // Timestamp
  final String scanlationGroup;

  Chapter({
    required this.id,
    this.volume,
    this.chapter,
    this.title,
    required this.language,
    required this.pages,
    required this.publishAt,
    required this.scanlationGroup,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] ?? 'N/A',
      volume: json['volume'],
      chapter: json['chapter'],
      title: json['title'],
      language: json['language'] ?? 'N/A',
      pages: json['pages'] ?? 0,
      publishAt: json['publishAt'] ?? '',
      scanlationGroup: json['scanlationGroup'] ?? 'Unknown',
    );
  }
}

// Model untuk respons daftar chapter dari backend
class ChaptersResponse {
  final String message;
  final List<Chapter> chapters;
  // Tambahkan info paginasi jika endpoint /feed Anda mendukungnya dan mengembalikannya

  ChaptersResponse({
    required this.message,
    required this.chapters,
  });

  factory ChaptersResponse.fromJson(Map<String, dynamic> json) {
    var chapterList = (json['data'] as List? ?? [])
        .map((i) => Chapter.fromJson(i as Map<String, dynamic>))
        .toList();
    return ChaptersResponse(
      message: json['message'] ?? '',
      chapters: chapterList,
    );
  }
}