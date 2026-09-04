import 'package:flutter/material.dart';

import 'package:sehatfile/core/routes/app_routes.dart';
import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/widgets/care_track_bottom_nav.dart';

class ProfilePageScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const ProfilePageScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: body,
      ),

    );
  }
}