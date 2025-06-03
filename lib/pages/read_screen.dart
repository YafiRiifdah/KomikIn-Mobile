// lib/pages/read_screen.dart - Updated dengan History Save
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:komik_in/models/chapter_pages_model.dart';
import 'package:komik_in/services/api_service.dart';
import 'package:komik_in/models/chapter_model.dart';
import 'package:komik_in/providers/auth_provider.dart';

enum ReadingMode {
  singlePageHorizontal,
  verticalScroll,
}

class ReadScreen extends StatefulWidget {
  final String chapterId;
  final String chapterTitle;
  // Parameter baru untuk navigasi chapter
  final String? mangaId; 
  final List<Chapter>? allChapters; 
  final int? currentChapterIndex;
  // Parameter baru untuk continue dari history
  final int? startPage; // Page terakhir yang dibaca dari history

  const ReadScreen({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
    this.mangaId,
    this.allChapters,
    this.currentChapterIndex,
    this.startPage, // Added untuk history continuation
  });

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Future<ChapterPagesData>? _pagesFuture;
  
  PageController _pageController = PageController();
  int _currentPageIndex = 0;
  int _totalPages = 0;
  List<String> _imageUrls = [];

  bool _showControls = true;
  ReadingMode _currentReadingMode = ReadingMode.singlePageHorizontal;
  Color _backgroundColor = Colors.black;
  double _sliderValue = 0;
  bool _isSliderInteracting = false;

  // Chapter navigation
  bool _hasNextChapter = false;
  bool _hasPreviousChapter = false;
  bool _isLoadingNewChapter = false;

  // Animation controllers
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  // History tracking
  Timer? _historySaveTimer;
  bool _isHistorySaved = false;
  int _lastSavedPage = -1;
  
  // Cache AuthProvider untuk avoid context access di dispose
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    _fetchPages();
    _pageController.addListener(_pageViewListener);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeOut,
    );
    _controlsAnimationController.forward(); 

    _initializeChapterNavigation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache AuthProvider reference untuk avoid context access di dispose
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  void _pageViewListener() {
    if (_pageController.hasClients && _pageController.page != null && !_isSliderInteracting) {
      final newPage = _pageController.page!.round();
      if (newPage != _currentPageIndex) {
        if (mounted) {
          setState(() {
            _currentPageIndex = newPage;
            _sliderValue = newPage.toDouble();
          });
        }
        
        // Save history dengan debounce
        _saveHistoryWithDebounce();
        
        print('Halaman saat ini (listener PageView): ${_currentPageIndex + 1}');
      }
    }
  }

  // Method untuk save history dengan debounce
  void _saveHistoryWithDebounce() {
    // Cancel timer sebelumnya jika ada
    _historySaveTimer?.cancel();
    
    // Set timer baru dengan delay 2 detik
    _historySaveTimer = Timer(const Duration(seconds: 2), () {
      _saveHistory();
    });
  }

  // Method untuk save history
  Future<void> _saveHistory() async {
    // Cek apakah sudah pernah save di page yang sama
    if (_lastSavedPage == _currentPageIndex || widget.mangaId == null) {
      return;
    }

    if (_authProvider?.token == null) {
      print('[ReadScreen] No token available for saving history');
      return;
    }

    try {
      print('[ReadScreen] Saving history: Page ${_currentPageIndex + 1}/${_totalPages}');
      
      await _apiService.addHistory(
        token: _authProvider!.token!,
        mangaId: widget.mangaId!,
        chapterId: widget.chapterId,
        lastPage: _currentPageIndex,
      );
      
      if (mounted) {
        setState(() {
          _isHistorySaved = true;
          _lastSavedPage = _currentPageIndex;
        });
      }
      
      print('[ReadScreen] History saved successfully: Page ${_currentPageIndex + 1}');
    } catch (e) {
      print('[ReadScreen] Failed to save history: $e');
      // Don't show error to user, just log it
    }
  }

  // Method untuk force save history (dipanggil saat dispose/pindah chapter)
  Future<void> _forceSaveHistory() async {
    if (widget.mangaId == null || _authProvider?.token == null) return;

    try {
      await _apiService.addHistory(
        token: _authProvider!.token!,
        mangaId: widget.mangaId!,
        chapterId: widget.chapterId,
        lastPage: _currentPageIndex,
      );
      
      print('[ReadScreen] Force saved history: Page ${_currentPageIndex + 1}');
    } catch (e) {
      print('[ReadScreen] Failed to force save history: $e');
    }
  }

  @override
  void dispose() {
    // Cancel timer terlebih dahulu
    _historySaveTimer?.cancel();
    
    // Save history menggunakan cached AuthProvider (no context access)
    if (widget.mangaId != null && _authProvider?.token != null) {
      // Fire and forget - no await to avoid blocking dispose
      _forceSaveHistory().catchError((e) {
        print('[ReadScreen] Error in dispose force save: $e');
      });
    }
    
    _pageController.removeListener(_pageViewListener);
    _pageController.dispose();
    _controlsAnimationController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _fetchPages() {
    if (mounted) {
      setState(() {
        // Reset state sebelum fetch baru
        _imageUrls = [];
        _totalPages = 0;
        _currentPageIndex = 0;
        _sliderValue = 0;
        _isLoadingNewChapter = false;
        _isHistorySaved = false;
        _lastSavedPage = -1;
        _pagesFuture = _apiService.getPagesForChapter(widget.chapterId);
      });
    }
  }

  void _updatePageData(ChapterPagesData data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final urls = data.getFullPageUrls();
        if (_totalPages != urls.length || _imageUrls.isEmpty || !listEquals(_imageUrls, urls)) {
           setState(() {
            _imageUrls = urls;
            _totalPages = _imageUrls.length;
            
            // Set initial page dari history jika ada
            if (widget.startPage != null && widget.startPage! < _totalPages) {
              _currentPageIndex = widget.startPage!;
            } else if (_currentPageIndex >= _totalPages && _totalPages > 0) {
                _currentPageIndex = _totalPages -1;
            } else if (_totalPages == 0) {
                _currentPageIndex = 0;
            }
            
            _sliderValue = _currentPageIndex.toDouble(); 
          });
          
          // Navigate ke page yang sesuai jika ada startPage
          if (widget.startPage != null && widget.startPage! < _totalPages && _totalPages > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pageController.hasClients) {
                _pageController.jumpToPage(widget.startPage!);
              }
            });
          }
          
          // Save history untuk page pertama setelah load
          if (_totalPages > 0) {
            _saveHistoryWithDebounce();
          }
        }
      }
    });
  }

  void _toggleControls() {
    if (mounted) {
      setState(() {
        _showControls = !_showControls;
        if (_showControls) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          _controlsAnimationController.forward();
        } else {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          _controlsAnimationController.reverse();
        }
      });
    }
  }

  void _navigateToPage(int pageIndex) {
    if (_currentReadingMode == ReadingMode.singlePageHorizontal && pageIndex >= 0 && pageIndex < _totalPages) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _initializeChapterNavigation() {
    if (widget.allChapters != null && widget.currentChapterIndex != null) {
      if (mounted) {
        setState(() {
          _hasPreviousChapter = widget.currentChapterIndex! > 0;
          _hasNextChapter = widget.currentChapterIndex! < widget.allChapters!.length - 1;
        });
      }
    }
  }

  void _navigateToChapter(bool next) async {
    if (_isLoadingNewChapter || !mounted) return;
    
    if (widget.allChapters == null || widget.currentChapterIndex == null || widget.mangaId == null) {
      _showSnackBar('Informasi navigasi chapter tidak lengkap.');
      return;
    }

    int targetIndex;
    if (next) {
      if (!_hasNextChapter) {
        _showSnackBar('Ini adalah chapter terakhir.');
        return;
      }
      targetIndex = widget.currentChapterIndex! + 1;
    } else {
      if (!_hasPreviousChapter) {
        _showSnackBar('Ini adalah chapter pertama.');
        return;
      }
      targetIndex = widget.currentChapterIndex! - 1;
    }

    if (mounted) setState(() => _isLoadingNewChapter = true);

    // Save history sebelum pindah chapter (dengan mounted check)
    if (mounted) {
      await _forceSaveHistory();
    }

    try {
      final targetChapter = widget.allChapters![targetIndex]; 
      
      if (!mounted) return;
      
      // Menggunakan pushReplacement agar tidak menumpuk halaman ReadScreen di stack navigasi
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ReadScreen(
            chapterId: targetChapter.id, 
            chapterTitle: _getChapterTitle(targetChapter),
            mangaId: widget.mangaId,
            allChapters: widget.allChapters,
            currentChapterIndex: targetIndex,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = next ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
            var end = Offset.zero;
            var curve = Curves.easeOutQuint; 
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } catch (e) {
      print("Error navigating to chapter: $e");
      if (mounted) setState(() => _isLoadingNewChapter = false);
      _showSnackBar('Error memuat chapter baru: $e');
    }
  }

  String _getChapterTitle(Chapter chapterData) {
     return 'Chapter ${chapterData.chapter ?? "N/A"}${chapterData.title != null && chapterData.title!.isNotEmpty ? ": ${chapterData.title}" : ""}';
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.grey[850]?.withOpacity(0.95),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.fromLTRB(15, 5, 15, (_showControls && _totalPages > 0 && _currentReadingMode == ReadingMode.singlePageHorizontal) ? 120 : 15),
        ),
      );
    }
  }

  void _showReadingSettings() {
    // Simpan background sementara untuk preview
    Color tempBackground = _backgroundColor;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) { 
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40, height: 5,
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const Text('Pengaturan Pembacaan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        
                        Text('Mode Baca', style: TextStyle(color: Colors.grey[300], fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModeButton(
                                'Geser (Horizontal)', Icons.swipe_rounded,
                                _currentReadingMode == ReadingMode.singlePageHorizontal,
                                () {
                                  setState(() => _currentReadingMode = ReadingMode.singlePageHorizontal);
                                  setModalState(() {}); 
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModeButton(
                                'Gulir (Vertikal)', Icons.view_day_rounded,
                                _currentReadingMode == ReadingMode.verticalScroll,
                                () {
                                  setState(() => _currentReadingMode = ReadingMode.verticalScroll);
                                  setModalState(() {}); 
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        Text('Warna Latar', style: TextStyle(color: Colors.grey[300], fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        
                        // Preview background
                        Container(
                          width: double.infinity,
                          height: 60,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: tempBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[600]!, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              'Preview Latar Belakang',
                              style: TextStyle(
                                color: tempBackground == Colors.white ? Colors.black : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildColorButton(Colors.black, 'Hitam', tempBackground, (color) {
                                tempBackground = color;
                                setState(() => _backgroundColor = color);
                                setModalState(() {});
                              }),
                              const SizedBox(width: 16),
                              _buildColorButton(Colors.grey[900]!, 'Abu Gelap', tempBackground, (color) {
                                tempBackground = color;
                                setState(() => _backgroundColor = color);
                                setModalState(() {});
                              }),
                              const SizedBox(width: 16),
                              _buildColorButton(const Color(0xFFF0F0F0), 'Putih Abu', tempBackground, (color) {
                                tempBackground = color;
                                setState(() => _backgroundColor = color);
                                setModalState(() {});
                              }),
                              const SizedBox(width: 16),
                              _buildColorButton(Colors.white, 'Putih', tempBackground, (color) {
                                tempBackground = color;
                                setState(() => _backgroundColor = color);
                                setModalState(() {});
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChapterList() {
    if (widget.allChapters == null || widget.allChapters!.isEmpty) {
      _showSnackBar('Daftar chapter tidak tersedia');
      return;
    }

    // Save history sebelum membuka chapter list
    _forceSaveHistory();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Handle bar and header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Chapter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.allChapters!.length} Chapter',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Chapter list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.allChapters!.length,
                    itemBuilder: (context, index) {
                      final chapter = widget.allChapters![index];
                      final isCurrentChapter = index == widget.currentChapterIndex;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrentChapter 
                              ? Colors.blue[600]!.withOpacity(0.2)
                              : Colors.grey[800]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrentChapter 
                              ? Border.all(color: Colors.blue[600]!, width: 1)
                              : null,
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCurrentChapter 
                                  ? Colors.blue[600]
                                  : Colors.grey[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            _getChapterTitle(chapter),
                            style: TextStyle(
                              color: isCurrentChapter ? Colors.blue[300] : Colors.white,
                              fontWeight: isCurrentChapter ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isCurrentChapter 
                              ? Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.blue[400],
                                  size: 20,
                                )
                              : Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.grey[500],
                                  size: 16,
                                ),
                          onTap: isCurrentChapter ? null : () async {
                            Navigator.pop(context); // Close bottom sheet first
                            
                            // Save history sebelum pindah chapter
                            await _forceSaveHistory();
                            
                            // Navigate to selected chapter
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => ReadScreen(
                                  chapterId: chapter.id,
                                  chapterTitle: _getChapterTitle(chapter),
                                  mangaId: widget.mangaId,
                                  allChapters: widget.allChapters,
                                  currentChapterIndex: index,
                                ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: index > (widget.currentChapterIndex ?? 0) 
                                          ? const Offset(1.0, 0.0) 
                                          : const Offset(-1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut,
                                    )),
                                    child: child,
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 300),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeButton(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.blue[400]!, width: 1.5) : null,
          boxShadow: isSelected ? [
            BoxShadow(color: Colors.blue[700]!.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[400], size: 26),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color, String label, Color currentBackground, Function(Color) onColorChanged) {
    bool isSelected = currentBackground == color;
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blueAccent[100]! : (color == Colors.white ? Colors.grey[500]! : Colors.transparent),
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected ? [
                 BoxShadow(color: Colors.blueAccent[100]!.withOpacity(0.5), blurRadius: 5)
              ] : [
                 BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2, offset: const Offset(1,1))
              ]
            ),
            child: isSelected 
              ? Icon(Icons.check, color: color == Colors.white ? Colors.black : Colors.white, size: 22)
              : null,
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: _backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50, height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent[100]!),
              ),
            ),
            const SizedBox(height: 20),
            Text('Memuat halaman...', style: TextStyle(color: _backgroundColor == Colors.black ? Colors.grey[400] : Colors.grey[700], fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      color: _backgroundColor,
      padding: const EdgeInsets.all(20),
      child: Center( 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent[100], size: 60),
            const SizedBox(height: 20),
            Text('Gagal Memuat Halaman', style: TextStyle(color: _backgroundColor == Colors.black ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(error, style: TextStyle(color: _backgroundColor == Colors.black ? Colors.grey[400] : Colors.grey[700], fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent[100], foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Coba Lagi", style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: _fetchPages, 
            )
          ],
        ),
      )
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: _backgroundColor.withOpacity(0.5),
      child: Center(
        child: SizedBox(
          width: 30, height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[500]!),
          ),
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: _backgroundColor.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.grey[600], size: 50),
            const SizedBox(height: 8),
            Text('Gagal memuat', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderWidget() {
    if (_imageUrls.isEmpty) {
      return Center(child: Text(_totalPages > 0 ? 'Memuat gambar...' : 'Tidak ada halaman.', style: TextStyle(color: Colors.grey[400], fontSize: 16)));
    }

    switch (_currentReadingMode) {
      case ReadingMode.singlePageHorizontal:
        return PageView.builder(
          controller: _pageController,
          itemCount: _imageUrls.length,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              panEnabled: true, minScale: 1.0, maxScale: 5.0,
              child: CachedNetworkImage(
                imageUrl: _imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => _buildImagePlaceholder(),
                errorWidget: (context, url, error) => _buildImageError(),
              ),
            );
          },
        );
      case ReadingMode.verticalScroll:
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _imageUrls.length,
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: _imageUrls[index],
              fit: BoxFit.fitWidth,
              placeholder: (context, url) => AspectRatio(aspectRatio: 3 / 4, child: _buildImagePlaceholder()),
              errorWidget: (context, url, error) => AspectRatio(aspectRatio: 3 / 4, child: _buildImageError()),
            );
          },
        );
    }
  }

  Widget _buildStyledButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? iconColor,
    bool isActive = false,
  }) {
    final bool isEnabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isActive ? Colors.blue[700]!.withOpacity(0.3) : Colors.transparent,
        ),
        child: Icon(
          icon, 
          color: isEnabled 
              ? (iconColor ?? Colors.white.withOpacity(0.9))
              : Colors.grey[700],
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _showControls ? PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(_controlsAnimation),
          child: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () {
                // Save history sebelum keluar dengan safe context access
                if (mounted && widget.mangaId != null && _authProvider?.token != null) {
                  _forceSaveHistory().then((_) {
                    if (mounted) Navigator.of(context).pop();
                  }).catchError((e) {
                    print('[ReadScreen] Error saving history on back: $e');
                    if (mounted) Navigator.of(context).pop();
                  });
                } else {
                  if (mounted) Navigator.of(context).pop();
                }
              },
              tooltip: 'Kembali',
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.chapterTitle,
                  style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.allChapters != null && widget.currentChapterIndex != null)
                  Text(
                    '${widget.currentChapterIndex! + 1} dari ${widget.allChapters!.length}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[300]),
                  ),
              ],
            ),
            actions: [
              if (_hasPreviousChapter)
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                  onPressed: _isLoadingNewChapter ? null : () => _navigateToChapter(false),
                  tooltip: 'Chapter Sebelumnya',
                ),
              if (_hasNextChapter)
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                  onPressed: _isLoadingNewChapter ? null : () => _navigateToChapter(true),
                  tooltip: 'Chapter Selanjutnya',
                ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.5), Colors.transparent],
                  stops: const [0.0, 0.7, 1.0]
                ),
              ),
            ),
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
        ),
      ) : null,
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleControls,
            onHorizontalDragEnd: (DragEndDetails details) {
              if (_currentReadingMode == ReadingMode.singlePageHorizontal && 
                  widget.allChapters != null && 
                  widget.currentChapterIndex != null && 
                  _totalPages > 0) {
                if (_currentPageIndex == 0 && details.primaryVelocity! > 300 && _hasPreviousChapter) {
                  _navigateToChapter(false);
                } else if (_currentPageIndex == _totalPages - 1 && details.primaryVelocity! < -300 && _hasNextChapter) {
                  _navigateToChapter(true);
                }
              }
            },
            child: FutureBuilder<ChapterPagesData>(
              future: _pagesFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  _updatePageData(snapshot.data!);
                }
                if (snapshot.connectionState == ConnectionState.waiting && _imageUrls.isEmpty) {
                  return _buildLoadingIndicator();
                } else if (snapshot.hasError) {
                  return _buildErrorWidget('Error: ${snapshot.error}');
                } else if (_imageUrls.isNotEmpty) { 
                    return _buildReaderWidget();
                } else if (snapshot.connectionState != ConnectionState.waiting) {
                    return Center(child: Text('Tidak ada halaman untuk chapter ini.', style: TextStyle(color: Colors.grey[400], fontSize: 16)));
                }
                return _buildLoadingIndicator();
              },
            ),
          ),
          if (_isLoadingNewChapter)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.blue[300]),
                      const SizedBox(height: 20),
                      const Text('Memuat Chapter Baru...', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _showControls && _totalPages > 0 ? SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(_controlsAnimation),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.75), Colors.black.withOpacity(0.4), Colors.transparent,],
              stops: const [0.0, 0.4, 0.7, 1.0]
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentReadingMode == ReadingMode.singlePageHorizontal) ...[
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text('Hal:', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.blueAccent[100],
                                inactiveTrackColor: Colors.grey[800],
                                thumbColor: Colors.blueAccent[100],
                                overlayColor: Colors.blueAccent[100]!.withOpacity(0.3),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0, pressedElevation: 8.0),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                                trackHeight: 2.0,
                                valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                                valueIndicatorColor: Colors.blueAccent[100],
                                valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontSize: 10),
                              ),
                              child: Slider(
                                value: _sliderValue,
                                min: 0,
                                max: (_totalPages > 0 ? _totalPages - 1 : 0).toDouble(),
                                divisions: _totalPages > 1 ? _totalPages - 1 : null,
                                label: '${_sliderValue.round() + 1}',
                                onChanged: (double value) {
                                  if (mounted) setState(() { _sliderValue = value; _isSliderInteracting = true; });
                                },
                                onChangeEnd: (double value) { 
                                  if (mounted) setState(() => _isSliderInteracting = false);
                                  _navigateToPage(value.round());
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${_currentPageIndex + 1}/${_totalPages}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8), 
                  ],
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                     decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _buildStyledButton(
                          icon: Icons.skip_previous_rounded,
                          tooltip: 'Chapter Sebelumnya',
                          onPressed: _hasPreviousChapter && !_isLoadingNewChapter ? () => _navigateToChapter(false) : null,
                        ),
                        _buildStyledButton(
                          icon: _currentReadingMode == ReadingMode.singlePageHorizontal 
                              ? Icons.view_day_rounded 
                              : Icons.swipe_rounded,
                          tooltip: _currentReadingMode == ReadingMode.singlePageHorizontal 
                                ? 'Mode Gulir Vertikal' 
                                : 'Mode Geser Halaman',
                          iconColor: Colors.orangeAccent[100],
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _currentReadingMode = _currentReadingMode == ReadingMode.singlePageHorizontal
                                    ? ReadingMode.verticalScroll
                                    : ReadingMode.singlePageHorizontal;
                              });
                            }
                          },
                        ),
                        _buildStyledButton(
                          icon: Icons.format_list_bulleted_rounded,
                          tooltip: 'Daftar Chapter',
                          onPressed: _showChapterList,
                        ),
                        _buildStyledButton(
                          icon: Icons.settings_rounded,
                          tooltip: 'Pengaturan',
                          onPressed: _showReadingSettings,
                        ),
                        _buildStyledButton(
                          icon: Icons.skip_next_rounded,
                          tooltip: 'Chapter Selanjutnya',
                          onPressed: _hasNextChapter && !_isLoadingNewChapter ? () => _navigateToChapter(true) : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ) : null,
    );
  }
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}