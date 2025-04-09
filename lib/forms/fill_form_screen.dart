import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mysourcing2/models/fournisseur_model.dart';
import 'package:mysourcing2/services/storage_service.dart';
import 'package:mysourcing2/widgets/auto_suggest.dart';
import 'package:mysourcing2/widgets/image_uploader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'form_model.dart';
import 'entry_list_screen.dart';
import 'form_service.dart';

class FillFormScreen extends StatefulWidget {
  final String formId;
  final String formTitle;
  final List<FormFieldData> fields;

  const FillFormScreen({super.key, required this.formId, required this.formTitle, required this.fields});

  @override
  State<FillFormScreen> createState() => _FillFormScreenState();
}

class _FillFormScreenState extends State<FillFormScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final picker = ImagePicker();

  final List<File> _tempFiles = [];

  FournisseurModel? _selectedFournisseur;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      if (field.type != 'image') {
        _controllers[field.label] = TextEditingController();
      }
    }
  }

  Future<void> _addImage() async {
    final status = await Permission.camera.request();

    log("Status de la permission : $status");

    if (status != PermissionStatus.granted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission refusée pour accéder à la caméra')));
      return;
    }

    // Montrer une modalbottomsheet pour choisir entre la caméra et la galerie
    ImageSource? imageSource;

    if (mounted) {
      imageSource = await showModalBottomSheet<ImageSource?>(
        context: context,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Prendre une photo'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo),
                    title: const Text('Choisir dans la galerie'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (imageSource == null) return;

    final pickedFile = await picker.pickImage(source: imageSource);

    if (pickedFile == null) return;

    // Add image to app folder

    setState(() {
      _tempFiles.add(File(pickedFile.path));
    });
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
    });

    final entry = <String, dynamic>{};

    try {
      for (final field in widget.fields) {
        if (field.type == 'image') {
          log("Image field: ${field.label}");

          if (_tempFiles.isNotEmpty) {
            final imagePaths = await _uploadFilesToServer();
            log("Image paths: $imagePaths");
            entry[field.label] = imagePaths;
          } else {
            entry[field.label] = [];
          }
        } else {
          entry[field.label] = _controllers[field.label]?.text ?? '';
        }

        if (field.type == 'fournisseur') {
          entry[field.label] = _selectedFournisseur?.toJson();
        }
      }

      await FormService().saveEntry(widget.formId, entry);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrée ajoutée avec succès')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => EntryListScreen(formId: widget.formId, formTitle: widget.formTitle, fields: widget.fields)),
      );
    } catch (e) {
      log("❌ Erreur globale : $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la soumission : $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  _uploadFilesToServer() async {
    try {
      final newPaths = await GetIt.I<StorageService>().uploadImagesToServer(
        uid: FirebaseAuth.instance.currentUser!.uid,
        formId: widget.formId,
        files: _tempFiles,
      );
      return newPaths;
    } catch (e) {
      log("Erreur lors de l'upload de l'image : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'upload de l'image : $e")));
      }
      rethrow;
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
                    Text("${field.label} (image)", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ImageUploader(
                      images: _tempFiles,
                      addImage: _addImage,
                      deleteImage: (index) {
                        setState(() {
                          _tempFiles.removeAt(index);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              } else if (field.type == 'fournisseur') {
                return AutocompleteTextField(
                  initialValue: _selectedFournisseur,
                  label: field.label,
                  onChanged: (fournisseur) {
                    log('Selected fournisseur: $fournisseur');
                    _selectedFournisseur = fournisseur;
                  },
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextField(
                    controller: _controllers[field.label],
                    maxLines: field.type == 'multiline' ? 5 : 1,
                    decoration: InputDecoration(labelText: field.label),
                  ),
                );
              }
            }),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
              label: const Text("Sauvegarder"),
            ),
          ],
        ),
      ),
    );
  }
}
