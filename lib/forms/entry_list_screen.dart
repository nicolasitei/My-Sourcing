import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'form_model.dart';
import 'edit_entry_screen.dart'; // Correctement importé
import 'export_excel.dart';
import 'package:intl/intl.dart'; 


class EntryListScreen extends StatefulWidget {
  final String formId;
  final String formTitle;
  final List<FormFieldData> fields;

  const EntryListScreen({
    super.key,
    required this.formId,
    required this.formTitle,
    required this.fields,
  });

  @override
  State<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends State<EntryListScreen> {
  final Map<String, bool> selectedEntries = {};
  bool selectAll = false;

  void _toggleSelectAll(List<QueryDocumentSnapshot> docs) {
    setState(() {
      selectAll = !selectAll;
      for (var doc in docs) {
        selectedEntries[doc.id] = selectAll;
      }
    });
  }

  void _exportSelected(List<QueryDocumentSnapshot> docs) async {
    final selectedDocs =
        docs.where((doc) => selectedEntries[doc.id] == true).toList();
    final entries =
        selectedDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    final userId = FirebaseAuth.instance.currentUser!.uid;

    await exportSelectedEntriesToExcel(
      context: context,
      userId: userId,
      formId: widget.formId,
      formTitle: widget.formTitle,
      fields: widget.fields,
      entries: entries,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final entriesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('forms')
        .doc(widget.formId)
        .collection('entries');

    return Scaffold(
      appBar: AppBar(
        title: Text("Entrées : ${widget.formTitle}"),
        // Suppression des deux icônes à droite du header (actions)
        actions: [],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: entriesRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data!.docs;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: selectAll,
                      onChanged: (_) => _toggleSelectAll(entries),
                    ),
                    const Text("Tout sélectionner"),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_download),
                      label: const Text("Exporter"),
                      onPressed: () => _exportSelected(entries),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = entries[index].data() as Map<String, dynamic>;
                    final entryId = entries[index].id;

                    final firstFilled = widget.fields
                        .map((f) => data[f.label])
                        .firstWhere(
                          (value) =>
                              value != null && value.toString().isNotEmpty,
                          orElse: () => null,
                        );

                    final createdAt = data['createdAt']
                            ?.toDate();
              final formattedDate = createdAt != null
                  ? DateFormat('d MMM yyyy').format(createdAt) // Format: jour mois abrégé année
                  : '';

                    final imageField = widget.fields.firstWhere(
                      (f) => f.type == 'image' && data[f.label] != null,
                      orElse: () => FormFieldData(label: '', type: 'text'),
                    );
                    final imageUrl = imageField.label.isNotEmpty
                        ? data[imageField.label]
                        : null;

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: ListTile(
                        leading: imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.insert_drive_file, size: 36),
                        title: Text(
                          firstFilled?.toString() ?? "Entrée ${index + 1}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "$formattedDate",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Checkbox(
                              value: selectedEntries[entryId] ?? false,
                              onChanged: (value) {
                                setState(() =>
                                    selectedEntries[entryId] = value ?? false);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditEntryScreen(
                                      formId: widget.formId,
                                      entryId: entryId,
                                      fields: widget.fields,
                                      initialData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Supprimer l'entrée"),
                                    content: const Text(
                                        "Êtes-vous sûr de vouloir supprimer cette entrée ?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Annuler"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Supprimer"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(FirebaseAuth.instance
                                          .currentUser!.uid)
                                      .collection('forms')
                                      .doc(widget.formId)
                                      .collection('entries')
                                      .doc(entryId)
                                      .delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Entrée supprimée.")),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
