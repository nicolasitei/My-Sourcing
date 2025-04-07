import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestStorageScreen extends StatefulWidget {
  @override
  _TestStorageScreenState createState() => _TestStorageScreenState();
}

class _TestStorageScreenState extends State<TestStorageScreen> {
  final picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    try {
      // Demander à l'utilisateur de choisir une image depuis la galerie
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Sélectionner l'image
        File imageFile = File(pickedFile.path);

        // Créer une référence de fichier dans Firebase Storage
        String fileName = 'uploads/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

        // Uploader l'image
        UploadTask uploadTask = storageRef.putFile(imageFile);

        // Attendre que l'upload se termine
        TaskSnapshot snapshot = await uploadTask;

        // Récupérer l'URL de l'image téléchargée
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Afficher l'URL dans la console et sur l'interface utilisateur
        print("Image téléchargée avec succès ! URL : $downloadUrl");

        // Afficher un message de succès à l'utilisateur
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Image téléchargée avec succès ! URL: $downloadUrl'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Aucune image sélectionnée."),
        ));
      }
    } catch (e) {
      print("Erreur lors de l'upload de l'image : $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Erreur lors du téléchargement : $e"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Firebase Storage')),
      body: Center(
        child: ElevatedButton(
          onPressed: _pickAndUploadImage,
          child: const Text("Choisir une image et télécharger"),
        ),
      ),
    );
  }
}
