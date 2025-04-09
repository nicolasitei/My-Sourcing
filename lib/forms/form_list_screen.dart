import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_form_screen.dart'; // Assurez-vous d'importer EditFormScreen ici
import 'form_model.dart';
import 'fill_form_screen.dart';
import 'entry_list_screen.dart';
import '../widgets/loading_overlay.dart';

class FormListScreen extends StatefulWidget {
  const FormListScreen({super.key});

  @override
  State<FormListScreen> createState() => _FormListScreenState();
}

class _FormListScreenState extends State<FormListScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final formsRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('forms');

    return Scaffold(
      appBar: AppBar(title: const Text('My Forms')),
      body: StreamBuilder<QuerySnapshot>(
        stream: formsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No forms available"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'No title';
              final formId = doc.id;

              // Récupérer la liste des champs
              final List<FormFieldData> fields =
                  (data['fields'] as List).map((fieldData) {
                    return FormFieldData.fromMap(fieldData);
                  }).toList();

              // Récupérer le nombre d'entrées associées à ce formulaire
              final entriesRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('forms').doc(formId).collection('entries');

              return FutureBuilder<int>(
                future: _getEntriesCount(entriesRef),
                builder: (context, entrySnapshot) {
                  if (entrySnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final entryCount = entrySnapshot.data ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("$entryCount entries"), // Affiche le nombre d'entrées
                      trailing: const Icon(Icons.more_vert),
                      onTap: () {
                        showDialog(context: context, builder: (_) => _FormActionDialog(formId: formId, title: title, fields: fields));
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Fonction pour obtenir le nombre d'entrées dans une sous-collection
  Future<int> _getEntriesCount(CollectionReference entriesRef) async {
    try {
      final snapshot = await entriesRef.count().get();
      return snapshot.count ?? 0; // Si count est null, retourner 0
    } catch (e) {
      log("Error : $e");
      return 0; // Retourner 0 en cas d'erreur
    }
  }
}

class _FormActionDialog extends StatelessWidget {
  final String formId;
  final String title;
  final List<FormFieldData> fields;

  const _FormActionDialog({required this.formId, required this.title, required this.fields});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("What would you like to do?", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildAction(context, Icons.add_box, "Add a product", () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => FillFormScreen(formId: formId, formTitle: title, fields: fields)));
          }),
          _buildAction(context, Icons.list, "View entries", () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => EntryListScreen(formId: formId, formTitle: title, fields: fields)));
          }),
          _buildAction(context, Icons.copy, "Duplicate", () async {
            final safeContext = context;
            Navigator.pop(context);
            await Future.delayed(const Duration(milliseconds: 100));
            LoadingOverlay.show(safeContext);
            try {
              await FirebaseFirestore.instance.collection('users').doc(userId).collection('forms').add({
                'title': '$title (copy)',
                'fields': fields.map((f) => f.toMap()).toList(),
                'createdAt': Timestamp.now(),
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Form duplicated successfully")));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Duplication error : $e")));
            } finally {
              LoadingOverlay.hide();
            }
          }),
          _buildAction(context, Icons.edit, "Modify", () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => EditFormScreen(formId: formId, initialTitle: title, initialFields: fields)));
          }),
          _buildAction(context, Icons.delete, "Delete", () {
            showDialog(
              context: context,
              builder:
                  (_) => AlertDialog(
                    title: const Text("Delete Form"),
                    content: const Text("Are you sure you want to delete this form? This action cannot be undone."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          final safeContext = context;
                          Navigator.pop(context);
                          await Future.delayed(const Duration(milliseconds: 100));
                          LoadingOverlay.show(safeContext);
                          try {
                            await FirebaseFirestore.instance.collection('users').doc(userId).collection('forms').doc(formId).delete();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Form deleted successfully")));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error : $e")));
                          } finally {
                            LoadingOverlay.hide();
                          }
                        },
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
      ),
    );
  }
}
