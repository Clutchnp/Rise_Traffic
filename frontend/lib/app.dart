import 'package:flutter/material.dart';
import 'package:frontend/shell/app_shell.dart';
import 'screens/dashboard_screen.dart';

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RISE AI',
      home: const AppShell(),
    );
  }
}
