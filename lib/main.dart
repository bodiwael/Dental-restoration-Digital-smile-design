import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/editor_screen.dart';
import 'core/providers/session_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SmileCraftApp()));
}

class SmileCraftApp extends StatelessWidget {
  const SmileCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmileCraft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/editor': (context) => const EditorScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes if needed
        return null;
      },
    );
  }
}
