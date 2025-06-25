import 'package:flutter/material.dart';
import 'package:skincare/models/routine.dart';
import 'package:skincare/services/product_database.dart';

class RoutineReorderPage extends StatefulWidget {
  final List<Routine> routines;
  const RoutineReorderPage({required this.routines, super.key});

  @override
  State<RoutineReorderPage> createState() => _RoutineReorderPageState();
}

class _RoutineReorderPageState extends State<RoutineReorderPage> {
  late List<Routine> routines;

  @override
  void initState() {
    super.initState();
    routines = widget.routines;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final routine = routines.removeAt(oldIndex);
      routines.insert(newIndex, routine);
    });
  }

  Future<void> _saveOrder() async {
    final db = ProductDatabase.instance;
    final products = routines.map((r) => r.product).toList();
    await db.updateRoutineOrder(routines.first.routine, products);
    if (mounted) {
      Navigator.pop(context, routines);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reorder ${routines.first.routine.name} routine')),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView(
              onReorder: _onReorder,
              children: [
                for (final product in routines.map((r) => r.product).toList())
                  ListTile(
                    key: ValueKey(product.id),
                    title: Text(product.name),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveOrder,
              child: Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
