import 'package:flutter/foundation.dart';

class HistoryUtils {
  static double calculateReadingProgress(int currentPage, int totalPages) {
    if (totalPages <= 0) return 0.0;
    if (currentPage <= 0) return 0.0;
    if (currentPage >= totalPages) return 100.0;
    
    return (currentPage / totalPages) * 100.0;
  }

  /// Mengecek apakah chapter sudah selesai dibaca
  static bool isChapterComplete(int currentPage, int totalPages) {
    if (totalPages <= 0) return false;
    return currentPage >= totalPages;
  }

  /// Mengecek apakah chapter baru saja dimulai
  static bool isChapterJustStarted(int currentPage) {
    return currentPage <= 1;
  }

  /// Format display untuk progress reading
  static String formatReadingProgress(int currentPage, int totalPages) {
    if (totalPages <= 0) return 'N/A';
    
    final progress = calculateReadingProgress(currentPage, totalPages);
    
    if (isChapterComplete(currentPage, totalPages)) {
      return 'Selesai';
    } else if (isChapterJustStarted(currentPage)) {
      return 'Baru dimulai';
    } else {
      return '${progress.toStringAsFixed(1)}% (${currentPage}/${totalPages})';
    }
  }

  /// Mengecek apakah perlu update history berdasarkan perubahan halaman
  static bool shouldUpdateHistory({
    required int oldPage,
    required int newPage,
    required int totalPages,
    int minimumPageDifference = 1,
  }) {
    // Update jika halaman berubah signifikan
    if ((newPage - oldPage).abs() >= minimumPageDifference) {
      return true;
    }
    
    // Update jika mencapai halaman pertama atau terakhir
    if (newPage == 1 || newPage == totalPages) {
      return true;
    }
    
    // Update jika mencapai milestone tertentu (setiap 10%)
    final oldProgress = calculateReadingProgress(oldPage, totalPages);
    final newProgress = calculateReadingProgress(newPage, totalPages);
    
    if ((newProgress ~/ 10) != (oldProgress ~/ 10)) {
      return true;
    }
    
    return false;
  }

  /// Mendapatkan status membaca berdasarkan halaman
  static ReadingStatus getReadingStatus(int currentPage, int totalPages) {
    if (totalPages <= 0) return ReadingStatus.unknown;
    if (currentPage <= 0) return ReadingStatus.notStarted;
    if (currentPage == 1) return ReadingStatus.justStarted;
    if (currentPage >= totalPages) return ReadingStatus.completed;
    if (currentPage / totalPages >= 0.8) return ReadingStatus.almostComplete;
    if (currentPage / totalPages >= 0.5) return ReadingStatus.halfWay;
    return ReadingStatus.inProgress;
  }

  /// Validasi data sebelum update history
  static HistoryValidationResult validateHistoryData({
    required String mangaId,
    required String chapterId,
    required int currentPage,
    required int totalPages,
  }) {
    final errors = <String>[];
    
    if (mangaId.isEmpty) {
      errors.add('Manga ID tidak boleh kosong');
    }
    
    if (chapterId.isEmpty) {
      errors.add('Chapter ID tidak boleh kosong');
    }
    
    if (currentPage < 0) {
      errors.add('Halaman saat ini tidak boleh negatif');
    }
    
    if (totalPages < 0) {
      errors.add('Total halaman tidak boleh negatif');
    }
    
    if (currentPage > totalPages && totalPages > 0) {
      errors.add('Halaman saat ini melebihi total halaman');
    }
    
    return HistoryValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Debug helper untuk logging
  static void logHistoryUpdate({
    required String mangaId,
    required String chapterId,
    required int currentPage,
    required int totalPages,
    String? additionalInfo,
  }) {
    if (kDebugMode) {
      final progress = calculateReadingProgress(currentPage, totalPages);
      final status = getReadingStatus(currentPage, totalPages);
      
      print([
        '=== HISTORY UPDATE ===',
        'Manga ID: $mangaId',
        'Chapter ID: $chapterId',  
        'Page: $currentPage/$totalPages',
        'Progress: ${progress.toStringAsFixed(1)}%',
        'Status: ${status.name}',
        if (additionalInfo != null) 'Info: $additionalInfo',
        '=====================',
      ].join('\n'));
    }
  }
}

enum ReadingStatus {
  unknown,
  notStarted,
  justStarted,
  inProgress,
  halfWay,
  almostComplete,
  completed,
}

class HistoryValidationResult {
  final bool isValid;
  final List<String> errors;
  
  const HistoryValidationResult({
    required this.isValid,
    required this.errors,
  });
  
  String get errorMessage => errors.join(', ');
}

extension ReadingStatusExtension on ReadingStatus {
  String get displayName {
    switch (this) {
      case ReadingStatus.unknown:
        return 'Tidak diketahui';
      case ReadingStatus.notStarted:
        return 'Belum dimulai';
      case ReadingStatus.justStarted:
        return 'Baru dimulai';
      case ReadingStatus.inProgress:
        return 'Sedang dibaca';
      case ReadingStatus.halfWay:
        return 'Setengah jalan';
      case ReadingStatus.almostComplete:
        return 'Hampir selesai';
      case ReadingStatus.completed:
        return 'Selesai';
    }
  }
  
  String get emoji {
    switch (this) {
      case ReadingStatus.unknown:
        return '❓';
      case ReadingStatus.notStarted:
        return '⭕';
      case ReadingStatus.justStarted:
        return '🆕';
      case ReadingStatus.inProgress:
        return '📖';
      case ReadingStatus.halfWay:
        return '⏳';
      case ReadingStatus.almostComplete:
        return '🔥';
      case ReadingStatus.completed:
        return '✅';
    }
  }
}