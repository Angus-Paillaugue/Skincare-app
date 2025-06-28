import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare/page.dart';
import 'package:skincare/models/product.dart';
import 'package:skincare/models/time.dart';
import 'package:skincare/pages/edit_product.dart';
import 'package:skincare/services/product_database.dart';

class AddProductPage extends AppPage {
  const AddProductPage({super.key});
  @override
  String get title => 'Add Product';

  @override
  Widget build(BuildContext context) {
    return AddProductPageInner();
  }
}

class AddProductPageInner extends StatefulWidget {
  const AddProductPageInner({super.key});
  @override
  State<AddProductPageInner> createState() => _AddProductPageInnerState();
}

class _AddProductPageInnerState extends State<AddProductPageInner> {
  bool _useInMorning = false;
  bool _useAtNight = false;

  void _saveProduct(Product product) async {
    if (product.name.isEmpty || product.instructions.isEmpty) return;
    List<SkincareTime> routines = [];
    if (_useInMorning) routines.add(SkincareTime.morning);
    if (_useAtNight) routines.add(SkincareTime.night);
    final productId = await ProductDatabase.instance.addProduct(
      product,
      routines,
    );
    product.id = productId;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} added successfully!')),
      );
      GoRouter.of(context).go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProductForm(
      onFinished: _saveProduct,
      type: ProductFormType.create,
      onCheckboxChanged: (time, value) {
        setState(() {
          if (time == SkincareTime.morning) {
            _useInMorning = value;
          } else if (time == SkincareTime.night) {
            _useAtNight = value;
          }
        });
      },
    );
  }
}
