import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mysourcing2/models/fournisseur_model.dart';
import 'package:mysourcing2/services/database_service.dart';

class AutocompleteTextField extends StatefulWidget {
  final FournisseurModel? initialValue;
  final String label;
  final Function(FournisseurModel fournisseur)? onChanged;
  const AutocompleteTextField({super.key, required this.initialValue, required this.label, required this.onChanged});

  @override
  State<AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField> {
  late TextEditingController? controller;

  List<FournisseurModel> fournisseurs = [];

  StreamSubscription? _fournisseurSubscription;

  @override
  void initState() {
    super.initState();

    _fournisseurSubscription = GetIt.I<DatabaseService>().streamFournisseurs().listen((value) {
      setState(() {
        fournisseurs = value;
      });
    });
  }

  @override
  void dispose() {
    _fournisseurSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<String>(
          initialValue: TextEditingValue(text: widget.initialValue?.name ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const ['Ajouter un fournisseur'];
            }
            final options = fournisseurs.where((FournisseurModel option) {
              return option.name?.toLowerCase().contains(textEditingValue.text.toLowerCase()) ?? false;
            });

            if (options.isEmpty) {
              return const ['Ajouter un fournisseur'];
            }
            return options.map((FournisseurModel option) => option.name!).toList();
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  height: 230,
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        title: Text(option),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            controller = textEditingController;
            return AnimatedBuilder(
              animation: controller!,
              builder: (context, child) {
                if (textEditingController.text == 'Ajouter un fournisseur') {
                  textEditingController.clear();
                  focusNode.unfocus();
                }
                return TextField(controller: textEditingController, focusNode: focusNode, decoration: InputDecoration(labelText: widget.label));
              },
            );
          },
          onSelected: (String selection) {
            if (selection == 'Ajouter un fournisseur') {
              // Handle the case when the user selects "Ajouter un fournisseur"
              _showPopUpToAddFournisseur();
            } else {
              // Handle the case when the user selects an existing option
              debugPrint('User selected: $selection');
              final selectedFournisseur = fournisseurs.firstWhere((fournisseur) => fournisseur.name == selection);
              if (widget.onChanged != null) {
                widget.onChanged!(selectedFournisseur);
              }
            }
          },
        );
      },
    );
  }

  _showPopUpToAddFournisseur() async {
    final fournisseurModel = FournisseurModel(name: '', description: '');

    final fournisseur = await showDialog<FournisseurModel>(
      context: context,
      builder: (context) {
        // Create a new instance of FournisseurModel
        return AlertDialog(
          title: const Text('Ajouter un fournisseur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: const InputDecoration(labelText: 'Nom du société'),
                onChanged: (value) {
                  // Handle the input value
                  fournisseurModel.name = value;
                },
              ),
              SizedBox(height: 16),
              TextField(
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
                onChanged: (value) {
                  // Handle the input value
                  fournisseurModel.description = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),

            TextButton(
              child: const Text('Ajouter'),
              onPressed: () {
                // Handle adding the new supplier
                Navigator.of(context).pop(fournisseurModel);
              },
            ),
          ],
        );
      },
    );

    if (fournisseur != null) {
      // Handle the added supplier
      debugPrint('Added supplier: ${fournisseurModel.toJson()}');
      _saveFournisseur(fournisseur);
    } else {
      // Handle the case when the user cancels the dialog
      debugPrint('User cancelled the dialog');
    }
  }

  _saveFournisseur(FournisseurModel fournisseur) async {
    await GetIt.I<DatabaseService>().addFournisseur(data: fournisseur);

    // Handle the case when the supplier is saved successfully
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fournisseur ajouté avec succès")));

    controller?.text = fournisseur.name!;

    if (widget.onChanged != null) {
      widget.onChanged!(fournisseur);
    }
  }
}
