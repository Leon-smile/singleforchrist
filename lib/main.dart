import 'package:flutter/material.dart';
import 'package:mobileappsfc/Theme.dart';
import 'package:mobileappsfc/app_state.dart';

import 'shell.dart';

void main() => runApp(const LyricFlowApp());

class LyricFlowApp extends StatefulWidget {
  const LyricFlowApp({super.key});

  @override
  State<LyricFlowApp> createState() => _LyricFlowAppState();
}

class _LyricFlowAppState extends State<LyricFlowApp> {
  final _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LyricFlow',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: AppScope(state: _state, child: const AppShell()),
    );
  }
}
