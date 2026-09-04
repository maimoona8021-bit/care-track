import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =====================================================
  // FIREBASE
  // =====================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // =====================================================
  // SUPABASE
  // Uses the currently logged-in Firebase user's token.
  // =====================================================

  await Supabase.initialize(
    url: 'https://xkuijvlgqfguzpvbnrfe.supabase.co',
    publishableKey:
    'sb_publishable_Gzq3QGTTHR4P-w3qszJrTQ_7Mgn8Fxi',

    accessToken: () async {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        return null;
      }

      return await user.getIdToken();
    },
  );

  // =====================================================
  // NOTIFICATIONS
  // =====================================================

  await NotificationService.instance.initialize();

  // =====================================================
  // START CARE TRACK
  // =====================================================

  runApp(
    const CareTrackApp(),
  );
}