// lib/pages/bookmark_screen.dart - Fixed Navigation Version
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:komik_in/providers/auth_provider.dart';
import 'package:komik_in/services/api_service.dart';
import 'package:komik_in/models/bookmark_model.dart';
import 'package:komik_in/models/comic_model.dart';
import 'package:komik_in/pages/comic_detail_screen.dart';
import 'package:komik_in/pages/main_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({Key? key}) : super(key: key);

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  
  List<Bookmark> _bookmarks = [];
  BookmarkPagination? _pagination;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData()) {
        _loadMoreBookmarks();
      }
    }
  }

  bool _hasMoreData() {
    if (_pagination == null) return false;
    return _currentPage < _pagination!.totalPages;
  }

  Future<void> _loadBookmarks() async {
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token == null) {
      _setError('Please login to view bookmarks');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentPage = 1;
    });

    try {
      final response = await _apiService.getBookmarks(
        token: authProvider.token!,
        page: _currentPage,
        limit: _itemsPerPage,
      );

      if (!mounted) return;

      if (response is Map<String, dynamic>) {
        final List<dynamic> bookmarkData = response['data'] as List<dynamic>? ?? [];

        final List<Bookmark> bookmarks = bookmarkData.map<Bookmark>((item) {
          return Bookmark(
            mangaId: item['manga_id']?.toString() ?? '',
            createdAt: item['created_at']?.toString() ?? '',
            title: item['title']?.toString() ?? 'N/A',
            coverUrl: item['coverUrl']?.toString(),
            author: item['author']?.toString() ?? 'N/A',
            status: item['status']?.toString() ?? 'N/A',
          );
        }).toList();

        final paginationData = response['pagination'] as Map<String, dynamic>? ?? {};
        final pagination = BookmarkPagination(
          currentPage: paginationData['currentPage'] ?? 1,
          totalPages: paginationData['totalPages'] ?? 1,
          itemsPerPage: paginationData['itemsPerPage'] ?? _itemsPerPage,
          totalItems: paginationData['totalItems'] ?? bookmarks.length,
        );

        setState(() {
          _bookmarks = bookmarks;
          _pagination = pagination;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        throw Exception('Invalid response format: ${response.runtimeType}');
      }

    } catch (e) {
      if (mounted) {
        _setError('Failed to load bookmarks: ${e.toString()}');
      }
    }
  }

  Future<void> _loadMoreBookmarks() async {
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token == null || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      
      final response = await _apiService.getBookmarks(
        token: authProvider.token!,
        page: nextPage,
        limit: _itemsPerPage,
      );

      if (!mounted) return;

      if (response is Map<String, dynamic>) {
        final List<dynamic> bookmarkData = response['data'] as List<dynamic>? ?? [];

        final List<Bookmark> newBookmarks = bookmarkData.map<Bookmark>((item) {
          return Bookmark(
            mangaId: item['manga_id']?.toString() ?? '',
            createdAt: item['created_at']?.toString() ?? '',
            title: item['title']?.toString() ?? 'N/A',
            coverUrl: item['coverUrl']?.toString(),
            author: item['author']?.toString() ?? 'N/A',
            status: item['status']?.toString() ?? 'N/A',
          );
        }).toList();

        final paginationData = response['pagination'] as Map<String, dynamic>? ?? {};
        final pagination = BookmarkPagination(
          currentPage: paginationData['currentPage'] ?? nextPage,
          totalPages: paginationData['totalPages'] ?? 1,
          itemsPerPage: paginationData['itemsPerPage'] ?? _itemsPerPage,
          totalItems: paginationData['totalItems'] ?? 0,
        );
        
        setState(() {
          _bookmarks.addAll(newBookmarks);
          _pagination = pagination;
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      } else {
        throw Exception('Invalid response format for load more');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more bookmarks: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token == null) return;

    try {
      await _apiService.deleteBookmark(
        token: authProvider.token!,
        mangaId: bookmark.mangaId,
      );

      if (mounted) {
        setState(() {
          _bookmarks.removeWhere((b) => b.mangaId == bookmark.mangaId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Removed "${bookmark.title}" from bookmarks')),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove bookmark: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Bookmark bookmark) async {
    if (!mounted) return;
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Bookmark'),
        content: Text(
          'Are you sure you want to remove "${bookmark.title}" from your bookmarks?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      _deleteBookmark(bookmark);
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = message;
    });
  }

  void _navigateToComicDetail(Bookmark bookmark) {
    if (!mounted) return;
    
    final comic = Comic(
      id: bookmark.mangaId,
      title: bookmark.title,
      coverUrl: bookmark.coverUrl ?? '',
      author: bookmark.author,
      artist: bookmark.author,
      status: bookmark.status,
      description: '',
      tags: const [],
      year: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicDetailScreen(comic: comic),
      ),
    );
  }

  // Safe navigation back method - Always go to main screen
  void _handleBackPress() {
    if (!mounted) return;
    
    // Direct navigation to MainScreen widget (most reliable)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  // Safe explore navigation method - Go to main screen
  void _handleExplorePress() {
    if (!mounted) return;
    
    // Direct navigation to MainScreen widget
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleBackPress();
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'My Bookmarks',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _handleBackPress,
          ),
          actions: [
            if (_bookmarks.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadBookmarks,
                tooltip: 'Refresh',
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadBookmarks,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_hasError) {
      return _buildErrorState();
    }
    
    if (_bookmarks.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildBookmarkList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading bookmarks...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBookmarks,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Bookmarks Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start exploring comics and bookmark your favorites to see them here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleExplorePress,
              icon: const Icon(Icons.explore),
              label: const Text('Explore Comics'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkList() {
    return Column(
      children: [
        // Stats header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.bookmark, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                '${_pagination?.totalItems ?? _bookmarks.length} Bookmarks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
        
        // Bookmark list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _bookmarks.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _bookmarks.length) {
                return _buildLoadingMoreIndicator();
              }
              
              final bookmark = _bookmarks[index];
              return _buildBookmarkCard(bookmark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildBookmarkCard(Bookmark bookmark) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: InkWell(
      onTap: () => _navigateToComicDetail(bookmark),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Cover image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 80,
                color: Colors.grey[200],
                child: bookmark.coverUrl != null && bookmark.coverUrl!.isNotEmpty
                    ? Image.network(
                        bookmark.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          );
                        },
                      )
                    : Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[600],
                        size: 24,
                      ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Comic info - Alternative layout with status and date stacked
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookmark.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Author: ${bookmark.author}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Status on separate line
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(bookmark.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bookmark.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(bookmark.status),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Date on separate line
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(bookmark.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Delete button
            IconButton(
              onPressed: () => _showDeleteConfirmation(bookmark),
              icon: Icon(
                Icons.bookmark_remove,
                color: Colors.red[400],
              ),
              tooltip: 'Remove bookmark',
            ),
          ],
        ),
      ),
    ),
  );
}

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'hiatus':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} weeks ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}