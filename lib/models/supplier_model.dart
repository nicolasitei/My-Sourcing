class SupplierModel {
  final String? id;
  String? name;
  String? description;

  SupplierModel({this.id, this.name, this.description});

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(id: json['id'] as String?, name: json['name'] as String?, description: json['description'] as String?);
  }

  Map<String, dynamic> toJson() {
    final map = {'id': id, 'name': name, 'description': description};

    map.removeWhere((key, value) => value == null); // Remove null values
    return map;
  }

  SupplierModel copyWith({String? id, String? name, String? description}) {
    return SupplierModel(id: id ?? this.id, name: name ?? this.name, description: description ?? this.description);
  }
}
