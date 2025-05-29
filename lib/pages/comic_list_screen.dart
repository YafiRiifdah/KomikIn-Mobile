import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/comic_card.dart';
import '../widgets/search_filter.dart';
import '../pages/comic_detail_screen.dart';
import '../services/api_service.dart';
import '../models/comic_model.dart';
import '../models/genre_model.dart';

class ComicListScreen extends StatefulWidget {
  final String category; // 'latest' atau 'popular'
  final String title;
  final String? searchQuery;
  final String? genreId;
  final List<Genre>? genres;

  const ComicListScreen({
    super.key,
    required this.category,
    required this.title,
    this.searchQuery,
    this.genreId,
    this.genres,
  });

  @override
  State<ComicListScreen> createState() => _ComicListScreenState();
}

class _ComicListScreenState extends State<ComicListScreen> {
  final ApiService _apiService = ApiService();
  List<Comic> _comics = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLastPage = false;
  final int _limit = 20; // Lebih banyak untuk GridView
  final ScrollController _scrollController = ScrollController();

  // Search and filter for 'latest' category
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedGenreId = "";
  String _selectedGenreName = "All";
  bool _isSearchActive = false;
  Timer? _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.searchQuery ?? "";
    _selectedGenreId = widget.genreId ?? "";
    _selectedGenreName = widget.genres?.firstWhere(
          (g) => g.id == widget.genreId,
          orElse: () => Genre(id: '', name: 'All', group: ''),
        ).name ??
        "All";
    _isSearchActive = _searchQuery.isNotEmpty;
    _searchController.text = _searchQuery;
    _fetchComics(page: 1, isInitialLoad: true);
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        !_isLastPage) {
      _fetchComics(page: _currentPage + 1, isInitialLoad: false);
    }
  }

  void _onSearchChanged() {
    if (_searchDebouncer?.isActive ?? false) _searchDebouncer!.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      final newQuery = _searchController.text.trim();
      if (newQuery != _searchQuery) {
        setState(() {
          _searchQuery = newQuery;
          _isSearchActive = newQuery.isNotEmpty;
        });
        _fetchComics(page: 1, isInitialLoad: true);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = "";
      _isSearchActive = false;
    });
    _fetchComics(page: 1, isInitialLoad: true);
  }

  Future<void> _fetchComics({required int page, bool isInitialLoad = false}) async {
    if (isInitialLoad) {
      if (mounted) setState(() {
        _comics = [];
        _isLoading = true;
        _currentPage = 1;
        _isLastPage = false;
      });
    } else {
      if (mounted) setState(() => _isLoadingMore = true);
    }

    try {
      PaginatedComicsResponse response;
      if (widget.category == 'latest') {
        if (_searchQuery.isNotEmpty && _selectedGenreId.isNotEmpty) {
          response = await _apiService.searchComicsByTitleAndGenre(
            _searchQuery,
            _selectedGenreId,
            page: page,
            limit: _limit,
          );
        } else if (_searchQuery.isNotEmpty) {
          response = await _apiService.searchComicsByTitle(_searchQuery, page: page, limit: _limit);
        } else if (_selectedGenreId.isNotEmpty) {
          response = await _apiService.searchComicsByGenre(_selectedGenreId, page: page, limit: _limit);
        } else {
          response = await _apiService.getLatestComics(page: page, limit: _limit);
        }
      } else {
        response = await _apiService.getPopularComics(page: page, limit: _limit);
      }

      if (mounted) {
        setState(() {
          if (isInitialLoad) {
            _comics = response.comics;
          } else {
            _comics.addAll(response.comics);
          }
          _currentPage = page;
          _totalPages = response.pagination.totalPages;
          _isLastPage = page >= _totalPages;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat komik: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('Error fetching comics (page $page): $e');
    }
  }

  void _onGenreSelected(String genreName) {
    Navigator.pop(context);
    if (genreName == "All") {
      if (mounted) {
        setState(() {
          _selectedGenreName = "All";
          _selectedGenreId = "";
        });
      }
    } else {
      final selectedGenre = widget.genres!.firstWhere(
        (g) => g.name == genreName,
        orElse: () => Genre(id: '', name: 'Unknown', group: ''),
      );
      if (selectedGenre.id.isNotEmpty) {
        if (mounted) {
          setState(() {
            _selectedGenreName = genreName;
            _selectedGenreId = selectedGenre.id;
          });
        }
      }
    }
    _fetchComics(page: 1, isInitialLoad: true);
  }

  void _showGenreFilter() {
    if (widget.genres == null || widget.genres!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daftar genre tidak tersedia.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    List<String> displayGenres = ["All", ...widget.genres!.map((genre) => genre.name)];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SearchFilter(
          genres: displayGenres,
          onSelected: _onGenreSelected,
          selectedGenre: _selectedGenreName,
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
        border: _isSearchActive
            ? Border.all(color: const Color(0xFF2196F3), width: 2)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: _isSearchActive ? const Color(0xFF2196F3) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search comic by title...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
          if (_isSearchActive) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: widget.category == 'latest'
            ? [
                IconButton(
                  icon: Icon(
                    Icons.filter_alt_outlined,
                    color: _selectedGenreName != "All" ? const Color(0xFF1976D2) : Colors.grey,
                  ),
                  onPressed: _showGenreFilter,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          if (widget.category == 'latest') ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchBar(),
            ),
          ],
          Expanded(
            child: _isLoading && _comics.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _comics.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.library_books_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No comics found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try refreshing or check back later',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _fetchComics(page: 1, isInitialLoad: true),
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _comics.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _comics.length && _isLoadingMore) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (index >= _comics.length) {
                              return const SizedBox.shrink();
                            }
                            final comic = _comics[index];
                            return ComicCard(
                              comic: comic,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ComicDetailScreen(comic: comic),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}