import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mysourcing2/models/fournisseur_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFournisseur({required FournisseurModel data}) {
    return _firestore.collection('fournisseurs').add(data.toJson());
  }

  Stream<List<FournisseurModel>> streamFournisseurs() {
    final snapshot = _firestore.collection('fournisseurs').snapshots();

    return snapshot.map((snapshot) {
      return snapshot.docs.map((doc) {
        return FournisseurModel.fromJson(doc.data());
      }).toList();
    });
  }
}
