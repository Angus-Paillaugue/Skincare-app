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

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'],
    name: map['name'],
    intervalDays: map['intervalDays'],
    instructions: map['instructions'],
    imagePath: map['imagePath'] as String?,
  );

  Product.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      intervalDays = json['intervalDays'],
      instructions = json['instructions'],
      imagePath = json['imagePath'] as String?,
      id = json['id'] as int?;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'intervalDays': intervalDays,
    'instructions': instructions,
    'imagePath': imagePath,
  };
}
