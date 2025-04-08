import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mysourcing2/services/storage_service.dart';

class ThumbnailImageRenderer extends StatelessWidget {
  final String storagePath;
  const ThumbnailImageRenderer({super.key, required this.storagePath});

  Future<File?> get future => GetIt.I<StorageService>().getImageFromStoragePath(storagePath);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.data == null) return SizedBox();

        final file = snapshot.data;

        if (file == null) return const SizedBox();

        return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, width: 48, height: 48, fit: BoxFit.cover));
      },
    );
  }
}
