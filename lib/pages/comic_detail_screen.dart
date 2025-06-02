// lib/pages/comic_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add provider import
import 'package:komik_in/models/comic_model.dart';
import 'package:komik_in/models/chapter_model.dart';
import 'package:komik_in/services/api_service.dart';
import 'package:komik_in/providers/auth_provider.dart'; // Add AuthProvider import
import 'package:cached_network_image/cached_network_image.dart';
import 'package:komik_in/pages/read_screen.dart';

class ComicDetailScreen extends StatefulWidget {
  final Comic comic;

  const ComicDetailScreen({super.key, required this.comic});

  @override
  State<ComicDetailScreen> createState() => _ComicDetailScreenState();
}

class _ComicDetailScreenState extends State<ComicDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<ChaptersResponse> _chaptersFuture;
  
  // Bookmark state variables
  bool _isBookmarked = false;
  bool _isCheckingBookmark = true;
  bool _isBookmarkLoading = false;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = _apiService.getMangaChapters(widget.comic.id, limit: 5000);
    _checkBookmarkStatus();
  }

  // Check if comic is already bookmarked
  Future<void> _checkBookmarkStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token == null) {
      setState(() {
        _isCheckingBookmark = false;
        _isBookmarked = false;
      });
      return;
    }

    try {
      print('[ComicDetail] Checking bookmark status for: ${widget.comic.id}');
      
      // Get first page of bookmarks to check if this comic is bookmarked
      final response = await _apiService.getBookmarks(
        token: authProvider.token!,
        page: 1,
        limit: 100, // Get more items to check
      );

      final bookmarks = response['data'] as List<dynamic>? ?? [];
      final isBookmarked = bookmarks.any((bookmark) => 
        bookmark['manga_id'] == widget.comic.id
      );

      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
          _isCheckingBookmark = false;
        });
        
        print('[ComicDetail] Bookmark status: $_isBookmarked');
      }
    } catch (e) {
      print('[ComicDetail] Error checking bookmark status: $e');
      if (mounted) {
        setState(() {
          _isCheckingBookmark = false;
          _isBookmarked = false;
        });
      }
    }
  }

  // Toggle bookmark status
  Future<void> _toggleBookmark() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to bookmark comics'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isBookmarkLoading = true;
    });

    try {
      if (_isBookmarked) {
        // Remove bookmark
        print('[ComicDetail] Removing bookmark for: ${widget.comic.id}');
        await _apiService.deleteBookmark(
          token: authProvider.token!,
          mangaId: widget.comic.id,
        );
        
        if (mounted) {
          setState(() {
            _isBookmarked = false;
            _isBookmarkLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.bookmark_remove, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Removed "${widget.comic.title}" from bookmarks')),
                ],
              ),
              backgroundColor: Colors.orange[600],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Add bookmark
        print('[ComicDetail] Adding bookmark for: ${widget.comic.id}');
        await _apiService.addBookmark(
          token: authProvider.token!,
          mangaId: widget.comic.id,
        );
        
        if (mounted) {
          setState(() {
            _isBookmarked = true;
            _isBookmarkLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.bookmark_add, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Added "${widget.comic.title}" to bookmarks')),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('[ComicDetail] Error toggling bookmark: $e');
      if (mounted) {
        setState(() {
          _isBookmarkLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isBookmarked ? 'remove' : 'add'} bookmark: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.comic.coverUrl,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 280,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 280,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                      ),
                    ),
                  ),
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.0, 0.5, 1.0]
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                  ),
                  
                  // Top action buttons
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        
                        // Bookmark button
                        _buildBookmarkButton(),
                      ],
                    ),
                  ),
                  
                  // Title at bottom
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Text(
                      widget.comic.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 2.0, color: Colors.black54, offset: Offset(1,1))]
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'By ${widget.comic.author}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 15, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<ChaptersResponse>(
                      future: _chaptersFuture,
                      builder: (context, chapterSnapshot) {
                        String totalChaptersDisplay = "...";
                        String languageDisplay = "N/A";

                        if (chapterSnapshot.connectionState == ConnectionState.done) {
                          if (chapterSnapshot.hasData && chapterSnapshot.data != null) {
                            if (chapterSnapshot.data!.chapters.isNotEmpty) {
                              totalChaptersDisplay = chapterSnapshot.data!.chapters.length.toString();
                              languageDisplay = chapterSnapshot.data!.chapters[0].language.toUpperCase();
                            } else {
                              totalChaptersDisplay = "0";
                            }
                          } else if (chapterSnapshot.hasError) {
                             totalChaptersDisplay = "Err"; 
                          }
                        }
                        
                        if (languageDisplay == "N/A" && widget.comic.tags.isNotEmpty) {
                           final langTag = widget.comic.tags.firstWhere(
                               (tag) => tag.toLowerCase().contains("indonesian") || 
                                        tag.toLowerCase().contains("english") || 
                                        tag.toLowerCase().contains("japanese") || 
                                        tag.toLowerCase().contains("korean"), 
                                orElse: () => "N/A"
                           );
                           if (langTag != "N/A") {
                               languageDisplay = langTag.split(" ").firstWhere((s) => s.isNotEmpty, orElse: () => "N/A");
                           }
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _InfoColumn(title: widget.comic.status, subtitle: 'Status'),
                              _InfoColumn(title: totalChaptersDisplay, subtitle: 'Chapters'),
                              _InfoColumn(title: languageDisplay, subtitle: 'Language'),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.comic.description,
                      style: const TextStyle(color: Colors.black87, height: 1.5, fontFamily: 'Poppins', fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                     if (widget.comic.tags.isNotEmpty) ...[
                        const Text(
                          'Tags',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6.0,
                          runSpacing: 4.0,
                          children: widget.comic.tags
                              .map((tag) => Chip(
                                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                                    backgroundColor: Colors.grey[200],
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                     ],
                    const Text(
                      'Chapters',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 8),
                    _buildChapterSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build bookmark button with different states
  Widget _buildBookmarkButton() {
    if (_isCheckingBookmark) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _isBookmarkLoading ? null : _toggleBookmark,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isBookmarked 
              ? Colors.orange[600]?.withOpacity(0.9)
              : Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: _isBookmarkLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
                size: 24,
              ),
      ),
    );
  }

  Widget _buildChapterSection() {
    return FutureBuilder<ChaptersResponse>(
      future: _chaptersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          print('[ComicDetailScreen._buildChapterSection] Error: ${snapshot.error}');
          print('[ComicDetailScreen._buildChapterSection] StackTrace: ${snapshot.stackTrace}');
          return Center(child: Text('Error memuat chapter: ${snapshot.error.toString()}'));
        } else if (snapshot.hasData && snapshot.data != null) {
            if (snapshot.data!.chapters.isNotEmpty) {
              final chapters = snapshot.data!.chapters;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  String chapterDisplay = 'Chapter ${chapter.chapter ?? "N/A"}';
                  if (chapter.title != null && chapter.title!.isNotEmpty) {
                    chapterDisplay += ': ${chapter.title}';
                  }
                  String subtitle = 'Vol. ${chapter.volume ?? "-"} • ${chapter.pages} Halaman • ${chapter.language.toUpperCase()}';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
                    title: Text(chapterDisplay, style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
                    subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins')),
                    trailing: const Icon(Icons.chevron_right, color: Colors.blueAccent),
                    onTap: () {
                      print('Navigasi ke ReadScreen untuk Chapter ID: ${chapter.id}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReadScreen(
                            chapterId: chapter.id,
                            chapterTitle: chapterDisplay,
                            // Kirim data untuk navigasi chapter
                            mangaId: widget.comic.id,
                            allChapters: chapters,
                            currentChapterIndex: index,
                          ),
                        ),
                      );
                    },
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1),
              );
            } else {
              return const Center(child: Text('Tidak ada chapter untuk manga ini.'));
            }
        } else {
          return const Center(child: Text('Gagal memuat chapter atau tidak ada data.'));
        }
      },
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoColumn({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins', fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}