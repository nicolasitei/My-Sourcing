import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
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
    print("📦 Démarrage export Excel...");

    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Supprimer la feuille par défaut
    final sheet = excel['Export']; // TODO : Renommer la feuille Sheet 1

    final headers = fields.map((f) => TextCellValue(f.label)).toList()..add(TextCellValue('Date'));
    sheet.appendRow(headers);

    for (var entry in entries) {
      final row =
          fields.map<CellValue?>((f) {
            final value = entry[f.label];
            return TextCellValue(value?.toString() ?? '');
          }).toList();

      final submittedAt = entry['submittedAt']?.toDate().toString() ?? '';
      row.add(TextCellValue(submittedAt));
      sheet.appendRow(row);
    }

    final dir = await getApplicationDocumentsDirectory();
    final filename = '${formTitle.replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${dir.path}/$filename';
    print("📂 Enregistrement dans : $filePath");

    final fileBytes = excel.encode();
    if (fileBytes == null) throw Exception("Échec de l'encodage du fichier Excel.");

    final file =
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

    print("✅ Export terminé avec succès.");
  } catch (e) {
    print("❌ Erreur export Excel : $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'export : $e")));
    }
  }
}
