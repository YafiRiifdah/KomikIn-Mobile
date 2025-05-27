import 'package:flutter/material.dart';

class Comic {
  String title;
  String imageAsset;
  String language;
  int chapter;

  Comic({
    required this.title,
    required this.imageAsset,
    required this.language,
    required this.chapter,
  });
}

List<Comic> listComic = [
  Comic(
    title: 'Komi Can\'t Communicate',
    imageAsset: 'assets/images/komi_cant_communicate.jpg',
    language: 'Japanese',
    chapter: 443,
  ),
  Comic(
    title: 'SPY x Family',
    imageAsset: 'assets/images/spy_family.jpg',
    language: 'Japanese',
    chapter: 92,
  ),
  Comic(
    title: 'A Better World',
    imageAsset: 'assets/images/a_better_world.jpg',
    language: 'Korean',
    chapter: 65,
  ),
  Comic(
    title: 'Bad Dreams in the Night',
    imageAsset: 'assets/images/bad_dreams.jpg',
    language: 'English',
    chapter: 6,
  ),
  Comic(
    title: 'Chainsaw Man Vol. 14 - Vol. 16',
    imageAsset: 'assets/images/chainsaw_man.jpg',
    language: 'Japanese',
    chapter: 144,
  ),
  Comic(
    title: 'The Ribbon Queen',
    imageAsset: 'assets/images/the_ribbon_queen.jpg',
    language: 'English',
    chapter: 8,
  ),
  Comic(
    title: 'How It All Ends',
    imageAsset: 'assets/images/how_it_all_ends.jpg',
    language: 'English',
    chapter: 1,
  ),
  Comic(
    title: 'Polar Vortex',
    imageAsset: 'assets/images/polar_vortex.jpg',
    language: 'English',
    chapter: 1,
  ),
  Comic(
    title: 'The Deviant Vol. 1',
    imageAsset: 'assets/images/the_deviant.jpg',
    language: 'English',
    chapter: 9,
  ),
  Comic(
    title: 'How to Baby',
    imageAsset: 'assets/images/how_to_baby.jpg',
    language: 'Japanese',
    chapter: 120,
  ),
  Comic(
    title: 'The King`s Warrior',
    imageAsset: 'assets/images/the_kings_warrior.jpg',
    language: 'Korean',
    chapter: 102,
  ),
];

class ComicCard extends StatelessWidget {
  final Comic comic;
  final VoidCallback? onTap;

  const ComicCard({
    super.key,
    required this.comic,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  comic.imageAsset,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comic.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        comic.language,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Chapter ${comic.chapter}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
