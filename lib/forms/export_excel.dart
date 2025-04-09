import 'dart:developer';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mysourcing2/models/supplier_model.dart';
import 'package:mysourcing2/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // Assurez-vous que le bon package est importé
import 'form_model.dart';

Future<void> exportSelectedEntriesToExcel({
  required BuildContext context,
  required String userId,
  required String formId,
  required String formTitle,
  required List<FormFieldData> fields,
  required List<Map<String, dynamic>> entries,
}) async {
  try {
    log("📦 Démarrage export Excel...");

    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Export');

    // Create the header row
    final headers = fields.map((f) => TextCellValue(f.label)).toList();
    headers.add(TextCellValue('Date')); // Ajoutez la colonne de date

    excel.appendRow('Export', headers);

    for (var entry in entries) {
      log('Exporting entry: $entry');

      List<CellValue> row = [];

      for (var field in fields) {
        if (field.type == 'image') {
          final imagePaths = List<String>.from(entry[field.label] ?? []);
          log('Image Paths: $imagePaths');

          // Convert storage paths to downloadable urls
          final imageUrls = imagePaths.map((path) => GetIt.I<StorageService>().getImageUrlFromStoragePath(path)).toList();
          log('Image URLs: $imageUrls');

          final urls = await Future.wait(imageUrls);

          row.add(TextCellValue(urls.toString()));
        } else if (field.type == 'supplier') {
          final value = SupplierModel.fromJson(entry[field.label]);
          row.add(TextCellValue('${value.name}, ${value.description}'));
          log('Updated entry: $entry');
        } else {
          final value = entry[field.label];
          row.add(TextCellValue(value?.toString() ?? ''));
          log('Updated entry: $entry');
        }
      }

      final submittedAt = entry['createdAt']?.toDate().toString() ?? '';
      row.add(TextCellValue(submittedAt));
      excel.appendRow('Export', row);
    }

    final dir = await getApplicationDocumentsDirectory();
    final filename = '${formTitle.replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${dir.path}/$filename';
    log("📂 Enregistrement dans : $filePath");

    final fileBytes = excel.encode();
    if (fileBytes == null) throw Exception("Échec de l'encodage du fichier Excel.");

    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);

    // Utilisez la méthode correcte pour partager le fichier
    Share.shareFiles([filePath], text: 'Voici le fichier Excel exporté : $filename');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exporté et prêt à être partagé : $filename'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    log("✅ Export terminé avec succès.");
  } catch (e) {
    log("❌ Erreur export Excel : $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'export : $e")));
    }
  }
}
