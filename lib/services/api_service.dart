// lib/services/api_service.dart - Updated with Bookmark Methods
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

// Pastikan path impor model Anda benar sesuai struktur folder Anda
import 'package:komik_in/models/comic_model.dart';
import 'package:komik_in/models/genre_model.dart';
import 'package:komik_in/models/chapter_model.dart';
import 'package:komik_in/models/chapter_pages_model.dart'; 

class ApiService {
  // Menggunakan URL yang sudah Anda konfirmasi berfungsi
  static const String _baseUrl = 'https://api.tascaid.space/api';

  // HISTORY METHODS - BARU

  // Get user reading history with pagination
  Future<Map<String, dynamic>> getHistory({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$_baseUrl/user/history?page=$page&limit=$limit');
    
    print('[ApiService.getHistory] Fetching from: $uri');
    
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      print('[ApiService.getHistory] Response status: ${response.statusCode}');
      print('[ApiService.getHistory] Response body: ${response.body}');

      final decodedResponse = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return decodedResponse;
      } else {
        final errorMessage = decodedResponse['message'] ?? 'Failed to get history';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[ApiService.getHistory] Error: $e');
      rethrow;
    }
  }

  // Add or update reading history
  Future<Map<String, dynamic>> addHistory({
    required String token,
    required String mangaId,
    required String chapterId,
    int lastPage = 0,
  }) async {
    final uri = Uri.parse('$_baseUrl/user/history');
    
    print('[ApiService.addHistory] Adding history for manga: $mangaId, chapter: $chapterId, page: $lastPage');
    
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'mangaId': mangaId,
          'chapterId': chapterId,
          'lastPage': lastPage,
        }),
      ).timeout(const Duration(seconds: 15));

      print('[ApiService.addHistory] Response status: ${response.statusCode}');
      print('[ApiService.addHistory] Response body: ${response.body}');

      final decodedResponse = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return decodedResponse;
      } else {
        final errorMessage = decodedResponse['message'] ?? 'Failed to add history';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[ApiService.addHistory] Error: $e');
      rethrow;
    }
  }

  // BOOKMARK METHODS

  // Get user bookmarks with pagination
  Future<Map<String, dynamic>> getBookmarks({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$_baseUrl/user/bookmarks?page=$page&limit=$limit');
    
    print('[ApiService.getBookmarks] Fetching from: $uri');
    
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      print('[ApiService.getBookmarks] Response status: ${response.statusCode}');
      print('[ApiService.getBookmarks] Response body: ${response.body}');

      final decodedResponse = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return decodedResponse;
      } else {
        final errorMessage = decodedResponse['message'] ?? 'Failed to get bookmarks';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[ApiService.getBookmarks] Error: $e');
      rethrow;
    }
  }

  // Add bookmark
  Future<Map<String, dynamic>> addBookmark({
    required String token,
    required String mangaId,
  }) async {
    final uri = Uri.parse('$_baseUrl/user/bookmarks');
    
    print('[ApiService.addBookmark] Adding bookmark for manga: $mangaId');
    
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'mangaId': mangaId,
        }),
      ).timeout(const Duration(seconds: 15));

      print('[ApiService.addBookmark] Response status: ${response.statusCode}');
      print('[ApiService.addBookmark] Response body: ${response.body}');

      final decodedResponse = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return decodedResponse;
      } else {
        final errorMessage = decodedResponse['message'] ?? 'Failed to add bookmark';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[ApiService.addBookmark] Error: $e');
      rethrow;
    }
  }

  // Delete bookmark
  Future<Map<String, dynamic>> deleteBookmark({
    required String token,
    required String mangaId,
  }) async {
    final uri = Uri.parse('$_baseUrl/user/bookmarks/$mangaId');
    
    print('[ApiService.deleteBookmark] Deleting bookmark for manga: $mangaId');
    
    try {
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('[ApiService.deleteBookmark] Response status: ${response.statusCode}');
      print('[ApiService.deleteBookmark] Response body: ${response.body}');

      final decodedResponse = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return decodedResponse;
      } else {
        final errorMessage = decodedResponse['message'] ?? 'Failed to delete bookmark';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[ApiService.deleteBookmark] Error: $e');
      rethrow;
    }
  }

  // PROFILE UPDATE METHOD
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? username,
    String? profileImageUrl,
  }) async {
    final uri = Uri.parse('$_baseUrl/user/profile');
    
    final Map<String, dynamic> requestBody = {};
    if (username != null && username.trim().isNotEmpty) {
      requestBody['username'] = username.trim();
    }
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      requestBody['profile_image_url'] = profileImageUrl;
    }

    print('[ApiService.updateProfile] Endpoint: $uri');
    print('[ApiService.updateProfile] Request body: $requestBody');
    
    try {
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('[ApiService.updateProfile] Response status: ${response.statusCode}');
      print('[ApiService.updateProfile] Response body: ${response.body}');

      final decodedResponse = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return decodedResponse;
      } else {
        final errorMessage = decodedResponse['message'] ?? 'Failed to update profile';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[ApiService.updateProfile] Error: $e');
      rethrow;
    }
  }

  Future<PaginatedComicsResponse> getLatestComics({int page = 1, int limit = 10}) async {
    final uri = Uri.parse('$_baseUrl/manga/latest?page=$page&limit=$limit');
    print('[ApiService.getLatestComics] Fetching from: $uri');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        if (decodedJson is Map<String, dynamic>) {
            return PaginatedComicsResponse.fromJson(decodedJson);
        } else {
            print('[ApiService.getLatestComics] Error: Expected a Map but got ${decodedJson.runtimeType}');
            throw Exception('Invalid JSON format for latest comics');
        }
      } else {
        print('[ApiService.getLatestComics] Failed: ${response.statusCode} Body: ${response.body}');
        throw Exception('Failed to load latest comics (${response.statusCode})');
      }
    } catch (e) {
      print('[ApiService.getLatestComics] Error: $e');
      rethrow;
    }
  }

  Future<PaginatedComicsResponse> getPopularComics({int page = 1, int limit = 10}) async {
    final uri = Uri.parse('$_baseUrl/manga/popular?page=$page&limit=$limit');
    print('[ApiService.getPopularComics] Fetching from: $uri');
     try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        if (decodedJson is Map<String, dynamic>) {
            return PaginatedComicsResponse.fromJson(decodedJson);
        } else {
            print('[ApiService.getPopularComics] Error: Expected a Map but got ${decodedJson.runtimeType}');
            throw Exception('Invalid JSON format for popular comics');
        }
      } else {
        print('[ApiService.getPopularComics] Failed: ${response.statusCode} Body: ${response.body}');
        throw Exception('Failed to load popular comics (${response.statusCode})');
      }
    } catch (e) {
      print('[ApiService.getPopularComics] Error: $e');
      rethrow;
    }
  }
  
  Future<GenresResponse> getGenres() async {
    final uri = Uri.parse('$_baseUrl/manga/genres');
    print('[ApiService.getGenres] Fetching from: $uri');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        if (decodedJson is Map<String, dynamic>) {
            return GenresResponse.fromJson(decodedJson);
        } else {
            print('[ApiService.getGenres] Error: Expected a Map but got ${decodedJson.runtimeType}');
            throw Exception('Invalid JSON format for genres');
        }
      } else {
        print('[ApiService.getGenres] Failed: ${response.statusCode} Body: ${response.body}');
        throw Exception('Failed to load genres (${response.statusCode})');
      }
    } catch (e) {
      print('[ApiService.getGenres] Error: $e');
      rethrow;
    }
  }

  Future<ChaptersResponse> getMangaChapters(String mangaId, {int limit = 5000, int offset = 0, String? lang}) async {
    String url = '$_baseUrl/manga/$mangaId/feed?limit=$limit&offset=$offset';
    if (lang != null && lang.isNotEmpty) {
      url += '&lang=$lang';
    }
    final uri = Uri.parse(url);
    print('[ApiService.getMangaChapters] Fetching chapters from: $uri');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        if (decodedJson is Map<String, dynamic>) {
            return ChaptersResponse.fromJson(decodedJson);
        } else {
            print('[ApiService.getMangaChapters] Error: Expected a Map for ChaptersResponse but got ${decodedJson.runtimeType}');
            throw Exception('Invalid JSON format for manga chapters');
        }
      } else {
        print('[ApiService.getMangaChapters] Failed for manga $mangaId: ${response.statusCode} Body: ${response.body}');
        throw Exception('Failed to load chapters for manga $mangaId (${response.statusCode})');
      }
    } catch (e) {
      print('[ApiService.getMangaChapters] Error for manga $mangaId: $e');
      rethrow;
    }
  }

  Future<ChapterPagesData> getPagesForChapter(String chapterId) async {
    final uri = Uri.parse('$_baseUrl/chapters/$chapterId/pages');
    print('[ApiService.getPagesForChapter] Fetching from: $uri');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 25));
        print('[ApiService.getPagesForChapter] Response Status Code: ${response.statusCode}');
      print('[ApiService.getPagesForChapter] Response Body RAW: ${response.body}');
      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        if (decodedJson is Map<String, dynamic>) {
            return ChapterPagesData.fromJson(decodedJson);
        } else {
            print('[ApiService.getPagesForChapter] Error: Expected a Map for ChapterPagesData but got ${decodedJson.runtimeType}');
            throw Exception('Invalid JSON format for chapter pages');
        }
      } else {
        print('[ApiService.getPagesForChapter] Failed for chapter $chapterId: ${response.statusCode} Body: ${response.body}');
        throw Exception('Failed to load pages for chapter $chapterId (${response.statusCode})');
      }
    } catch (e) {
      print('[ApiService.getPagesForChapter] Error for chapter $chapterId: $e');
      rethrow;
    }
  }

  Future<PaginatedComicsResponse> searchComicsByGenre(String genreId, {int page = 1, int limit = 20}) async {
    final uri = Uri.parse('$_baseUrl/manga/search/genre?genreIds=$genreId&page=$page&limit=$limit');
    print('[ApiService.searchComicsByGenre] Fetching from: $uri');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        if (decodedJson is Map<String, dynamic>) {
            return PaginatedComicsResponse.fromJson(decodedJson);
        } else {
            print('[ApiService.searchComicsByGenre] Error: Expected a Map but got ${decodedJson.runtimeType}');
            throw Exception('Invalid JSON format for search comics by genre');
        }
      } else {
         print('[ApiService.searchComicsByGenre] Failed: ${response.statusCode} Body: ${response.body}');
        throw Exception('Failed to search comics by genre (${response.statusCode})');
      }
    } catch (e) {
      print('[ApiService.searchComicsByGenre] Error: $e');
      rethrow;
    }
  }

  Future<PaginatedComicsResponse> searchComicsByTitle(String title, {int page = 1, int limit = 10}) async {
    final uri = Uri.parse('$_baseUrl/manga/search/title?title=${Uri.encodeComponent(title)}&page=$page&limit=$limit');
    print('[ApiService.searchComicsByTitle] Fetching from: $uri');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        if (decodedJson is Map<String, dynamic>) {
            return PaginatedComicsResponse.fromJson(decodedJson);
        } else {
            print('[ApiService.searchComicsByTitle] Error: Expected a Map but got ${decodedJson.runtimeType}');
            throw Exception('Invalid JSON format for search comics by title');
        }
      } else {
         print('[ApiService.searchComicsByTitle] Failed: ${response.statusCode} Body: ${response.body}');
        throw Exception('Failed to search comics by title (${response.statusCode})');
      }
    } catch (e) {
      print('[ApiService.searchComicsByTitle] Error: $e');
      rethrow;
    }
  }

  Future<PaginatedComicsResponse> searchComicsByTitleAndGenre(
    String title, 
    String genreId, 
    {int page = 1, int limit = 10}
  ) async {
    final uri = Uri.parse('$_baseUrl/manga/search/combined?title=${Uri.encodeComponent(title)}&genreIds=$genreId&page=$page&limit=$limit');
    print('[ApiService.searchComicsByTitleAndGenre] Fetching from: $uri');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        if (decodedJson is Map<String, dynamic>) {
            return PaginatedComicsResponse.fromJson(decodedJson);
        } else {
            print('[ApiService.searchComicsByTitleAndGenre] Error: Expected a Map but got ${decodedJson.runtimeType}');
            throw Exception('Invalid JSON format for search comics by title and genre');
        }
      } else {
         print('[ApiService.searchComicsByTitleAndGenre] Failed: ${response.statusCode} Body: ${response.body}');
        throw Exception('Failed to search comics by title and genre (${response.statusCode})');
      }
    } catch (e) {
      print('[ApiService.searchComicsByTitleAndGenre] Error: $e');
      rethrow;
    }
  }
}