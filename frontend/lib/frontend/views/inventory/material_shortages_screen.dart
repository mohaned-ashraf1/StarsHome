import 'package:flutter/material.dart';
import 'package:stars_home/frontend/views/shortages/shortages_screen.dart';

/// Backward-compatible bridge to the new Standalone Shortages Module
class MaterialShortagesScreen extends StatelessWidget {
  const MaterialShortagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShortagesScreen();
  }
}
