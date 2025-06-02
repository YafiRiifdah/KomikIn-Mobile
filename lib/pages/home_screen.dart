import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:komik_in/providers/auth_provider.dart';
import 'package:komik_in/widgets/comic_card.dart';
import 'package:komik_in/widgets/search_filter.dart';
import 'package:komik_in/pages/comic_detail_screen.dart';
import 'package:komik_in/pages/comic_list_screen.dart';
import 'package:komik_in/services/api_service.dart';
import 'package:komik_in/models/comic_model.dart';
import 'package:komik_in/models/genre_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Genre> _fetchedGenres = [];
  String _selectedGenreForFilter = "All";
  String _selectedGenreIdForFilter = "";
  List<Comic> _latestComics = [];
  List<Comic> _popularComics = [];
  bool _isLoadingLatest = true;
  bool _isLoadingPopular = true;
  bool _isLoadingGenres = true;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearchActive = false;
  Timer? _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _fetchInitialComics();
    _fetchGenres();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
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
        _fetchInitialLatestComics();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = "";
      _isSearchActive = false;
    });
    _fetchInitialLatestComics();
  }

  Future<void> _fetchInitialComics() async {
    _fetchInitialLatestComics();
    _fetchInitialPopularComics();
  }

  Future<void> _fetchInitialLatestComics() async {
    if (mounted)
      setState(() {
        _latestComics = [];
        _isLoadingLatest = true;
      });

    try {
      PaginatedComicsResponse response;
      if (_searchQuery.isNotEmpty && _selectedGenreIdForFilter.isNotEmpty) {
        response = await _apiService.searchComicsByTitleAndGenre(
          _searchQuery,
          _selectedGenreIdForFilter,
          page: 1,
          limit: 6,
        );
      } else if (_searchQuery.isNotEmpty) {
        response = await _apiService.searchComicsByTitle(
          _searchQuery,
          page: 1,
          limit: 6,
        );
      } else if (_selectedGenreIdForFilter.isNotEmpty) {
        response = await _apiService.searchComicsByGenre(
          _selectedGenreIdForFilter,
          page: 1,
          limit: 6,
        );
      } else {
        response = await _apiService.getLatestComics(page: 1, limit: 6);
      }

      if (mounted) {
        setState(() {
          _latestComics = response.comics;
          _isLoadingLatest = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLatest = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat komik terbaru: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('Error fetching latest comics: $e');
    }
  }

  Future<void> _fetchInitialPopularComics() async {
    if (mounted)
      setState(() {
        _popularComics = [];
        _isLoadingPopular = true;
      });

    try {
      final response = await _apiService.getPopularComics(page: 1, limit: 6);
      if (mounted) {
        setState(() {
          _popularComics = response.comics;
          _isLoadingPopular = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPopular = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat komik populer: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('Error fetching popular comics: $e');
    }
  }

  Future<void> _fetchGenres() async {
    if (mounted) setState(() => _isLoadingGenres = true);
    try {
      final genresResponse = await _apiService.getGenres();
      if (mounted) {
        setState(() {
          _fetchedGenres = genresResponse.genres;
          _isLoadingGenres = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingGenres = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat genre: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('Error fetching genres: $e');
    }
  }

  void _onGenreSelected(String genreName) {
    Navigator.pop(context);
    if (genreName == "All") {
      if (mounted) {
        setState(() {
          _selectedGenreForFilter = "All";
          _selectedGenreIdForFilter = "";
        });
      }
    } else {
      final selectedGenre = _fetchedGenres.firstWhere(
        (g) => g.name == genreName,
        orElse: () => Genre(id: '', name: 'Unknown', group: ''),
      );
      if (selectedGenre.id.isNotEmpty) {
        if (mounted) {
          setState(() {
            _selectedGenreForFilter = genreName;
            _selectedGenreIdForFilter = selectedGenre.id;
          });
        }
      }
    }
    _fetchInitialLatestComics();
  }

  void _showGenreFilter() {
    if (_isLoadingGenres) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daftar genre masih dimuat...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_fetchedGenres.isEmpty && !_isLoadingGenres) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat genre. Coba lagi nanti.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchGenres();
      return;
    }

    List<String> displayGenres = [
      "All",
      ..._fetchedGenres.map((genre) => genre.name),
    ];

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
          selectedGenre: _selectedGenreForFilter,
        );
      },
    );
  }

  String _getDisplayTitle() {
    if (_isSearchActive && _selectedGenreForFilter != "All") {
      return 'Search: "$_searchQuery" in $_selectedGenreForFilter';
    } else if (_isSearchActive) {
      return 'Search: "$_searchQuery"';
    } else if (_selectedGenreForFilter != "All") {
      return 'Genre: $_selectedGenreForFilter';
    } else {
      return 'Komik Update Terbaru';
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
        border:
            _isSearchActive
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
              onSubmitted: (value) {
                if (value.trim() != _searchQuery) {
                  setState(() {
                    _searchQuery = value.trim();
                    _isSearchActive = _searchQuery.isNotEmpty;
                  });
                  _fetchInitialLatestComics();
                }
              },
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
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    if (!_isSearchActive && _selectedGenreForFilter == "All") {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_isSearchActive)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                border: Border.all(color: const Color(0xFF2196F3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, size: 16, color: Color(0xFF1976D2)),
                  const SizedBox(width: 4),
                  Text(
                    'Search: "$_searchQuery"',
                    style: const TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _clearSearch,
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedGenreForFilter != "All")
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                border: Border.all(color: const Color(0xFF4CAF50)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.category,
                    size: 16,
                    color: Color(0xFF388E3C),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedGenreForFilter,
                    style: const TextStyle(
                      color: Color(0xFF388E3C),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _onGenreSelected("All"),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isLatest) {
    if (isLatest && _isSearchActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No comics found for "$_searchQuery"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2196F3),
                backgroundColor: const Color(0xFFE3F2FD),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Center(
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
              'No ${isLatest ? 'latest' : 'popular'} comics found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try refreshing or check back later',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
  }

  // Helper method untuk mendapatkan display name user
  String _getUserDisplayName(AuthProvider authProvider) {
    // Prioritas: username -> email -> fallback "User"
    if (authProvider.username != null && authProvider.username!.isNotEmpty) {
      return authProvider.username!;
    }
    
    if (authProvider.userEmail != null && authProvider.userEmail!.isNotEmpty) {
      // Ambil bagian sebelum @ dari email
      final emailParts = authProvider.userEmail!.split('@');
      return emailParts.isNotEmpty ? emailParts[0] : 'User';
    }
    
    return 'User';
  }

  // Profile section dengan data dinamis dari AuthProvider
  Widget _buildProfileSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final displayName = _getUserDisplayName(authProvider);
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: authProvider.profileImageUrl != null && 
                                  authProvider.profileImageUrl!.isNotEmpty
                      ? MemoryImage(
                          base64Decode(
                            authProvider.profileImageUrl!.split(',')[1], // Remove data:image/jpeg;base64,
                          ),
                        )
                      : const AssetImage('assets/images/profile.png') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stay trending!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings),
              onSelected: (value) async {
                if (value == 'logout') {
                  // Tampilkan konfirmasi logout
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Konfirmasi'),
                      content: const Text('Apakah Anda yakin ingin keluar?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Keluar'),
                        ),
                      ],
                    ),
                  );
                  
                  if (shouldLogout == true) {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login', 
                        (route) => false,
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 8),
                      Text('Profile (${displayName})'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section - Menggunakan widget terpisah dengan data dinamis
                _buildProfileSection(),
                const SizedBox(height: 20),

                // Search Bar
                _buildSearchBar(),
                const SizedBox(height: 20),

                // Active Filters
                _buildActiveFilters(),

                // Latest Comics Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getDisplayTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color:
                            _selectedGenreForFilter != "All"
                                ? const Color(0xFFE3F2FD)
                                : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: _showGenreFilter,
                        icon: Icon(
                          Icons.filter_alt_outlined,
                          color:
                              _selectedGenreForFilter != "All"
                                  ? const Color(0xFF1976D2)
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ComicListScreen(
                                category: 'latest',
                                title: _getDisplayTitle(),
                                searchQuery: _searchQuery,
                                genreId: _selectedGenreIdForFilter,
                                genres: _fetchedGenres,
                              ),
                        ),
                      );
                    },
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _isLoadingLatest && _latestComics.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _latestComics.isEmpty
                    ? SizedBox(height: 300, child: _buildEmptyState(true))
                    : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                      itemCount: _latestComics.length,
                      itemBuilder: (context, index) {
                        final comic = _latestComics[index];
                        return ComicCard(
                          comic: comic,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ComicDetailScreen(comic: comic),
                              ),
                            );
                          },
                        );
                      },
                    ),

                const SizedBox(height: 24),

                // Popular Comics Section
                const Text(
                  'Komik Populer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const ComicListScreen(
                                category: 'popular',
                                title: 'Komik Populer',
                              ),
                        ),
                      );
                    },
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _isLoadingPopular && _popularComics.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _popularComics.isEmpty
                    ? SizedBox(height: 300, child: _buildEmptyState(false))
                    : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                      itemCount: _popularComics.length,
                      itemBuilder: (context, index) {
                        final comic = _popularComics[index];
                        return ComicCard(
                          comic: comic,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ComicDetailScreen(comic: comic),
                              ),
                            );
                          },
                        );
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}