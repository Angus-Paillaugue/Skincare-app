import 'package:skincare/models/product.dart';
import 'package:skincare/models/time.dart';

class Routine {
  int? id;
  final int productId;
  final SkincareTime routine;
  final int routineOrder;
  DateTime lastUsed;
  Product? product;

  Routine({
    this.id,
    required this.productId,
    required this.routine,
    required this.routineOrder,
    required this.lastUsed,
    required this.product,
  });

  factory Routine.fromMap(Map<String, dynamic> map) => Routine(
    id: map['id'],
    productId: map['productId'],
    routine: SkincareTime.values.firstWhere(
      (e) => e.name == map['routine'] as String,
      orElse: () => SkincareTime.none,
    ),
    routineOrder: map['routineOrder'],
    lastUsed: DateTime.parse(map['lastUsed'] as String),
    product: map['product'] == null
        ? null
        : Product.fromMap(map['product'] as Map<String, dynamic>),
  );

  Routine.fromJson(Map<String, dynamic> json)
    : productId = json['productId'],
      routine = SkincareTime.values.firstWhere(
        (e) => e.name == json['routine'] as String,
        orElse: () => SkincareTime.none,
      ),
      routineOrder = json['routineOrder'],
      lastUsed = DateTime.parse(json['lastUsed'] as String);

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'routine': routine.name,
    'routineOrder': routineOrder,
    'lastUsed': lastUsed.toIso8601String(),
  };
}
