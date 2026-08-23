import 'package:flutter/material.dart';
import 'package:frontend/app.dart';
import 'package:frontend/data/traffic_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  trafficState.initialize();
  runApp(const App());
}
