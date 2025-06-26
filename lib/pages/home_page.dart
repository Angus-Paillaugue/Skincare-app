import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter/material.dart';
import 'package:skincare/models/time.dart';
import 'package:skincare/models/routine.dart';
import 'package:skincare/models/product.dart';
import 'package:skincare/pages/unused_products.dart';
import 'package:skincare/services/product_database.dart';
import 'package:skincare/utils/utils.dart';
import 'add_product_page.dart';
import 'edit_product.dart';
import 'routine_page.dart';
import 'routine_reorder.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    final innerFightRoutines = await ProductDatabase.instance
        .getRoutinesForTime(SkincareTime.night);
    setState(() {
      morningRoutines = innerMorningRoutines;
      nightRoutines = innerFightRoutines;
    });
  }

  bool isDue(Product product, SkincareTime time) {
    final now = DateTime.now();
    final routine = time == SkincareTime.morning
        ? morningRoutines
        : nightRoutines;

    if (!routine.any((r) => r.product.id == product.id)) {
      return false; // Product not in routine
    }
    final lastUsed = routine
        .firstWhere((r) => r.product.id == product.id && r.routine == time)
        .lastUsed;

    return now.difference(lastUsed).inDays >= product.intervalDays;
  }

  void _startRoutinePrompt() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Routine'),
        content: const Text('Which routine do you want to start?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'morning'),
            child: const Text('Morning'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'night'),
            child: const Text('Night'),
          ),
        ],
      ),
    );

    if (result != null) {
      final time = result == 'morning'
          ? SkincareTime.morning
          : SkincareTime.night;
      final activeRoutine = time == SkincareTime.morning
          ? morningRoutines
          : nightRoutines;
      final dueRoutines = activeRoutine
          .where((r) => isDue(r.product, time))
          .toList();

      if (dueRoutines.isNotEmpty && mounted) {
        final res = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RoutinePage(dueRoutines, time)),
        );
        if (res != true) return;
        // If the routine was completed, update lastUsed for each product
        for (int i = 0; i < activeRoutine.length; i++) {
          final routine = activeRoutine[i];
          if (isDue(routine.product, time)) {
            setState(() {
              routine.lastUsed = DateTime.now();
            });
          }
        }
      }
    }
  }

  void _editProduct(Product product) async {
    final routines = [
      if (morningRoutines.any((r) => r.product.id == product.id))
        SkincareTime.morning,
      if (nightRoutines.any((r) => r.product.id == product.id))
        SkincareTime.night,
    ];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductPage(
          product: product,
          routines: routines,
          onFinished: () => _loadProducts(),
        ),
      ),
    );
  }

  Widget _buildRoutine(SkincareTime time) {
    List<Routine> routines = time == SkincareTime.morning
        ? morningRoutines
        : nightRoutines;
    List<Product> products = routines.map((r) => r.product).toList();
    bool hasDueProducts = products.any((p) => isDue(p, time));

    Widget productGrid = Padding(
      padding: EdgeInsetsGeometry.all(8.0),
      child: LayoutGrid(
        columnSizes: [1.fr, 1.fr],
        rowSizes: [for (int i = 0; i < math.max((products.length / 2).ceil(), 1); i++) auto],
        rowGap: 8,
        columnGap: 8,
        children: [
          for (final product in products)
            GestureDetector(
              onTap: () => _editProduct(product),
              child: ProductCard(product: product, time: time),
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
                  icon: Icon(Icons.keyboard_arrow_right_rounded),
                  iconSize: 24,
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoutineReorderPage(routines: routines),
                      ),
                    );
                    if (res == null || res is! List<Routine>) return;
                    if (res.isEmpty) return;
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

  Future<void> _showUnusedProducts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UnusedProductsPage()),
    );
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skincare Routine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_rounded),
            onPressed: _showUnusedProducts,
            tooltip: 'Unused Products',
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildRoutine(SkincareTime.morning),
                _buildRoutine(SkincareTime.night),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 8.0,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final returnValue = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddProductPage()),
                    );
                    if (returnValue == null || returnValue is! Product) return;
                    final routines = await ProductDatabase.instance
                        .getRoutinesForProduct(returnValue);
                    if (routines.isNotEmpty) {
                      setState(() {
                        for (final routine in routines) {
                          if (routine.routine == SkincareTime.morning) {
                            morningRoutines.add(routine);
                          } else {
                            nightRoutines.add(routine);
                          }
                        }
                      });
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 4,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded),
                      const Text("Add New Product"),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _startRoutinePrompt,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 4,
                    children: [
                      const Icon(Icons.play_circle_outline_rounded),
                      const Text("Start Routine"),
                    ],
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
