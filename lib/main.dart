import 'package:flutter/material.dart';
import 'app/app_bootstrap.dart';
import 'app/app_widget.dart';

Future<void> main() async {
  await bootstrap();     // Inicializa Supabase + ErrorWidget
  runApp(const HckEggApp());
}
