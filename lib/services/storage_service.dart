import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService._();

  static final StorageService instance =
  StorageService._();

  // =====================================================
  // SUPABASE BUCKET
  // =====================================================

  static const String _bucketName =
      'care-track-files';

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  SupabaseClient get _supabase =>
      Supabase.instance.client;

  // =====================================================
  // CURRENT FIREBASE USER
  // =====================================================

  String get _currentUserUid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in Firebase user.',
      );
    }

    return user.uid;
  }

  // =====================================================
  // CLEAN FILE NAME
  // =====================================================

  String _cleanFileName(
      String fileName,
      ) {
    return fileName
        .trim()
        .replaceAll(' ', '_')
        .replaceAll(
      RegExp(
        r'[^a-zA-Z0-9._-]',
      ),
      '',
    );
  }

  // =====================================================
  // RECORD TYPE FOLDER
  // =====================================================

  String _recordTypeFolder(
      String recordType,
      ) {
    switch (recordType.toLowerCase()) {
      case 'prescription':
        return 'prescriptions';

      case 'lab report':
        return 'lab-reports';

      case 'medical report':
        return 'medical-reports';

      case 'vaccination':
        return 'vaccinations';

      default:
        return 'other';
    }
  }

  // =====================================================
  // CONTENT TYPE
  // =====================================================

  String? _contentType(
      String fileName,
      ) {
    final extension = fileName
        .split('.')
        .last
        .toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'pdf':
        return 'application/pdf';

      default:
        return null;
    }
  }

  // =====================================================
  // UPLOAD MEDICAL RECORD FILE
  // =====================================================

  Future<String> uploadRecordFile({
    required File file,
    required String fileName,
    required String recordType,
    String? profileId,
  }) async {
    final String uid =
        _currentUserUid;

    final String profileFolder =
        profileId ?? 'self';

    final String recordFolder =
    _recordTypeFolder(
      recordType,
    );

    final String safeFileName =
    _cleanFileName(
      fileName,
    );

    final String uniqueFileName =
        '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

    // IMPORTANT:
    // Firebase UID MUST be the first folder.
    //
    // Our Supabase RLS policy checks:
    //
    // storage.foldername(name)[1] == Firebase UID
    //
    final String storagePath =
        '$uid/'
        'records/'
        '$profileFolder/'
        '$recordFolder/'
        '$uniqueFileName';

    await _supabase.storage
        .from(
      _bucketName,
    )
        .upload(
      storagePath,
      file,
      fileOptions: FileOptions(
        contentType:
        _contentType(
          fileName,
        ),
        upsert: false,
      ),
    );

    // We return the STORAGE PATH,
    // not a public URL.
    return storagePath;
  }

  // =====================================================
  // CREATE TEMPORARY SIGNED URL
  // =====================================================

  Future<String> createSignedUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async {
    final String signedUrl =
    await _supabase.storage
        .from(
      _bucketName,
    )
        .createSignedUrl(
      storagePath,
      expiresInSeconds,
    );

    return signedUrl;
  }

  // =====================================================
  // DELETE FILE
  // =====================================================

  Future<void> deleteFile({
    required String storagePath,
  }) async {
    if (storagePath.trim().isEmpty) {
      return;
    }

    await _supabase.storage
        .from(
      _bucketName,
    )
        .remove(
      [
        storagePath,
      ],
    );
  }

  // =====================================================
  // UPLOAD PROFILE IMAGE
  // We will connect this to Profile later.
  // =====================================================

  Future<String> uploadProfileImage({
    required File file,
    required String fileName,
    String? profileId,
  }) async {
    final String uid =
        _currentUserUid;

    final String profileFolder =
        profileId ?? 'self';

    final String safeFileName =
    _cleanFileName(
      fileName,
    );

    final String uniqueFileName =
        '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

    final String storagePath =
        '$uid/'
        'profile-images/'
        '$profileFolder/'
        '$uniqueFileName';

    await _supabase.storage
        .from(
      _bucketName,
    )
        .upload(
      storagePath,
      file,
      fileOptions: FileOptions(
        contentType:
        _contentType(
          fileName,
        ),
        upsert: false,
      ),
    );

    return storagePath;
  }// =====================================================
// GET SECURE SHARED DOCUMENT URL
// =====================================================

  Future<String> getSharedDocumentUrl({
    required String shareId,
    required String storagePath,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be signed in to open a shared document.',
      );
    }

    if (shareId.trim().isEmpty) {
      throw Exception(
        'Health QR share ID is missing.',
      );
    }

    if (storagePath.trim().isEmpty) {
      throw Exception(
        'Document storage path is missing.',
      );
    }

    // Get Firebase ID token for the currently
    // signed-in Care Track user.
    final String? firebaseToken =
    await user.getIdToken();

    if (firebaseToken == null ||
        firebaseToken.trim().isEmpty) {
      throw Exception(
        'Unable to verify your account.',
      );
    }

    // Call the Supabase Edge Function.
    //
    // Verify JWT is OFF on the Supabase gateway,
    // because our function performs custom Firebase
    // authentication itself.
    final response =
    await _supabase.functions.invoke(
      'get-shared-document-url',

      body: {
        'shareId':
        shareId.trim(),

        'storagePath':
        storagePath.trim(),
      },

      headers: {
        'Authorization':
        'Bearer $firebaseToken',
      },
    );

    final dynamic responseData =
        response.data;

    if (responseData is! Map) {
      throw Exception(
        'Invalid document response from server.',
      );
    }

    final Map<String, dynamic> data =
    Map<String, dynamic>.from(
      responseData,
    );

    final String signedUrl =
        data['signedUrl']
            ?.toString()
            .trim() ??
            '';

    if (signedUrl.isNotEmpty) {
      return signedUrl;
    }

    final String errorMessage =
        data['error']
            ?.toString()
            .trim() ??
            '';

    if (errorMessage.isNotEmpty) {
      throw Exception(
        errorMessage,
      );
    }

    throw Exception(
      'Unable to open the shared document.',
    );
  }
}