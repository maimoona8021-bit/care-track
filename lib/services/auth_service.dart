import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirestoreService _firestoreService =
  FirestoreService();

  // =====================================================
  // GOOGLE SIGN IN
  // =====================================================

  static final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  static Future<void>? _googleInitialization;

  Future<void> _initializeGoogleSignIn() {
    return _googleInitialization ??=
        _googleSignIn.initialize();
  }

  // =====================================================
  // CREATE ACCOUNT
  // =====================================================

  Future<UserCredential> createAccount({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final UserCredential userCredential =
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user =
        userCredential.user;

    if (user == null) {
      throw Exception(
        'User account could not be created.',
      );
    }

    await user.updateDisplayName(
      fullName.trim(),
    );

    await _firestoreService.createUserProfile(
      uid: user.uid,
      fullName: fullName,
      email: email,
    );

    return userCredential;
  }

  // =====================================================
  // EMAIL + PASSWORD LOGIN
  // =====================================================

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // =====================================================
  // GOOGLE LOGIN
  // =====================================================

  Future<UserCredential>
  signInWithGoogle() async {
    // google_sign_in 7.x must be initialized
    // before authenticate() is called.
    await _initializeGoogleSignIn();

    // Show Google account selector.
    final GoogleSignInAccount googleUser =
    await _googleSignIn.authenticate();

    // Get Google authentication information.
    final GoogleSignInAuthentication
    googleAuthentication =
        googleUser.authentication;

    final String? idToken =
        googleAuthentication.idToken;

    if (idToken == null ||
        idToken.trim().isEmpty) {
      throw Exception(
        'Google Sign-In did not return an ID token.',
      );
    }

    // Create Firebase credential from Google token.
    final AuthCredential credential =
    GoogleAuthProvider.credential(
      idToken: idToken,
    );

    // Authenticate the Google user with Firebase.
    final UserCredential userCredential =
    await _auth.signInWithCredential(
      credential,
    );

    final User? user =
        userCredential.user;

    if (user == null) {
      throw Exception(
        'Google account could not be signed in.',
      );
    }

    // ===================================================
    // GOOGLE USER INFORMATION
    // ===================================================

    String fullName =
        user.displayName?.trim() ??
            googleUser.displayName?.trim() ??
            '';

    String email =
        user.email?.trim() ??
            googleUser.email.trim();

    // Fallback in the unlikely event Google provides
    // no display name.
    if (fullName.isEmpty &&
        email.isNotEmpty) {
      fullName =
          email.split('@').first;
    }

    // ===================================================
    // FIRESTORE PROFILE
    // ===================================================
    //
    // First-time Google users need the same:
    //
    // users/{uid}
    //
    // document as email/password users.
    //
    // Existing users are NOT recreated, which prevents
    // us from replacing existing medical/profile data.
    // ===================================================

    final Map<String, dynamic>?
    existingProfile =
    await _firestoreService
        .getUserProfile();

    if (existingProfile == null) {
      await _firestoreService
          .createUserProfile(
        uid: user.uid,
        fullName: fullName,
        email: email,
      );
    } else {
      // Fill only missing basic information.
      // Existing profile information remains untouched.
      final Map<String, dynamic>
      updates = {};

      final String existingName =
          existingProfile['fullName']
              ?.toString()
              .trim() ??
              '';

      final String existingEmail =
          existingProfile['email']
              ?.toString()
              .trim() ??
              '';

      if (existingName.isEmpty &&
          fullName.isNotEmpty) {
        updates['fullName'] =
            fullName;
      }

      if (existingEmail.isEmpty &&
          email.isNotEmpty) {
        updates['email'] =
            email;
      }

      if (updates.isNotEmpty) {
        await _firestoreService
            .updateUserProfile(
          updates,
        );
      }
    }

    // Keep Firebase display name synchronized.
    final String firebaseDisplayName =
        user.displayName?.trim() ?? '';

    if (firebaseDisplayName.isEmpty &&
        fullName.isNotEmpty) {
      await user.updateDisplayName(
        fullName,
      );

      await user.reload();
    }

    return userCredential;
  }

  // =====================================================
  // RESET PASSWORD
  // =====================================================

  Future<void> resetPassword({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // =====================================================
  // UPDATE DISPLAY NAME
  // =====================================================

  Future<void> updateDisplayName(
      String name,
      ) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    await user.updateDisplayName(
      name.trim(),
    );

    await user.reload();
  }

  // =====================================================
  // CHANGE PASSWORD
  // =====================================================

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final User? user =
        _auth.currentUser;

    if (user == null ||
        user.email == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    final AuthCredential credential =
    EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(
      credential,
    );

    await user.updatePassword(
      newPassword,
    );
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> signOut() async {
    // Sign out from the Google plugin as well.
    // This ensures another Google account can be
    // selected the next time the user signs in.
    try {
      await _initializeGoogleSignIn();

      await _googleSignIn.signOut();
    } catch (_) {
      // Firebase logout must still happen even if
      // Google has no currently authenticated account.
    }

    await _auth.signOut();
  }

  // =====================================================
  // CURRENT USER
  // =====================================================

  User? get currentUser =>
      _auth.currentUser;
}