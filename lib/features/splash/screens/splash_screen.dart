import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _checkLoginStatus();
  }Future<void> _checkLoginStatus() async {
    // Keep splash visible for 3 seconds
    await Future.delayed(
      const Duration(seconds: 3),
    );

    if (!mounted) return;

    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User already logged in
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.home,
      );
    } else {
      // User is not logged in
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.register,
      );
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          const Positioned.fill(
            child: _SplashBackground(),
          ),

          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 45),

                  // Decorative top icons
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 45),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DecorativeIcon(
                          icon: Icons.health_and_safety_outlined,
                        ),
                        _DecorativeIcon(
                          icon: Icons.monitor_heart_outlined,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Main logo
                  Image.asset(
                    AppAssets.careTrackLogo,
                    width: 155,
                    height: 155,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 14),

                  // App name
                  Text(
                    'Care Track',
                    style: AppTextStyles.displayLarge,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Your Health. Your Records.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    'Always with you.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Bottom icons
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 55),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _BottomIcon(
                          icon: Icons.shield_outlined,
                        ),
                        _BottomIcon(
                          icon: Icons.cloud_outlined,
                        ),
                        _BottomIcon(
                          icon: Icons.medical_services_outlined,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  Text(
                    'Secure  •  Private  •  Organized',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 65),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeIcon extends StatelessWidget {
  final IconData icon;

  const _DecorativeIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 27,
      color: AppColors.secondaryLight,
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final IconData icon;

  const _BottomIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.secondaryLight,
        ),
      ),
      child: Icon(
        icon,
        size: 23,
        color: AppColors.primary,
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SplashPainter(),
    );
  }
}

class _SplashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top wave
    final topPaint = Paint()
      ..color = AppColors.primaryLight;

    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.14)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.11,
        size.width * 0.48,
        size.height * 0.16,
      )
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.20,
        0,
        size.height * 0.15,
      )
      ..close();

    canvas.drawPath(topPath, topPaint);

    // Light bottom wave
    final lightPaint = Paint()
      ..color = AppColors.splashWaveLight;

    final lightPath = Path()
      ..moveTo(0, size.height * 0.79)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.73,
        size.width * 0.50,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.89,
        size.width,
        size.height * 0.78,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(lightPath, lightPaint);

    // Medium bottom wave
    final mediumPaint = Paint()
      ..color = AppColors.splashWaveMedium;

    final mediumPath = Path()
      ..moveTo(0, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.81,
        size.width * 0.52,
        size.height * 0.90,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.97,
        size.width,
        size.height * 0.85,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(mediumPath, mediumPaint);

    // Dark bottom wave
    final darkPaint = Paint()
      ..color = AppColors.splashWaveDark;

    final darkPath = Path()
      ..moveTo(0, size.height * 0.95)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.88,
        size.width * 0.55,
        size.height * 0.96,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height,
        size.width,
        size.height * 0.92,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(darkPath, darkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}