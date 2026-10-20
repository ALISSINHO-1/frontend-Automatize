import 'package:flutter/material.dart';
import '../features/home/presentation/pages/login_screen.dart';
import '../core/theme/app_theme.dart';

class FaculdadeApp extends StatelessWidget {
  const FaculdadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projeto Semestral',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light, 
      
      home: const LoginScreen(), 
    );
  }
}