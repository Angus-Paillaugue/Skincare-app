import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:skincare/models/product.dart';
import 'package:skincare/models/time.dart';
import 'package:skincare/pages/edit_product.dart';
import 'package:skincare/pages/home_page.dart';
import 'package:skincare/services/product_database.dart';

class UnusedProductsPage extends StatefulWidget {
  const UnusedProductsPage({super.key});

  @override
  State<UnusedProductsPage> createState() => _UnusedProductsPageState();
}

class _UnusedProductsPageState extends State<UnusedProductsPage> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    List<Product> innerProducts = await ProductDatabase.instance
        .getUnusedProducts();
    setState(() {
      products = innerProducts;
    });
  }

  void _editProduct(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductPage(
          product: product,
          routines: [],
          onFinished: () => _loadProducts(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unused products')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: products.isEmpty
                  ? const Text(
                      'No unused products found.',
                      style: TextStyle(fontSize: 16),
                    )
                  : LayoutGrid(
                      columnSizes: [1.fr, 1.fr],
                      rowSizes: const [auto, auto],
                      rowGap: 8,
                      columnGap: 8,
                      children: [
                        for (final product in products)
                          GestureDetector(
                            onTap: () => _editProduct(product),
                            child: ProductCard(
                              product: product,
                              time: SkincareTime.none,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
