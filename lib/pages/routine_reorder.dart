import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare/models/routine.dart';
import 'package:skincare/services/product_database.dart';
import 'routine_page.dart';

class RoutineReorderPage extends StatelessWidget {
  final List<Routine> routines;
  const RoutineReorderPage({required this.routines, super.key});

  @override
  Widget build(BuildContext context) {
    return RoutineReorderPageInner(routines: routines);
  }
}

class RoutineReorderPageInner extends StatefulWidget {
  final List<Routine> routines;
  const RoutineReorderPageInner({required this.routines, super.key});

  @override
  State<RoutineReorderPageInner> createState() =>
      _RoutineReorderPageInnerState();
}

class _RoutineReorderPageInnerState extends State<RoutineReorderPageInner> {
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

  Future<void> _saveOrder(BuildContext context) async {
    final db = ProductDatabase.instance;
    final products = routines
        .where((r) => r.product != null)
        .map((r) => r.product!)
        .toList();
    await db.updateRoutineOrder(routines.first.routine, products);
    if (mounted) {
      GoRouter.of(context).pop(routines);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ReorderableListView(
              onReorder: _onReorder,
              children: [
                for (int i = 0; i < routines.length; i++)
                  Padding(
                    key: ValueKey(routines[i].product!.id),
                    padding: EdgeInsets.fromLTRB(
                      0,
                      i != 0 ? 8 : 0,
                      0,
                      i != routines.length - 1 ? 8 : 0,
                    ),
                    child: ProductCard(
                      product: routines[i].product!,
                      showInstructions: true,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _saveOrder(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
