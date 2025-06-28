import 'package:flutter/material.dart';

abstract class AppPage extends StatelessWidget {
  const AppPage({super.key});
  String get title;
  List<Widget> get scaffoldActions => [];
}
