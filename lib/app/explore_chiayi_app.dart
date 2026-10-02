import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../pages/landing_page.dart';

class ExploreChiayiApp extends StatelessWidget {
  const ExploreChiayiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '探索諸羅 Explore Chiayi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.cardBackground,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textTitle,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textTitle,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const LandingPage(),
    );
  }
}
