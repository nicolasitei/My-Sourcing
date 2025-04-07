class FormFieldData {
  final String label;
  final String type; // Exemple : 'text', 'number', 'email', 'date', 'image'

  FormFieldData({
    required this.label,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'type': type,
    };
  }

  factory FormFieldData.fromMap(Map<String, dynamic> map) {
    return FormFieldData(
      label: map['label'] ?? '',
      type: map['type'] ?? 'text',
    );
  }
}
