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
    final formsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('forms');

    return Scaffold(
      appBar: AppBar(title: const Text('Mes formulaires')),
      body: StreamBuilder<QuerySnapshot>(
        stream: formsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucun formulaire trouvé."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Sans titre';
              final formId = doc.id;

              // Récupérer la liste des champs
              final List<FormFieldData> fields =
                  (data['fields'] as List).map((fieldData) {
                return FormFieldData.fromMap(fieldData);
              }).toList();

              // Récupérer le nombre d'entrées associées à ce formulaire
              final entriesRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('forms')
                  .doc(formId)
                  .collection('entries');

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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("$entryCount entrées"), // Affiche le nombre d'entrées
                      trailing: const Icon(Icons.more_vert),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => _FormActionDialog(
                            formId: formId,
                            title: title,
                            fields: fields,
                          ),
                        );
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
      print("Erreur lors de la récupération du nombre d'entrées : $e");
      return 0; // Retourner 0 en cas d'erreur
    }
  }
}

class _FormActionDialog extends StatelessWidget {
  final String formId;
  final String title;
  final List<FormFieldData> fields;

  const _FormActionDialog({
    required this.formId,
    required this.title,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Que voulez-vous faire ?",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildAction(context, Icons.add_box, "Ajouter un produit", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FillFormScreen(
                  formId: formId,
                  formTitle: title,
                  fields: fields,
                ),
              ),
            );
          }),
          _buildAction(context, Icons.list, "Voir les entrées", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EntryListScreen(
                  formId: formId,
                  formTitle: title,
                  fields: fields,
                ),
              ),
            );
          }),
          _buildAction(context, Icons.copy, "Dupliquer", () async {
            final safeContext = context;
            Navigator.pop(context);
            await Future.delayed(const Duration(milliseconds: 100));
            LoadingOverlay.show(safeContext);
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('forms')
                  .add({
                'title': '$title (copie)',
                'fields': fields.map((f) => f.toMap()).toList(),
                'createdAt': Timestamp.now(),
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Formulaire dupliqué")),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Erreur duplication : $e")),
              );
            } finally {
              LoadingOverlay.hide();
            }
          }),
          _buildAction(context, Icons.edit, "Modifier", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditFormScreen(
                  formId: formId,
                  initialTitle: title,
                  initialFields: fields,
                ),
              ),
            );
          }),
          _buildAction(context, Icons.delete, "Supprimer", () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Confirmer la suppression"),
                content: const Text("Supprimer ce formulaire ?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Annuler"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    onPressed: () async {
                      final safeContext = context;
                      Navigator.pop(context);
                      await Future.delayed(const Duration(milliseconds: 100));
                      LoadingOverlay.show(safeContext);
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('forms')
                            .doc(formId)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Formulaire supprimé")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Erreur suppression : $e")),
                        );
                      } finally {
                        LoadingOverlay.hide();
                      }
                    },
                    child: const Text("Supprimer"),
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, IconData icon, String label,
      VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
      ),
    );
  }
}
