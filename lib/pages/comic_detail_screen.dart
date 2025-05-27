import 'package:flutter/material.dart';
import '../widgets/comic_card.dart';

class ComicDetailScreen extends StatelessWidget {
  final Comic comic;

  const ComicDetailScreen({super.key, required this.comic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: Image.asset(
                      comic.imageAsset,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.transparent,
                          Colors.black45,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul komik
                        Expanded(
                          child: Text(
                            comic.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Icon bookmark
                        IconButton(
                          icon: const Icon(
                            Icons.bookmark_border,
                            color: Colors.blue,
                          ),
                          onPressed: () {},
                        ),
                        // Icon bintang
                        IconButton(
                          icon: const Icon(Icons.star, color: Colors.amber),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'By Chad W. Beckerman',
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _InfoColumn(title: '4.5/5', subtitle: 'Rating'),
                          _InfoColumn(
                            title: '${comic.chapter}',
                            subtitle: 'Chapters',
                          ),
                          _InfoColumn(
                            title: comic.language,
                            subtitle: 'Language',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                      'Suspendisse molestie est nec gravida dictum. Nunc dictum lectus quam, '
                      'non maximus urna ornare sit amet. Aliquam id sapien in massa commodo.',
                      style: TextStyle(
                        color: Colors.black87,
                        height: 1.4,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chapters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildChapterList(comic.chapter),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterList(int totalChapters) {
    final List<Map<String, dynamic>> chapters = List.generate(
      totalChapters.clamp(1, 10),
      (index) => {
        'title': 'Chapter ${index + 1}',
        'pages': 15 + (index * 2) % 10,
      },
    );

    return Column(
      children:
          chapters.map((chapter) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    chapter['title']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${chapter['pages']} Pages',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.menu_book,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoColumn({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
        ),
      ],
    );
  }
}
