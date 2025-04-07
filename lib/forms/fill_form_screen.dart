import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'form_model.dart';
import 'entry_list_screen.dart';
import 'form_service.dart';

class FillFormScreen extends StatefulWidget {
  final String formId;
  final String formTitle;
  final List<FormFieldData> fields;

  const FillFormScreen({
    super.key,
    required this.formId,
    required this.formTitle,
    required this.fields,
  });

  @override
  State<FillFormScreen> createState() => _FillFormScreenState();
}

class _FillFormScreenState extends State<FillFormScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, File?> _updatedImages = {};
  final picker = ImagePicker();

  bool _isSubmitting = false;
  bool _isImageUploadCancelled = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      if (field.type != 'image') {
        _controllers[field.label] = TextEditingController();
      }
    }
  }

  Future<void> _pickImage() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _updatedImages['imageLabel'] = File(pickedFile.path);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission refusée pour accéder à la caméra')),
      );
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
    });

    final entry = <String, dynamic>{};

    try {
      for (final field in widget.fields) {
        if (field.type == 'image') {
          final file = _updatedImages[field.label];
          if (file != null && !_isImageUploadCancelled) {
            final ref = FirebaseStorage.instance
                .ref('form_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
            await ref.putFile(file);
            final url = await ref.getDownloadURL();
            entry[field.label] = url;
          } else {
            entry[field.label] = '';
          }
        } else {
          entry[field.label] = _controllers[field.label]?.text ?? '';
        }
      }

      await FormService().saveEntry(widget.formId, entry);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrée ajoutée avec succès')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EntryListScreen(
            formId: widget.formId,
            formTitle: widget.formTitle,
            fields: widget.fields,
          ),
        ),
      );
    } catch (e) {
      print("❌ Erreur globale : $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la soumission : $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isImageUploadCancelled = false; // Reset the cancellation flag
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un produit")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ListView(
          children: [
            ...widget.fields.map((field) {
              if (field.type == 'image') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${field.label} (image)",
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Prendre une photo"),
                      onPressed: _pickImage,
                    ),
                    const SizedBox(height: 8),
                    if (_updatedImages[field.label] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_updatedImages[field.label]!,
                            height: 120),
                      ),
                    const SizedBox(height: 24),
                  ],
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextField(
                    controller: _controllers[field.label],
                    maxLines: field.type == 'multiline' ? 5 : 1,
                    decoration: InputDecoration(
                      labelText: field.label,
                    ),
                  ),
                );
              }
            }),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.save),
              label: const Text("Sauvegarder"),
            ),
          ],
        ),
      ),
    );
  }
}
