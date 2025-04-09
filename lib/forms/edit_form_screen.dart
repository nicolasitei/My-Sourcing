import 'package:flutter/material.dart';
import 'form_model.dart';
import 'form_service.dart';

class EditFormScreen extends StatefulWidget {
  final String formId;
  final String initialTitle;
  final List<FormFieldData> initialFields;

  const EditFormScreen({super.key, required this.formId, required this.initialTitle, required this.initialFields});

  @override
  State<EditFormScreen> createState() => _EditFormScreenState();
}

class _EditFormScreenState extends State<EditFormScreen> {
  late TextEditingController _titleController;
  late List<FormFieldData> _fields;
  final _labelController = TextEditingController();
  final List<String> _fieldTypes = ['text', 'number', 'multiline', 'image', 'supplier'];
  String _selectedType = 'text';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _fields = List<FormFieldData>.from(widget.initialFields);
  }

  void _addField() {
    final label = _labelController.text.trim();
    if (label.isEmpty) return;
    setState(() {
      _fields.add(FormFieldData(label: label, type: _selectedType));
      _labelController.clear();
      _selectedType = 'text';
    });
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
    });
  }

  Future<void> _saveForm() async {
    await FormService().updateForm(widget.formId, _titleController.text.trim(), _fields);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Form')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titre du formulaire')),
            const SizedBox(height: 16),
            TextField(controller: _labelController, decoration: const InputDecoration(labelText: 'Nom du champ')),
            DropdownButton<String>(
              value: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              items:
                  _fieldTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
            ),
            ElevatedButton(onPressed: _addField, child: const Text('Add a field')),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _fields.length,
                itemBuilder: (context, index) {
                  final field = _fields[index];
                  return ListTile(
                    title: Text('${field.label} (${field.type})'),
                    trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeField(index)),
                  );
                },
              ),
            ),
            ElevatedButton(onPressed: _saveForm, child: const Text('Save Form')),
          ],
        ),
      ),
    );
  }
}
