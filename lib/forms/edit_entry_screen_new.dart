import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final Map<String, File?> _updatedImages = {};
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      if (field.type != 'image') {
        _controllers[field.label] = TextEditingController(text: widget.initialData[field.label]?.toString() ?? '');
      }
    }
  }

  // Méthode pour télécharger l'image dans Firebase Storage
  Future<String?> _uploadImage(File image) async {
    final fileName = 'entry_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('form_images/$fileName');
    final task = await ref.putFile(image);
    return await task.ref.getDownloadURL();
  }

  // Méthode pour choisir une image depuis la galerie
  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (status.isGranted) {
      try {
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          setState(() {
            _updatedImages['imageLabel'] = File(pickedFile.path);
          });
          print("Image sélectionnée depuis la galerie : ${pickedFile.path}");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune image sélectionnée.")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur de sélection de l'image : $e")));
        print("Erreur de sélection de l'image : $e");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission refusée pour accéder à la galerie')));
      print("Permission refusée pour accéder à la galerie");
    }
  }

  // Méthode pour enregistrer les modifications dans Firestore
  Future<void> _submit() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final updatedData = <String, dynamic>{};

    // Enregistrer les champs dans Firestore
    for (final field in widget.fields) {
      if (field.type == 'image') {
        // Si une image est sélectionnée, on la télécharge d'abord dans Firebase Storage
        if (_updatedImages.containsKey(field.label) && _updatedImages[field.label] != null) {
          final url = await _uploadImage(_updatedImages[field.label]!);
          updatedData[field.label] = url;
          print("Image téléchargée et URL ajoutée à Firestore : $url");
        } else {
          updatedData[field.label] = widget.initialData[field.label]; // Si aucune image n'est sélectionnée, conserver l'ancienne URL
        }
      } else {
        updatedData[field.label] = _controllers[field.label]?.text ?? ''; // Enregistrer les autres champs
      }
    }

    // Mettre à jour les données dans Firestore
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
              final existingUrl = widget.initialData[field.label];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${field.label} (image)", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(icon: const Icon(Icons.image), label: const Text("Choisir depuis la galerie"), onPressed: _pickImage),
                  const SizedBox(height: 8),
                  // Affichage de l'image sélectionnée ou de l'image existante
                  if (_updatedImages[field.label] != null)
                    Image.file(_updatedImages[field.label]!, height: 100)
                  else if (existingUrl != null)
                    Image.network(existingUrl, height: 100),
                  const SizedBox(height: 20),
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
          ElevatedButton.icon(onPressed: _submit, icon: const Icon(Icons.save), label: const Text("Sauvegarder les modifications")),
        ],
      ),
    );
  }
}
