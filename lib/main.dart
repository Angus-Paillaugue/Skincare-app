import 'package:flutter/material.dart';
import 'router.dart';

void main() {
  runApp(
    MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
    ),
  );
}
