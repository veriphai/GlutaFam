import 'package:flutter/material.dart';
import 'screens/missions/what_resistance_is/what_resistance_is_screen.dart';
void main() => runApp(const _P());
class _P extends StatelessWidget { const _P();
  @override Widget build(BuildContext c) => const MaterialApp(debugShowCheckedModeBanner: false, home: WhatResistanceIsScreen()); }
