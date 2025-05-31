import 'package:flutter/material.dart';
import '../models/comic_model.dart'; // Impor model Comic yang baru
import 'package:cached_network_image/cached_network_image.dart'; // Impor paket gambar

// HAPUS DEFINISI CLASS COMIC LAMA DAN listComic DARI SINI

class ComicCard extends StatelessWidget {
  final Comic comic; // Gunakan model Comic yang baru
  final VoidCallback? onTap;

  const ComicCard({super.key, required this.comic, this.onTap});

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
                aspectRatio: 16 / 9, // Atau sesuaikan dengan rasio gambar Anda
                child: CachedNetworkImage(
                  imageUrl: comic.coverUrl, // Gunakan coverUrl dari model baru
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
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
                        comic.title, // Gunakan title dari model baru
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2, // Batasi judul agar tidak terlalu panjang
                      ),
                      Text(
                        comic.author, // Gunakan author dari model baru
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Anda bisa menampilkan informasi lain di sini, misalnya tags atau status
                // Untuk 'chapter', model Comic baru kita tidak secara langsung punya info chapter terakhir
                // Anda bisa menambahkannya ke model jika endpoint backend mengembalikannya,
                // atau menampilkannya secara berbeda.
                // Untuk saat ini, kita bisa tampilkan statusnya.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    comic.status,
                    style: TextStyle(
                      color: Colors.blueGrey[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
