import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare/pages/account.dart';
import 'package:skincare/pages/add_product_page.dart';
import 'package:skincare/pages/edit_product.dart';
import 'package:skincare/pages/home_page.dart';
import 'package:skincare/pages/routine_page.dart';
import 'package:skincare/pages/routine_reorder.dart';
import 'package:skincare/pages/unused_products.dart';
import 'package:skincare/models/product.dart';
import 'package:skincare/models/routine.dart';
import 'package:skincare/models/time.dart';
import 'package:skincare/services/product_database.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomePage()),
          routes: [
            GoRoute(
              path: 'edit-product',
              builder: (context, state) {
                final product = state.extra is Map
                    ? (state.extra as Map)['product'] as Product
                    : null;
                if (product == null) {
                  return const Scaffold(
                    body: Center(child: Text('Product not found')),
                  );
                }
                final routines = state.extra is Map
                    ? (state.extra as Map)['routines'] as List<SkincareTime>
                    : <SkincareTime>[];
                return EditProductPage(product: product, routines: routines);
              },
            ),
            GoRoute(
              path: 'unused-products',
              builder: (context, state) => const UnusedProductsPage(),
            ),
            GoRoute(
              path: 'reorder-routine',
              builder: (context, state) {
                final routines = state.extra is Map
                    ? (state.extra as Map)['routines'] as List<Routine>
                    : <Routine>[];
                return RoutineReorderPage(routines: routines);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/routine',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: RoutineStartPage()),
          routes: [
            GoRoute(
              path: 'routine-inner',
              builder: (context, state) {
                final routines = state.extra is Map
                    ? (state.extra as Map)['routines'] as List<Routine>
                    : <Routine>[];
                final routineTime = state.extra is Map
                    ? (state.extra as Map)['routineTime'] as SkincareTime
                    : SkincareTime.morning;
                return RoutinePageInner(routines, routineTime);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/add',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AddProductPage()),
        ),
        GoRoute(
          path: '/account',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AccountPage()),
        ),
      ],
    ),
  ],
);

final Map<String, String> titles = {
  'home': 'Home',
  'routine': 'Start Routine',
  'add': 'Add Product',
  'account': 'Account',
  'edit-product': 'Edit Product',
  'unused-products': 'Unused Products',
  'reorder-routine': 'Reorder Routine',
  'routine-inner': 'Routine',
};

final Map<String, List<Widget>> actions = {
  'home': [
    Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.category_rounded),
        tooltip: 'Unused Products',
        onPressed: () => context.push('/home/unused-products'),
      ),
    ),
  ],
  'edit-product': [
    Builder(
      builder: (context) {
        final state = GoRouterState.of(context);
        final product = state.extra is Map
            ? (state.extra as Map)['product'] as Product?
            : null;
        if (product == null) {
          return const SizedBox.shrink();
        }
        return IconButton(
          icon: const Icon(Icons.delete_forever_outlined),
          tooltip: 'Delete product',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Product'),
                content: const Text(
                  'Are you sure you want to delete this product?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await ProductDatabase.instance.deleteProduct(product);
              if (context.mounted) {
                GoRouter.of(
                  context,
                ).pop(true); // Correctly pop the edit-product route
              }
            }
          },
        );
      },
    ),
  ],
};

class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({required this.child, super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

extension GoRouterExtension on GoRouter {
  String? get currentRouteName =>
      routerDelegate.currentConfiguration.last.route.name;
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  static const tabs = ['/home', '/routine', '/add', '/account'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(
      context,
    ).uri.toString().split('?').first.split('#').first;
    _currentIndex = tabs.indexWhere((tab) => location.startsWith(tab));
    if (_currentIndex == -1) _currentIndex = 0;

    // Use the last path segment for nested routes
    final segments = GoRouterState.of(context).uri.pathSegments;
    final routeName = segments.isNotEmpty ? segments.last : 'home';

    final title = titles[routeName] ?? '';
    final _actions = actions[routeName] ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: _actions,
        leading: segments.length > 1
            ? BackButton(
                onPressed: () {
                  // Handle back navigation
                  if (GoRouter.of(context).canPop()) {
                    GoRouter.of(context).pop();
                  } else {
                    // If no route to pop, navigate to home
                    GoRouter.of(context).go('/home');
                  }
                },
              )
            : null,
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          if (_currentIndex != idx) context.go(tabs[idx]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            label: 'Routine',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
