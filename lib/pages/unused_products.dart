import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare/models/product.dart';
import 'package:skincare/models/time.dart';
import 'package:skincare/services/product_database.dart';
import 'home_page.dart';

class UnusedProductsPage extends StatelessWidget {
  const UnusedProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnusedProductsPageInner();
  }
}

class UnusedProductsPageInner extends StatefulWidget {
  const UnusedProductsPageInner({super.key});

  @override
  State<UnusedProductsPageInner> createState() =>
      _UnusedProductsPageInnerState();
}

class _UnusedProductsPageInnerState extends State<UnusedProductsPageInner> {
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
    final result = await context.push(
      '/home/edit-product',
      extra: {'product': product, 'routines': const <SkincareTime>[]},
    );
    if (result == true && mounted) {
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
    );
  }
}
