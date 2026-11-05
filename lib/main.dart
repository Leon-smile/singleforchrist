import 'package:flutter/material.dart';
import 'package:mobileappsfc/Theme.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/service/authservice.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'shell.dart';

// Project Settings -> API in your Supabase dashboard.
// The anon key is safe to ship in the app (Row Level Security protects data).
const _supabaseUrl = 'https://gmukhkhkldbzivuhqzdd.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdtdWtoa2hrbGRieml2dWhxemRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMyNzUwNjAsImV4cCI6MjEwODg1MTA2MH0.i28WRwho4blO_BelDUxOm4q1ca1viFLxf87jcvxx-RM';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(const LyricFlowApp());
}

class LyricFlowApp extends StatefulWidget {
  const LyricFlowApp({super.key});

  @override
  State<LyricFlowApp> createState() => _LyricFlowAppState();
}

class _LyricFlowAppState extends State<LyricFlowApp> {
  final _state = AppState();

  @override
  void initState() {
    super.initState();

    // Stay signed in: Supabase restores the saved session on startup (this
    // also covers the return from Google's browser sign in on the web), so
    // skip the Sign in screen when there is one.
    if (AuthService.isSignedIn) {
      _state.signIn();
      AuthService.ensureGoogleProfile();
    }
  }

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
      // AppScope sits ABOVE the Navigator, so pages opened with
      // Navigator.push (Sign up) can also call AppScope.of(context).
      builder: (context, child) =>
          AppScope(state: _state, child: child ?? const SizedBox.shrink()),
      home: const AppShell(),
    );
  }
}
