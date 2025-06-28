import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare/models/product.dart';
import 'package:skincare/models/routine.dart';
import 'package:skincare/models/time.dart';
import 'package:skincare/page.dart';
import 'package:skincare/services/product_database.dart';
import 'package:skincare/utils/utils.dart';

class RoutineStartPage extends AppPage {
  const RoutineStartPage({super.key});
  @override
  String get title => 'Start Routine';

  @override
  Widget build(BuildContext context) {
    return RoutineSelectionScreen(
      onRoutineSelected: (time) async {
        final morningRoutines = await ProductDatabase.instance
            .getRoutinesForTime(SkincareTime.morning);
        final nightRoutines = await ProductDatabase.instance.getRoutinesForTime(
          SkincareTime.night,
        );
        final activeRoutine = time == SkincareTime.morning
            ? morningRoutines
            : nightRoutines;
        final dueRoutines = activeRoutine
            .where(
              (r) => r.product == null
                  ? false
                  : Utils.isDue(
                      r.product!,
                      time,
                      morningRoutines,
                      nightRoutines,
                    ),
            )
            .toList();

        if (dueRoutines.isNotEmpty) {
          context.push(
            '/routine/routine-inner',
            extra: {'routines': dueRoutines, 'routineTime': time},
          );
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No products due for this routine!'),
              ),
            );
          }
        }
      },
    );
  }
}

class RoutineSelectionScreen extends StatelessWidget {
  final Future<void> Function(SkincareTime) onRoutineSelected;
  const RoutineSelectionScreen({super.key, required this.onRoutineSelected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.wb_sunny_outlined),
            label: const Text('Start Morning Routine'),
            onPressed: () => onRoutineSelected(SkincareTime.morning),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(250, 60),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.nights_stay_outlined),
            label: const Text('Start Night Routine'),
            onPressed: () => onRoutineSelected(SkincareTime.night),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(250, 60),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class RoutinePageInner extends StatelessWidget {
  final List<Routine> routines;
  final SkincareTime routineTime;

  const RoutinePageInner(this.routines, this.routineTime, {super.key});

  Future<void> _markProductsUsed(BuildContext context) async {
    await ProductDatabase.instance.completeRoutine(routineTime);
    if (context.mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: routines
                  .where((r) => r.product != null)
                  .map((r) => ProductCard(product: r.product!))
                  .toList(),
            ),
            const SizedBox(height: 8),
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
    );
  }
}

// Use your existing ProductCard widget here or import from a shared file.

class ProductCard extends StatelessWidget {
  final Product product;
  final SkincareTime? time;
  final bool editableIcon;
  final bool showInstructions;

  const ProductCard({
    super.key,
    required this.product,
    this.time,
    this.editableIcon = false,
    this.showInstructions = false,
  });

  Widget _buildPill(BuildContext context) {
    if (time == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primary.withAlpha(Utils.toOpacity(0.1)),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        Utils.formatInterval(product.intervalDays, time!),
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
        : const Center(child: Icon(Icons.image, size: 50));

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
                  const Positioned(
                    bottom: 12,
                    right: 12,
                    child: Icon(Icons.edit_square, color: Colors.white),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 8),
                if (showInstructions)
                  Text(
                    product.instructions,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  _buildPill(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
