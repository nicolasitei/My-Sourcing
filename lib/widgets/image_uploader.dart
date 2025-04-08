import 'dart:io';

import 'package:flutter/material.dart';

class ImageUploader extends StatelessWidget {
  final List<File> images; // List of images to be displayed, stored locally
  final VoidCallback addImage;
  final Function(int) deleteImage;
  const ImageUploader({super.key, required this.images, required this.addImage, required this.deleteImage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: addImage,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(decoration: BoxDecoration(color: Colors.grey[300]), child: const Icon(Icons.add_a_photo)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ListView.separated(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(decoration: BoxDecoration(color: Colors.grey[300]), child: Image.file(images[index], fit: BoxFit.cover)),

                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => deleteImage(index),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.delete, size: 20, color: Color(0xFF0085AF)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemCount: images.length,
          ),
        ],
      ),
    );
  }
}
