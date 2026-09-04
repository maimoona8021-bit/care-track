import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

class CareTrackApp extends StatelessWidget {
  const CareTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care Track',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}