import 'dart:io';

import 'package:flutter/material.dart';
import 'package:skincare/models/product.dart';
import 'package:skincare/models/routine.dart';
import 'package:skincare/models/time.dart';
import 'package:skincare/services/product_database.dart';

class RoutinePage extends StatelessWidget {
  final List<Routine> routines;
  final SkincareTime routineTime;

  const RoutinePage(this.routines, this.routineTime, {super.key});

  void _markProductsUsed(BuildContext context) async {
    await ProductDatabase.instance.completeRoutine(routineTime);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routine')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  spacing: 8.0,
                  children: routines
                      .map((r) => ProductCard(product: r.product))
                      .toList(),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _markProductsUsed(context),
                child: const Text('Finished'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    bool imageExists =
        product.imagePath != null && File(product.imagePath!).existsSync();
    Widget image = imageExists
        ? Image.file(
            File(product.imagePath!),
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          )
        : const Icon(Icons.image_not_supported, size: 150);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(17),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        spacing: 8.0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: image,
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  product.instructions,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
