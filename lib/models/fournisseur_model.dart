class FournisseurModel {
  final String? id;
  String? name;
  String? description;

  FournisseurModel({this.id, this.name, this.description});

  factory FournisseurModel.fromJson(Map<String, dynamic> json) {
    return FournisseurModel(id: json['id'] as String?, name: json['name'] as String?, description: json['description'] as String?);
  }

  Map<String, dynamic> toJson() {
    final map = {'id': id, 'name': name, 'description': description};

    map.removeWhere((key, value) => value == null); // Remove null values
    return map;
  }

  FournisseurModel copyWith({String? id, String? name, String? description}) {
    return FournisseurModel(id: id ?? this.id, name: name ?? this.name, description: description ?? this.description);
  }
}
