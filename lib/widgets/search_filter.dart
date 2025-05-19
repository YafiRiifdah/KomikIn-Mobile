import 'package:flutter/material.dart';

class SearchFilter extends StatelessWidget {
  final List<String> genres;
  final void Function(String)? onSelected;

  const SearchFilter({
    super.key,
    required this.genres,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Pilih Genre",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: genres.map((genre) {
              return GestureDetector(
                onTap: () {
                  if (onSelected != null) onSelected!(genre);
                  Navigator.pop(context);
                },
                child: Chip(
                  label: Text(
                    genre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  backgroundColor: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  elevation: 2,
                  shadowColor: Colors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Colors.blue.shade200,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
