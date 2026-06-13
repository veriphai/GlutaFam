import 'package:flutter/material.dart';
import 'screens/missions/voltage_and_current/voltage_and_current_screen.dart';
void main() => runApp(const _P());
class _P extends StatelessWidget { const _P();
  @override Widget build(BuildContext c) => const MaterialApp(debugShowCheckedModeBanner: false, home: VoltageAndCurrentScreen()); }
