import 'package:skincare/models/product.dart';
import 'package:skincare/models/time.dart';

class Routine {
  int? id;
  final int productId;
  final SkincareTime routine;
  final int routineOrder;
  DateTime lastUsed;
  Product product;

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
    routine: map['routine'],
    routineOrder: map['routineOrder'],
    lastUsed: DateTime.parse(map['lastUsed'] as String),
    product: Product.fromMap(map['product'] as Map<String, dynamic>),
  );
}