import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'form_model.dart';

class FormService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> saveForm(String title, List<FormFieldData> fields) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('forms')
        .add({
      'title': title,
      'fields': fields.map((f) => f.toMap()).toList(),
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> deleteForm(String formId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('forms')
        .doc(formId)
        .delete();
  }

  Future<void> renameForm(String formId, String newTitle) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('forms')
        .doc(formId)
        .update({'title': newTitle});
  }

  Future<void> duplicateForm(String formId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final formDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('forms')
        .doc(formId)
        .get();

    if (!formDoc.exists) return;

    final data = formDoc.data()!;
    data['title'] = data['title'] + ' (copie)';
    data['createdAt'] = Timestamp.now();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('forms')
        .add(data);
  }

  Future<void> saveEntry(String formId, Map<String, dynamic> entryData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('forms')
        .doc(formId)
        .collection('entries')
        .add({
      ...entryData,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> updateEntry(String formId, String entryId, Map<String, dynamic> entryData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('forms')
        .doc(formId)
        .collection('entries')
        .doc(entryId)
        .update(entryData);
  }

  Future<void> deleteEntry(String formId, String entryId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('forms')
        .doc(formId)
        .collection('entries')
        .doc(entryId)
        .delete();
  }

  Future<void> updateForm(String formId, String title, List<FormFieldData> fields) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('forms')
        .doc(formId)
        .update({
          'title': title,
          'fields': fields.map((f) => f.toMap()).toList(),
          'updatedAt': Timestamp.now(),
        });
  }
}
