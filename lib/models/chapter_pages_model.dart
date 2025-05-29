// lib/models/chapter_pages_model.dart
class ChapterPagesData {
  final String id;
  final String baseUrl;
  final String chapterHash;
  final List<String> pageFileNames;
  final List<String> pageFileNamesSaver;

  ChapterPagesData({
    required this.id,
    required this.baseUrl,
    required this.chapterHash,
    required this.pageFileNames,
    required this.pageFileNamesSaver,
  });

  factory ChapterPagesData.fromJson(Map<String, dynamic> json) {
    print('[ChapterPagesData.fromJson] Parsing JSON: $json'); // Print JSON yang di-parse model
    return ChapterPagesData(
      id: json['id'] as String? ?? 'N/A',
      baseUrl: json['baseUrl'] as String? ?? '',
      chapterHash: json['hash'] as String? ?? '',
      pageFileNames: List<String>.from(json['pages'] as List? ?? []),
      pageFileNamesSaver: List<String>.from(json['pagesSaver'] as List? ?? []),
    );
  }

  List<String> getFullPageUrls() {
    if (baseUrl.isEmpty || chapterHash.isEmpty) {
        print('[ChapterPagesData.getFullPageUrls] Warning: baseUrl or chapterHash is empty. Base: "$baseUrl", Hash: "$chapterHash"');
        return [];
    }
    final urls = pageFileNames.map((fileName) => '$baseUrl/data/$chapterHash/$fileName').toList();
    print('[ChapterPagesData.getFullPageUrls] Constructed URLs: $urls'); // Print URL yang dikonstruksi
    return urls;
  }

  List<String> getFullPageUrlsSaver() {
     if (baseUrl.isEmpty || chapterHash.isEmpty) return [];
    return pageFileNamesSaver.map((fileName) => '$baseUrl/data-saver/$chapterHash/$fileName').toList();
  }
}
