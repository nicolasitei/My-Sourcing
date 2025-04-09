import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mysourcing2/models/supplier_model.dart';
import 'package:mysourcing2/services/database_service.dart';

class AutocompleteTextField extends StatefulWidget {
  final SupplierModel? initialValue;
  final String label;
  final Function(SupplierModel supplier)? onChanged;
  const AutocompleteTextField({super.key, required this.initialValue, required this.label, required this.onChanged});

  @override
  State<AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField> {
  late TextEditingController? controller;

  List<SupplierModel> suppliers = [];

  StreamSubscription? _supplierSubscription;

  @override
  void initState() {
    super.initState();

    _supplierSubscription = GetIt.I<DatabaseService>().streamSuppliers().listen((value) {
      setState(() {
        suppliers = value;
      });
    });
  }

  @override
  void dispose() {
    _supplierSubscription?.cancel();
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
              return const ['Add a supplier'];
            }
            final options = suppliers.where((SupplierModel option) {
              return option.name?.toLowerCase().contains(textEditingValue.text.toLowerCase()) ?? false;
            });

            if (options.isEmpty) {
              return const ['Add a supplier'];
            }
            return options.map((SupplierModel option) => option.name!).toList();
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
                if (textEditingController.text == 'Add a supplier') {
                  textEditingController.clear();
                  focusNode.unfocus();
                }
                return TextField(controller: textEditingController, focusNode: focusNode, decoration: InputDecoration(labelText: widget.label));
              },
            );
          },
          onSelected: (String selection) {
            if (selection == 'Add a supplier') {
              _showPopUpToAddSupplier();
            } else {
              // Handle the case when the user selects an existing option
              debugPrint('User selected: $selection');
              final selectedSupplier = suppliers.firstWhere((val) => val.name == selection);
              if (widget.onChanged != null) {
                widget.onChanged!(selectedSupplier);
              }
            }
          },
        );
      },
    );
  }

  _showPopUpToAddSupplier() async {
    final supplierModel = SupplierModel(name: '', description: '');

    final supplier = await showDialog<SupplierModel>(
      context: context,
      builder: (context) {
        // Create a new instance of SupplierModel
        return AlertDialog(
          title: const Text('Add a new supplier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: const InputDecoration(labelText: 'Company name'),
                onChanged: (value) {
                  // Handle the input value
                  supplierModel.name = value;
                },
              ),
              SizedBox(height: 16),
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
                onChanged: (value) {
                  // Handle the input value
                  supplierModel.description = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),

            TextButton(
              child: const Text('Add'),
              onPressed: () {
                // Handle adding the new supplier
                if (supplierModel.name == null || supplierModel.name!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a company name")));
                  return;
                }
                if (supplierModel.description == null || supplierModel.description!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a description")));
                  return;
                }
                Navigator.of(context).pop(supplierModel);
              },
            ),
          ],
        );
      },
    );

    if (supplier != null) {
      // Handle the added supplier
      log('Added supplier: ${supplierModel.toJson()}');
      _saveSupplier(supplier);
    }
  }

  _saveSupplier(SupplierModel supplier) async {
    await GetIt.I<DatabaseService>().addSupplier(data: supplier);

    // Handle the case when the supplier is saved successfully
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New supplier added!")));

    controller?.text = supplier.name!;

    if (widget.onChanged != null) {
      widget.onChanged!(supplier);
    }
  }
}
