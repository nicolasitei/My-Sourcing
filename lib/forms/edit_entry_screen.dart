import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mysourcing2/services/storage_service.dart';
import 'package:mysourcing2/widgets/image_uploader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'form_model.dart';

class EditEntryScreen extends StatefulWidget {
  final String formId;
  final String entryId;
  final List<FormFieldData> fields;
  final Map<String, dynamic> initialData;

  const EditEntryScreen({super.key, required this.formId, required this.entryId, required this.fields, required this.initialData});

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  final picker = ImagePicker();

  final List<File> _images = [];
  final List<File> _tempFiles = [];
  List<File> get _allImages => [..._images, ..._tempFiles];

  @override
  void initState() {
    super.initState();
    print("Initial data: ${widget.initialData}");

    for (final field in widget.fields) {
      if (field.type != 'image') {
        _controllers[field.label] = TextEditingController(text: widget.initialData[field.label]?.toString() ?? '');
      } else {
        // Pour les champs d'image, on vient copier les liens d'images existants
        loadImages(field);
      }
    }
  }

  loadImages(FormFieldData field) async {
    final storagePaths = List<String>.from(widget.initialData[field.label] ?? []);
    log("Storage paths: $storagePaths");
    if (storagePaths.isEmpty) return;
    for (final path in storagePaths) {
      // Get the local file
      final file = await GetIt.I<StorageService>().getImageFromStoragePath(path);
      if (file == null) continue;
      setState(() {
        _images.add(file);
      });
    }
  }

  Future<void> _addNewImage() async {
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

    // Create the storage path

    setState(() {
      _tempFiles.add(File(pickedFile.path));
    });
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
    });

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final updatedData = <String, dynamic>{};

    for (final field in widget.fields) {
      if (field.type == 'image') {
        List<String> storagePaths = [];

        for (final image in _images) {
          final imgPath = image.path.split('/').last;
          final storagePath = 'images/$userId/${widget.formId}/$imgPath';

          storagePaths.add(storagePath);
        }

        // Upload the temp image to the server
        if (_tempFiles.isNotEmpty) {
          final newPaths = await _uploadFilesToServer();
          storagePaths.addAll(newPaths);
        }

        updatedData[field.label] = storagePaths;
      } else {
        updatedData[field.label] = _controllers[field.label]?.text ?? '';
      }
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('forms')
        .doc(widget.formId)
        .collection('entries')
        .doc(widget.entryId)
        .update(updatedData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Entrée mise à jour.")));
      Navigator.pop(context);
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  Future<List<String>> _uploadFilesToServer() async {
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

  _deleteImage(int index) async {
    final image = _allImages[index];

    setState(() {
      _images.contains(image) ? _images.remove(image) : _tempFiles.remove(image);
    });

    log('New images: ${_allImages.map((e) => e.path).toList()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier l'entrée")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...widget.fields.map((field) {
            if (field.type == 'image') {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${field.label} (image)", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  ImageUploader(images: _allImages, addImage: _addNewImage, deleteImage: _deleteImage),

                  const SizedBox(height: 16),
                ],
              );
            } else if (field.type == 'multiline') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: _controllers[field.label],
                  maxLines: 5,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(labelText: field.label, alignLabelWithHint: true, border: const OutlineInputBorder()),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(controller: _controllers[field.label], decoration: InputDecoration(labelText: field.label)),
              );
            }
          }),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
            label: const Text("Sauvegarder les modifications"),
          ),
        ],
      ),
    );
  }
}
