import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mysourcing2/models/supplier_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addSupplier({required SupplierModel data}) {
    return _firestore.collection('suppliers').add(data.toJson());
  }

  Stream<List<SupplierModel>> streamSuppliers() {
    final snapshot = _firestore.collection('suppliers').snapshots();

    return snapshot.map((snapshot) {
      return snapshot.docs.map((doc) {
        return SupplierModel.fromJson(doc.data());
      }).toList();
    });
  }
}
