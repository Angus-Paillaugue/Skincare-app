import 'package:flutter/material.dart';
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: routines
                  .map((r) => ListTile(
                title: Text(r.product.name),
                subtitle: Text('Order: ${r.routineOrder}'),
              ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _markProductsUsed(context),
              child: const Text('Finished'),
            ),
          ),
        ],
      ),
    );
  }
}
