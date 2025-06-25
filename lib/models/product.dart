class Product {
  int? id;
  String name;
  int intervalDays;
  String instructions;
  String? imagePath;

  Product({
    this.id,
    required this.name,
    required this.intervalDays,
    required this.instructions,
    this.imagePath,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'intervalDays': intervalDays,
    'instructions': instructions,
    'imagePath': imagePath,
  };

  static Product fromMap(Map<String, dynamic> map) => Product(
    id: map['id'],
    name: map['name'],
    intervalDays: map['intervalDays'],
    instructions: map['instructions'],
    imagePath: map['imagePath'] as String?,
  );
}
