class SupplierModel {
  String? name;
  String? description;

  SupplierModel({this.name, this.description});

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(name: json['name'] as String?, description: json['description'] as String?);
  }

  Map<String, dynamic> toJson() {
    final map = {'name': name, 'description': description};

    map.removeWhere((key, value) => value == null); // Remove null values
    return map;
  }

  SupplierModel copyWith({String? name, String? description}) {
    return SupplierModel(name: name ?? this.name, description: description ?? this.description);
  }
}
