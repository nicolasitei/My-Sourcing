import 'dart:developer';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get the local path from the storage path
  Future<String> buildLocalPathFromStoragePath(String storagePath) async {
    // Get the image from local storage
    final filePath = storagePath.split('/').last;

    final appDirDoc = await getApplicationDocumentsDirectory();
    final dirPath = '${appDirDoc.path}/$filePath';

    return dirPath;
  }

  Future<File> saveImageLocally({required File file, required String storagePath}) async {
    final dirPath = await buildLocalPathFromStoragePath(storagePath);

    // Store the image locally
    final bytes = await file.readAsBytes();

    final newFile = File(dirPath);

    final storedFile = await newFile.writeAsBytes(bytes);

    return storedFile;
  }

  Future<List<String>> uploadImagesToServer({required String formId, required String uid, required List<File> files}) async {
    List<String> storagePaths = [];

    log("Form ID : $formId");
    log("UID : $uid");

    // Faire une loop pour uploader les images sur le storage
    for (final file in files) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      log("Timestamp : $timestamp");

      final ext = file.path.split('.').last;
      log("Extension : $ext");

      final storagePath = 'images/$uid/$formId/$timestamp.$ext';
      log("Storage Path : $storagePath");

      await saveImageLocally(storagePath: storagePath, file: file);

      log("Image saved locally!");

      final path = await uploadFileToStorage(storagePath: storagePath, file: file);

      log("Image uploaded successfully to server!");

      // Add the path to the list to upload Firestore document
      storagePaths.add(path);
    }

    log("Storage Paths : $storagePaths");

    return storagePaths;
  }

  // Create a new file in the storage
  Future<String> uploadFileToStorage({required String storagePath, required File file}) async {
    final ref = _storage.ref().child(storagePath);
    await ref.putFile(file);
    return storagePath;
  }

  // Delete a file from the storage
  Future<void> deleteFileFromStorageAndLocal(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    // Delete the file from the storage, if exists
    try {
      await ref.delete();
      log('File deleted from storage');
    } catch (e) {
      log('File does not exist in storage, no need to delete.');
    }

    // Get the image from local storage
    final filePath = await buildLocalPathFromStoragePath(storagePath);
    log('File path: $filePath');

    // Delete the file in local storage
    try {
      await File(filePath).delete();
      log('File deleted from local storage');
    } catch (e) {
      log('File does not exist in local storage, no need to delete.');
    }
  }

  Future<File?> getImageFromStoragePath(String? storagePath) async {
    if (storagePath == null) return Future.value(null);

    // Get the image from local storage
    final dirPath = await buildLocalPathFromStoragePath(storagePath);

    // Check if the file exists
    final exist = await File(dirPath).exists();

    // If the file does not exist, download from server and store it locally
    if (!exist) {
      log('Downloading media from server');
      await downloadMediaFromPath(storagePath);
    }

    return Future.value(File(dirPath));
  }

  Future<File?> downloadMediaFromPath(String storagePath) async {
    // Download the media from the server
    final ref = _storage.ref().child(storagePath);

    final dirPath = await buildLocalPathFromStoragePath(storagePath);
    final file = File(dirPath);

    await ref.writeToFile(file);

    return file;
  }
}
