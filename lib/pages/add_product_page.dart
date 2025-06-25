import 'package:flutter/material.dart';
import 'package:skincare/pages/edit_product.dart';
import 'package:skincare/models/product.dart';
import 'package:skincare/models/time.dart';
import 'package:skincare/services/product_database.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
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
      Navigator.pop(context, product);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Product')),
      body: ProductForm(
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
      ),
    );
  }
}
