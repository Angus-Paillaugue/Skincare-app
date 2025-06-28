import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare/models/time.dart';
import 'package:skincare/models/routine.dart';
import 'package:skincare/models/product.dart';
import 'package:skincare/page.dart';
import 'package:skincare/services/product_database.dart';
import 'package:skincare/utils/utils.dart';

class HomePage extends AppPage {
  const HomePage({super.key});
  @override
  String get title => 'Home';

  @override
  List<Widget> get scaffoldActions => [
    Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.category_rounded),
        tooltip: 'Unused Products',
        onPressed: () => context.push('/home/unused-products'),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const HomePageInner();
  }
}

class HomePageInner extends StatefulWidget {
  const HomePageInner({super.key});
  @override
  State<HomePageInner> createState() => _HomePageInnerState();
}

class _HomePageInnerState extends State<HomePageInner> {
  List<Routine> morningRoutines = [];
  List<Routine> nightRoutines = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    final innerMorningRoutines = await ProductDatabase.instance
        .getRoutinesForTime(SkincareTime.morning);
    final innerNightRoutines = await ProductDatabase.instance
        .getRoutinesForTime(SkincareTime.night);
    setState(() {
      morningRoutines = innerMorningRoutines;
      nightRoutines = innerNightRoutines;
    });
  }

  void _editProduct(Product product) async {
    final routines = [
      if (morningRoutines.any((r) => r.product?.id == product.id))
        SkincareTime.morning,
      if (nightRoutines.any((r) => r.product?.id == product.id))
        SkincareTime.night,
    ];
    final result = await context.push(
      '/home/edit-product',
      extra: {'product': product, 'routines': routines},
    );
    if (result == true) {
      _loadProducts();
    }
  }

  Widget _buildRoutine(SkincareTime time) {
    List<Routine> routines = time == SkincareTime.morning
        ? morningRoutines
        : nightRoutines;
    List<Product> products = routines
        .where((r) => r.product != null)
        .map((r) => r.product!)
        .toList();
    bool hasDueProducts = products.any(
      (p) => Utils.isDue(p, time, morningRoutines, nightRoutines),
    );

    Widget productGrid = Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutGrid(
        columnSizes: [1.fr, 1.fr],
        rowSizes: [
          for (int i = 0; i < math.max((products.length / 2).ceil(), 1); i++)
            auto,
        ],
        rowGap: 8,
        columnGap: 8,
        children: [
          for (final product in products)
            GestureDetector(
              onTap: () => _editProduct(product),
              child: ProductCard(
                product: product,
                time: time,
                editableIcon: true,
              ),
            ),
        ],
      ),
    );
    return Column(
      children: [
        ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasDueProducts ? Icons.close_rounded : Icons.check_rounded,
                color: hasDueProducts
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                time == SkincareTime.morning
                    ? 'Morning Routine'
                    : 'Night Routine',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: products.length > 1
              ? IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right_rounded),
                  iconSize: 24,
                  onPressed: () async {
                    final res = await context.push(
                      '/home/reorder-routine',
                      extra: {'routines': routines},
                    );
                    if (res == null || res is! List<Routine>) return;
                    setState(() {
                      if (time == SkincareTime.morning) {
                        morningRoutines = res;
                      } else {
                        nightRoutines = res;
                      }
                    });
                  },
                )
              : null,
        ),
        productGrid,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildRoutine(SkincareTime.morning),
        _buildRoutine(SkincareTime.night),
      ],
    );
  }
}

// Use your existing ProductCard widget here or import from a shared file.
class ProductCard extends StatelessWidget {
  final Product product;
  final SkincareTime time;
  final bool editableIcon;

  const ProductCard({
    super.key,
    required this.product,
    required this.time,
    this.editableIcon = true,
  });

  Widget _buildPill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primary.withAlpha(Utils.toOpacity(0.1)),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        Utils.formatInterval(product.intervalDays, time),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool pathExists =
        product.imagePath != null && File(product.imagePath!).existsSync();
    Widget image = pathExists
        ? Image.file(
            File(product.imagePath!),
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        : Center(child: Icon(Icons.image, size: 50));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                image,
                if (editableIcon)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: const Icon(Icons.edit_square, color: Colors.white),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildPill(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
