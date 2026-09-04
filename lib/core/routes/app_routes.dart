import 'package:flutter/material.dart';

import 'package:sehatfile/features/splash/screens/splash_screen.dart';
import 'package:sehatfile/features/auth/screens/login_screen.dart';
import 'package:sehatfile/features/auth/screens/register_screen.dart';
import 'package:sehatfile/features/profile/screens/profiles_screen.dart';
import 'package:sehatfile/features/profile/screens/create_profile_screen.dart';
import 'package:sehatfile/features/profile/screens/profile_screen.dart';
import 'package:sehatfile/features/profile/screens/edit_profile_screen.dart';
import 'package:sehatfile/features/profile/screens/privacy_security_screen.dart';
import 'package:sehatfile/features/profile/screens/change_password_screen.dart';
import 'package:sehatfile/features/profile/screens/notification_settings_screen.dart';
import 'package:sehatfile/features/profile/screens/help_support_screen.dart';
import 'package:sehatfile/features/profile/screens/about_screen.dart';
import '../../features/ home/ screens/home_screen.dart';
import '../../features/ medicines/  screens/medicine_profiles_screen.dart';
import 'package:sehatfile/features/records/screens/record_profiles_screen.dart';
import 'package:sehatfile/features/qr/screens/qr_profiles_screen.dart';
import 'package:sehatfile/features/daily/screens/daily_screen.dart';
import 'package:sehatfile/features/daily/screens/daily_profiles_screen.dart';
import 'package:sehatfile/features/chat/chat_screen.dart';
class AppRoutes {
  AppRoutes._();

  // ==========================================
  // MAIN ROUTES
  // ==========================================

  static const String splash = '/';

  static const String login = '/login';

  static const String register = '/register';

  static const String home = '/home';
  static const String daily = '/daily';
  static const String chat = '/chat';
  // ==========================================
  // PROFILE ROUTES
  // ==========================================

  static const String profile = '/profile';

  static const String editProfile =
      '/profile/edit';

  static const String privacySecurity =
      '/profile/privacy-security';

  static const String changePassword =
      '/profile/change-password';

  static const String notificationSettings =
      '/profile/notifications';

  static const String helpSupport =
      '/profile/help-support';

  static const String about =
      '/profile/about';
  static const String profiles =
      '/profiles';

  static const String createProfile =
      '/profiles/create';
  // ==========================================
  // FUTURE ROUTES
  // ==========================================

  static const String records = '/records';

  static const String medicines = '/medicines';

  static const String qr = '/qr';

  // ==========================================
  // ROUTE MAP
  // ==========================================

  static final Map<String, WidgetBuilder> routes = {
    splash: (context) =>
    const SplashScreen(),

    login: (context) =>
    const LoginScreen(),

    register: (context) =>
    const RegisterScreen(),

    home: (context) =>
    const HomeScreen(),

    // Profile
    profile: (context) =>
    const ProfileScreen(),
    profiles: (context) =>
    const ProfilesScreen(),

    createProfile: (context) =>
    const CreateProfileScreen(),

    editProfile: (context) =>
    const EditProfileScreen(),

    privacySecurity: (context) =>
    const PrivacySecurityScreen(),

    changePassword: (context) =>
    const ChangePasswordScreen(),

    notificationSettings: (context) =>
    const NotificationSettingsScreen(),

    helpSupport: (context) =>
    const HelpSupportScreen(),

    about: (context) =>
    const AboutScreen(),
    medicines: (context) =>
    const MedicineProfilesScreen(),

    // Records, Medicines and QR will be added

    records: (context) =>
    const RecordProfilesScreen(),
    qr: (context) =>
    const QrProfilesScreen(),
    // when their screens are completed.
    daily: (context) => DailyProfilesScreen(),
  };
}