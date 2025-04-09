import 'package:flutter/material.dart';
import 'form_model.dart';

class CreateFormScreen extends StatefulWidget {
  final Function(String title, List<FormFieldData> fields) onFormCreated;

  const CreateFormScreen({super.key, required this.onFormCreated});

  @override
  State<CreateFormScreen> createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends State<CreateFormScreen> {
  final _titleController = TextEditingController();
  final List<FormFieldData> _fields = [];

  final List<String> _fieldTypes = ['text', 'number', 'multiline', 'image', 'supplier'];
  String _selectedType = 'text';
  final _labelController = TextEditingController();

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

  void _submitForm() {
    final title = _titleController.text.trim();
    if (title.isEmpty || _fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complete the form before submitting"), backgroundColor: Colors.red));
      return;
    }

    widget.onFormCreated(title, _fields);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Form created successfully"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create a form")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ListView(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Form Title")),
            const SizedBox(height: 24),
            Text("Add a field", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _labelController, decoration: const InputDecoration(labelText: "Field Label"))),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedType,
                  items:
                      _fieldTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type == 'multiline' ? 'multiline' : type));
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: _addField, icon: const Icon(Icons.add_circle, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 24),
            if (_fields.isNotEmpty) ...[
              Text("Field Value", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._fields.asMap().entries.map((entry) {
                final index = entry.key;
                final field = entry.value;
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(field.label),
                    subtitle: Text("Type : ${field.type}"),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeField(index)),
                  ),
                );
              }),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(onPressed: _submitForm, icon: const Icon(Icons.check), label: const Text("Create Form")),
          ],
        ),
      ),
    );
  }
}
