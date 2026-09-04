
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  // =====================================================
  // CREATE MAIN USER
  // =====================================================

  Future<void> createUserProfile({
    required String uid,
    required String fullName,
    required String email,
  }) async {
    final String patientId =
        'CT-${uid.substring(0, 6).toUpperCase()}';

    await _firestore
        .collection('users')
        .doc(uid)
        .set(
      {
        'userUid': uid,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'patientId': patientId,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // =====================================================
  // MAIN USER LIVE STREAM
  // =====================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
  userProfileStream() {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots();
  }

  // =====================================================
  // GET MAIN USER
  // =====================================================

  Future<Map<String, dynamic>?>
  getUserProfile() async {
    final User? user = _currentUser;

    if (user == null) {
      return null;
    }

    final document =
    await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    return document.data();
  }

  // =====================================================
  // UPDATE MAIN USER
  // =====================================================

  Future<void> updateUserProfile(
      Map<String, dynamic> data,
      ) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      data,
      SetOptions(
        merge: true,
      ),
    );
  }

  // =====================================================
  // GET ALL CREATED PROFILES
  // =====================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
  profilesStream() {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    return _firestore
        .collection('profiles')
        .where(
      'ownerUid',
      isEqualTo: user.uid,
    )
        .snapshots();
  }

  // =====================================================
  // CREATE PROFILE
  // =====================================================

  Future<void> createProfile({
    required String fullName,
    required String relationship,
    required String gender,
    required String dateOfBirth,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    final DocumentReference<
        Map<String, dynamic>>
    profileRef =
    _firestore
        .collection('profiles')
        .doc();

    final String profileUid =
        profileRef.id;

    final String patientId =
        'CT-${profileUid.substring(0, 6).toUpperCase()}';

    await profileRef.set({
      'profileUid': profileUid,
      'ownerUid': user.uid,
      'fullName': fullName.trim(),
      'relationship': relationship,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'patientId': patientId,
      'createdAt':
      FieldValue.serverTimestamp(),
    });
  }

  // =====================================================
  // STREAM ONE PROFILE
  // =====================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
  profileStream({
    String? profileId,
  }) {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    if (profileId == null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots();
    }

    return _firestore
        .collection('profiles')
        .doc(profileId)
        .snapshots();
  }

  // =====================================================
  // GET ONE PROFILE
  // =====================================================

  Future<Map<String, dynamic>?>
  getProfile({
    String? profileId,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      return null;
    }

    if (profileId == null) {
      final document =
      await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      return document.data();
    }

    final document =
    await _firestore
        .collection('profiles')
        .doc(profileId)
        .get();

    return document.data();
  }

  // =====================================================
  // UPDATE PROFILE
  // =====================================================

  Future<void> updateProfile({
    String? profileId,
    required Map<String, dynamic> data,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    if (profileId == null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        data,
        SetOptions(
          merge: true,
        ),
      );

      return;
    }

    await _firestore
        .collection('profiles')
        .doc(profileId)
        .set(
      data,
      SetOptions(
        merge: true,
      ),
    );
  }

  // =====================================================
  // DELETE CREATED PROFILE
  // =====================================================

  Future<void> deleteProfile({
    required String profileId,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    final DocumentReference<
        Map<String, dynamic>>
    profileRef =
    _firestore
        .collection('profiles')
        .doc(profileId);

    final DocumentSnapshot<
        Map<String, dynamic>>
    profileDocument =
    await profileRef.get();

    if (!profileDocument.exists) {
      throw Exception(
        'Profile does not exist.',
      );
    }

    final Map<String, dynamic>? data =
    profileDocument.data();

    if (data?['ownerUid'] != user.uid) {
      throw Exception(
        'You do not have permission to delete this profile.',
      );
    }

    await profileRef.delete();
  }

  // =====================================================
  // MEDICINE COLLECTION
  // =====================================================

  CollectionReference<Map<String, dynamic>>
  _medicineCollection({
    String? profileId,
  }) {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    if (profileId == null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection(
        'medicines',
      );
    }

    return _firestore
        .collection('profiles')
        .doc(profileId)
        .collection(
      'medicines',
    );
  }

  // =====================================================
  // CREATE MEDICINE
  // =====================================================

  Future<String> createMedicine({
    String? profileId,
    required Map<String, dynamic> data,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    final collection =
    _medicineCollection(
      profileId: profileId,
    );

    final document =
    collection.doc();

    await document.set({
      ...data,
      'medicineId': document.id,
      'ownerUid': user.uid,
      'profileId': profileId,
      'createdAt':
      FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  // =====================================================
  // UPDATE MEDICINE
  // =====================================================

  Future<void> updateMedicine({
    required String medicineId,
    String? profileId,
    required Map<String, dynamic> data,
  }) async {
    await _medicineCollection(
      profileId: profileId,
    ).doc(
      medicineId,
    ).set(
      data,
      SetOptions(
        merge: true,
      ),
    );
  }

  // =====================================================
  // MEDICINE STREAM
  // =====================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
  medicinesStream({
    String? profileId,
  }) {
    return _medicineCollection(
      profileId: profileId,
    ).snapshots();
  }

  // =====================================================
  // DELETE MEDICINE
  // =====================================================

  Future<void> deleteMedicine({
    required String medicineId,
    String? profileId,
  }) async {
    await _medicineCollection(
      profileId: profileId,
    ).doc(
      medicineId,
    ).delete();
  }

  // =====================================================
  // MEDICAL RECORD COLLECTION
  // =====================================================

  CollectionReference<Map<String, dynamic>>
  _recordsCollection({
    String? profileId,
  }) {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    if (profileId == null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection(
        'records',
      );
    }

    return _firestore
        .collection('profiles')
        .doc(profileId)
        .collection(
      'records',
    );
  }

  // =====================================================
  // CREATE RECORD
  // =====================================================

  Future<String> createRecord({
    String? profileId,
    required Map<String, dynamic> data,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    final CollectionReference<
        Map<String, dynamic>>
    collection =
    _recordsCollection(
      profileId: profileId,
    );

    final DocumentReference<
        Map<String, dynamic>>
    document =
    collection.doc();

    await document.set({
      ...data,
      'recordId': document.id,
      'ownerUid': user.uid,
      'profileId': profileId,
      'createdAt':
      FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  // =====================================================
  // RECORDS STREAM
  // =====================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
  recordsStream({
    String? profileId,
  }) {
    return _recordsCollection(
      profileId: profileId,
    )
        .orderBy(
      'recordDate',
      descending: true,
    )
        .snapshots();
  }

  // =====================================================
  // QR SHAREABLE RECORDS STREAM
  // =====================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
  qrShareableRecordsStream({
    String? profileId,
  }) {
    return _recordsCollection(
      profileId: profileId,
    ).snapshots();
  }

  // =====================================================
  // UPDATE RECORD
  // =====================================================

  Future<void> updateRecord({
    required String recordId,
    String? profileId,
    required Map<String, dynamic> data,
  }) async {
    await _recordsCollection(
      profileId: profileId,
    ).doc(
      recordId,
    ).set(
      data,
      SetOptions(
        merge: true,
      ),
    );
  }

  // =====================================================
  // DELETE RECORD
  // =====================================================

  Future<void> deleteRecord({
    required String recordId,
    String? profileId,
  }) async {
    await _recordsCollection(
      profileId: profileId,
    ).doc(
      recordId,
    ).delete();
  }

  // =====================================================
  // QR SETTINGS DOCUMENT
  // =====================================================

  DocumentReference<Map<String, dynamic>>
  _qrSettingsDocument({
    String? profileId,
  }) {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    if (profileId == null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection(
        'qrSettings',
      )
          .doc(
        'sharing',
      );
    }

    return _firestore
        .collection('profiles')
        .doc(profileId)
        .collection(
      'qrSettings',
    )
        .doc(
      'sharing',
    );
  }

  // =====================================================
  // SAVE QR SETTINGS
  //
  // QR SHARING NOW SUPPORTS ONLY:
  // - Full Name
  // - Age
  // - Blood Group
  // - Current Medicines
  // - Medical Documents
  // =====================================================

  Future<void> saveQrSettings({
    String? profileId,
    required Map<String, bool> settings,
    List<String>? selectedDocumentIds,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    final Map<String, dynamic> data = {
      'ownerUid': user.uid,
      'profileId': profileId,

      'fullName':
      settings['fullName'] ?? true,

      'age':
      settings['age'] ?? true,

      'bloodGroup':
      settings['bloodGroup'] ?? true,

      'currentMedicines':
      settings['currentMedicines'] ??
          false,

      'medicalDocuments':
      settings['medicalDocuments'] ??
          false,

      // ===============================================
      // REMOVE OLD QR SETTINGS
      // ===============================================

      'allergies':
      FieldValue.delete(),

      'medicalConditions':
      FieldValue.delete(),

      'emergencyContact':
      FieldValue.delete(),

      'updatedAt':
      FieldValue.serverTimestamp(),
    };

    if (selectedDocumentIds != null) {
      data['selectedRecordIds'] =
          selectedDocumentIds
              .map(
                (id) => id.trim(),
          )
              .where(
                (id) => id.isNotEmpty,
          )
              .toSet()
              .toList();
    }

    await _qrSettingsDocument(
      profileId: profileId,
    ).set(
      data,
      SetOptions(
        merge: true,
      ),
    );
  }

  // =====================================================
  // GET QR SETTINGS
  // =====================================================

  Future<Map<String, bool>>
  getQrSettings({
    String? profileId,
  }) async {
    final snapshot =
    await _qrSettingsDocument(
      profileId: profileId,
    ).get();

    if (!snapshot.exists) {
      return {
        'fullName': true,
        'age': true,
        'bloodGroup': true,
        'currentMedicines': false,
        'medicalDocuments': false,
      };
    }

    final data =
        snapshot.data() ?? {};

    return {
      'fullName':
      data['fullName'] == true,

      'age':
      data['age'] == true,

      'bloodGroup':
      data['bloodGroup'] == true,

      'currentMedicines':
      data['currentMedicines'] ==
          true,

      'medicalDocuments':
      data['medicalDocuments'] ==
          true,
    };
  }

  // =====================================================
  // GET SELECTED QR DOCUMENT IDS
  // =====================================================

  Future<List<String>>
  getQrSelectedDocumentIds({
    String? profileId,
  }) async {
    final snapshot =
    await _qrSettingsDocument(
      profileId: profileId,
    ).get();

    if (!snapshot.exists) {
      return [];
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? {};

    final dynamic rawIds =
    data['selectedRecordIds'];

    if (rawIds is! Iterable) {
      return [];
    }

    return rawIds
        .map(
          (id) =>
          id.toString().trim(),
    )
        .where(
          (id) =>
      id.isNotEmpty,
    )
        .toSet()
        .toList();
  }

  // =====================================================
  // HEALTH SHARE HELPER
  // =====================================================

  String _shareValue(
      dynamic rawValue, {
        String fallback = 'Not added',
      }) {
    if (rawValue == null) {
      return fallback;
    }

    if (rawValue is Iterable) {
      final List<String> values =
      rawValue
          .map(
            (item) =>
            item
                .toString()
                .trim(),
      )
          .where(
            (item) =>
        item.isNotEmpty,
      )
          .toList();

      if (values.isEmpty) {
        return fallback;
      }

      return values.join(
        ', ',
      );
    }

    if (rawValue is Map) {
      final List<String> values = [];

      final String name =
          rawValue['name']
              ?.toString()
              .trim() ??
              '';

      final String phone =
          rawValue['phone']
              ?.toString()
              .trim() ??
              '';

      if (name.isNotEmpty) {
        values.add(name);
      }

      if (phone.isNotEmpty) {
        values.add(phone);
      }

      if (values.isNotEmpty) {
        return values.join(
          ' • ',
        );
      }
    }

    final String value =
    rawValue.toString().trim();

    if (value.isEmpty ||
        value.toLowerCase() ==
            'null') {
      return fallback;
    }

    return value;
  }

  // =====================================================
  // CALCULATE AGE
  // =====================================================

  int? _calculateAge(
      dynamic rawDate,
      ) {
    DateTime? birthDate;

    if (rawDate is Timestamp) {
      birthDate =
          rawDate.toDate();
    } else if (rawDate is DateTime) {
      birthDate =
          rawDate;
    } else {
      final String text =
          rawDate
              ?.toString()
              .trim() ??
              '';

      if (text.isEmpty) {
        return null;
      }

      birthDate =
          DateTime.tryParse(
            text,
          );

      if (birthDate == null) {
        final List<String> parts =
        text.split(
          RegExp(
            r'\s+',
          ),
        );

        if (parts.length == 3) {
          const Map<String, int> months = {
            'jan': 1,
            'feb': 2,
            'mar': 3,
            'apr': 4,
            'may': 5,
            'jun': 6,
            'jul': 7,
            'aug': 8,
            'sep': 9,
            'oct': 10,
            'nov': 11,
            'dec': 12,
          };

          final int? day =
          int.tryParse(
            parts[0],
          );

          final String monthText =
          parts[1]
              .toLowerCase();

          final String shortMonth =
          monthText.length >= 3
              ? monthText.substring(
            0,
            3,
          )
              : monthText;

          final int? month =
          months[shortMonth];

          final int? year =
          int.tryParse(
            parts[2],
          );

          if (day != null &&
              month != null &&
              year != null) {
            try {
              birthDate =
                  DateTime(
                    year,
                    month,
                    day,
                  );
            } catch (_) {
              birthDate = null;
            }
          }
        }
      }
    }

    if (birthDate == null) {
      return null;
    }

    final DateTime today =
    DateTime.now();

    int age =
        today.year -
            birthDate.year;

    final bool birthdayNotReached =
        today.month <
            birthDate.month ||
            (
                today.month ==
                    birthDate.month &&
                    today.day <
                        birthDate.day
            );

    if (birthdayNotReached) {
      age--;
    }

    if (age < 0 ||
        age > 130) {
      return null;
    }

    return age;
  }

  // =====================================================
  // BUILD SHARED HEALTH INFORMATION
  //
  // REMOVED:
  // - Allergies
  // - Medical Conditions
  // - Emergency Contact
  // =====================================================

  Future<Map<String, dynamic>>
  _buildSharedHealthData({
    required String? profileId,
    required Map<String, bool> settings,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    final DocumentSnapshot<
        Map<String, dynamic>>
    profileSnapshot;

    if (profileId == null) {
      profileSnapshot =
      await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
    } else {
      profileSnapshot =
      await _firestore
          .collection(
        'profiles',
      )
          .doc(profileId)
          .get();
    }

    if (!profileSnapshot.exists) {
      throw Exception(
        'Profile does not exist.',
      );
    }

    final Map<String, dynamic>
    profileData =
        profileSnapshot.data() ??
            {};

    final Map<String, dynamic>
    sharedData = {};

    // ===================================================
    // FULL NAME
    // ===================================================

    if (settings['fullName'] ==
        true) {
      sharedData['fullName'] =
          _shareValue(
            profileData['fullName'],
          );
    }

    // ===================================================
    // AGE
    // ===================================================

    if (settings['age'] ==
        true) {
      final dynamic savedAge =
      profileData['age'];

      final String savedAgeText =
      _shareValue(
        savedAge,
        fallback: '',
      );

      if (savedAgeText.isNotEmpty) {
        sharedData['age'] =
            savedAgeText;
      } else {
        final int? calculatedAge =
        _calculateAge(
          profileData['dateOfBirth'],
        );

        sharedData['age'] =
            calculatedAge
                ?.toString() ??
                'Not added';
      }
    }

    // ===================================================
    // BLOOD GROUP
    // ===================================================

    if (settings['bloodGroup'] ==
        true) {
      sharedData['bloodGroup'] =
          _shareValue(
            profileData['bloodGroup'],
          );
    }

    // ===================================================
    // CURRENT MEDICINES
    // ===================================================

    if (settings[
    'currentMedicines'] ==
        true) {
      final QuerySnapshot<
          Map<String, dynamic>>
      medicinesSnapshot =
      await _medicineCollection(
        profileId: profileId,
      )
          .where(
        'isCurrent',
        isEqualTo: true,
      )
          .get();

      final List<String>
      medicineNames = [];

      for (final document
      in medicinesSnapshot.docs) {
        final Map<String, dynamic>
        medicine =
        document.data();

        final String medicineName =
            medicine['medicineName']
                ?.toString()
                .trim() ??
                '';

        final String dosage =
            medicine['dosage']
                ?.toString()
                .trim() ??
                '';

        final String frequency =
            medicine['frequency']
                ?.toString()
                .trim() ??
                '';

        if (medicineName.isEmpty) {
          continue;
        }

        String displayText =
            medicineName;

        if (dosage.isNotEmpty) {
          displayText +=
          ' - $dosage';
        }

        if (frequency.isNotEmpty) {
          displayText +=
          ' ($frequency)';
        }

        medicineNames.add(
          displayText,
        );
      }

      sharedData[
      'currentMedicines'] =
      medicineNames.isEmpty
          ? 'None recorded'
          : medicineNames.join(
        '\n',
      );
    }

    return sharedData;
  }

  // =====================================================
  // BUILD SELECTED MEDICAL DOCUMENTS
  // =====================================================

  Future<List<Map<String, dynamic>>>
  _buildSharedDocuments({
    required String? profileId,
    required Map<String, bool> settings,
    required List<String>
    selectedRecordIds,
  }) async {
    if (settings[
    'medicalDocuments'] !=
        true) {
      return [];
    }

    if (selectedRecordIds.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>>
    sharedDocuments = [];

    for (final String recordId
    in selectedRecordIds) {
      final String cleanedId =
      recordId.trim();

      if (cleanedId.isEmpty) {
        continue;
      }

      final DocumentSnapshot<
          Map<String, dynamic>>
      recordSnapshot =
      await _recordsCollection(
        profileId: profileId,
      ).doc(
        cleanedId,
      ).get();

      if (!recordSnapshot.exists) {
        continue;
      }

      final Map<String, dynamic>
      record =
          recordSnapshot.data() ??
              {};

      final String storagePath =
          record['storagePath']
              ?.toString()
              .trim() ??
              '';

      if (storagePath.isEmpty) {
        continue;
      }

      sharedDocuments.add({
        'recordId':
        recordSnapshot.id,

        'recordTitle':
        record['recordTitle']
            ?.toString()
            .trim() ??
            'Medical Record',

        'recordType':
        record['recordType']
            ?.toString()
            .trim() ??
            'Record',

        'recordDate':
        record['recordDate'],

        'doctorName':
        record['doctorName']
            ?.toString()
            .trim() ??
            '',

        'facilityName':
        record['facilityName']
            ?.toString()
            .trim() ??
            '',

        'description':
        record['description']
            ?.toString()
            .trim() ??
            '',

        'attachmentName':
        record['attachmentName']
            ?.toString()
            .trim() ??
            'Medical document',

        'attachmentType':
        record['attachmentType']
            ?.toString()
            .trim() ??
            '',

        'storagePath':
        storagePath,
      });
    }

    return sharedDocuments;
  }

  // =====================================================
  // CREATE / UPDATE HEALTH SHARE
  // =====================================================

  Future<String>
  getOrCreateHealthShare({
    String? profileId,
    required String profileName,
    required Map<String, bool> settings,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    final DocumentReference<
        Map<String, dynamic>>
    settingsDocument =
    _qrSettingsDocument(
      profileId: profileId,
    );

    final DocumentSnapshot<
        Map<String, dynamic>>
    settingsSnapshot =
    await settingsDocument.get();

    final Map<String, dynamic>
    settingsData =
        settingsSnapshot.data() ??
            {};

    String shareId =
        settingsData['shareId']
            ?.toString()
            .trim() ??
            '';

    // ===================================================
    // SELECTED RECORD IDS
    // ===================================================

    final dynamic
    rawSelectedRecordIds =
    settingsData[
    'selectedRecordIds'];

    final List<String>
    selectedRecordIds =
    rawSelectedRecordIds is Iterable
        ? rawSelectedRecordIds
        .map(
          (id) => id
          .toString()
          .trim(),
    )
        .where(
          (id) =>
      id.isNotEmpty,
    )
        .toSet()
        .toList()
        : [];

    // ===================================================
    // BUILD SHARED HEALTH INFORMATION
    // ===================================================

    final Map<String, dynamic>
    sharedData =
    await _buildSharedHealthData(
      profileId: profileId,
      settings: settings,
    );

    // ===================================================
    // BUILD SHARED DOCUMENTS
    // ===================================================

    final List<
        Map<String, dynamic>>
    sharedDocuments =
    await _buildSharedDocuments(
      profileId: profileId,
      settings: settings,
      selectedRecordIds:
      selectedRecordIds,
    );

    final String
    visibleProfileName =
    settings['fullName'] == true
        ? profileName
        : 'Care Track Patient';

    // ===================================================
    // CREATE NEW SHARE
    // ===================================================

    if (shareId.isEmpty) {
      final DocumentReference<
          Map<String, dynamic>>
      shareDocument =
      _firestore
          .collection(
        'healthShares',
      )
          .doc();

      shareId =
          shareDocument.id;

      await shareDocument.set({
        'shareId':
        shareId,

        'ownerUid':
        user.uid,

        'profileId':
        profileId,

        'profileName':
        visibleProfileName,

        'shareSettings':
        settings,

        'sharedData':
        sharedData,

        'sharedDocuments':
        sharedDocuments,

        // New QR starts active.
        'active':
        true,

        'createdAt':
        FieldValue
            .serverTimestamp(),

        'updatedAt':
        FieldValue
            .serverTimestamp(),
      });

      await settingsDocument.set(
        {
          'shareId':
          shareId,

          'updatedAt':
          FieldValue
              .serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );
    }

    // ===================================================
    // UPDATE EXISTING SHARE
    // ===================================================

    else {
      final DocumentReference<
          Map<String, dynamic>>
      shareDocument =
      _firestore
          .collection(
        'healthShares',
      )
          .doc(
        shareId,
      );

      final DocumentSnapshot<
          Map<String, dynamic>>
      existingShare =
      await shareDocument.get();

      // ===============================================
      // EXISTING SHARE DOCUMENT WAS REMOVED
      // ===============================================

      if (!existingShare.exists) {
        await shareDocument.set({
          'shareId':
          shareId,

          'ownerUid':
          user.uid,

          'profileId':
          profileId,

          'profileName':
          visibleProfileName,

          'shareSettings':
          settings,

          'sharedData':
          sharedData,

          'sharedDocuments':
          sharedDocuments,

          'active':
          true,

          'createdAt':
          FieldValue
              .serverTimestamp(),

          'updatedAt':
          FieldValue
              .serverTimestamp(),
        });
      }

      // ===============================================
      // NORMAL UPDATE
      //
      // IMPORTANT:
      // We DO NOT set active=true here.
      //
      // If user paused the QR, reopening the QR screen
      // must not reactivate sharing automatically.
      // ===============================================

      else {
        await shareDocument.set(
          {
            'shareId':
            shareId,

            'ownerUid':
            user.uid,

            'profileId':
            profileId,

            'profileName':
            visibleProfileName,

            'shareSettings':
            settings,

            'sharedData':
            sharedData,

            'sharedDocuments':
            sharedDocuments,

            'updatedAt':
            FieldValue
                .serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );
      }
    }

    return shareId;
  }

  // =====================================================
  // GET QR SHARING ACTIVE STATUS
  // =====================================================

  Future<bool>
  getHealthShareActive({
    String? profileId,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    final DocumentSnapshot<
        Map<String, dynamic>>
    settingsSnapshot =
    await _qrSettingsDocument(
      profileId: profileId,
    ).get();

    if (!settingsSnapshot.exists) {
      return false;
    }

    final String shareId =
        settingsSnapshot
            .data()?['shareId']
            ?.toString()
            .trim() ??
            '';

    if (shareId.isEmpty) {
      return false;
    }

    final DocumentSnapshot<
        Map<String, dynamic>>
    shareSnapshot =
    await _firestore
        .collection(
      'healthShares',
    )
        .doc(
      shareId,
    )
        .get();

    if (!shareSnapshot.exists) {
      return false;
    }

    return shareSnapshot
        .data()?['active'] ==
        true;
  }

  // =====================================================
  // STOP / RESUME HEALTH QR SHARING
  // =====================================================

  Future<void>
  setHealthShareActive({
    String? profileId,
    required bool active,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    final DocumentSnapshot<
        Map<String, dynamic>>
    settingsSnapshot =
    await _qrSettingsDocument(
      profileId: profileId,
    ).get();

    if (!settingsSnapshot.exists) {
      throw Exception(
        'Health QR settings do not exist.',
      );
    }

    final String shareId =
        settingsSnapshot
            .data()?['shareId']
            ?.toString()
            .trim() ??
            '';

    if (shareId.isEmpty) {
      throw Exception(
        'Health QR has not been created yet.',
      );
    }

    final DocumentReference<
        Map<String, dynamic>>
    shareDocument =
    _firestore
        .collection(
      'healthShares',
    )
        .doc(
      shareId,
    );

    final DocumentSnapshot<
        Map<String, dynamic>>
    shareSnapshot =
    await shareDocument.get();

    if (!shareSnapshot.exists) {
      throw Exception(
        'Health QR share does not exist.',
      );
    }

    final Map<String, dynamic>
    shareData =
        shareSnapshot.data() ??
            {};

    if (shareData['ownerUid'] !=
        user.uid) {
      throw Exception(
        'You do not have permission to change this Health QR.',
      );
    }

    await shareDocument.update({
      'active':
      active,

      'updatedAt':
      FieldValue
          .serverTimestamp(),
    });
  }

  // =====================================================
  // LIVE HEALTH SHARE STREAM
  //
  // We will use this in SharedHealthInfoScreen so that
  // if the owner presses Stop Sharing while another
  // person is already viewing the QR data, access can
  // be removed immediately.
  // =====================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
  healthShareStream({
    required String shareId,
  }) {
    final String cleanedShareId =
    shareId.trim();

    if (cleanedShareId.isEmpty) {
      throw Exception(
        'Health QR share ID is missing.',
      );
    }

    return _firestore
        .collection(
      'healthShares',
    )
        .doc(
      cleanedShareId,
    )
        .snapshots();
  }

  // =====================================================
  // GET HEALTH SHARE FROM QR
  // =====================================================

  Future<Map<String, dynamic>?>
  getHealthShare({
    required String shareId,
  }) async {
    if (shareId.trim().isEmpty) {
      return null;
    }

    final DocumentSnapshot<
        Map<String, dynamic>>
    snapshot =
    await _firestore
        .collection(
      'healthShares',
    )
        .doc(
      shareId.trim(),
    )
        .get();

    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data =
    snapshot.data();

    if (data == null ||
        data['active'] != true) {
      return null;
    }

    return data;
  }

  // =====================================================
  // HEALTH READINGS COLLECTION
  // =====================================================

  CollectionReference<Map<String, dynamic>>
  _healthReadingsCollection({
    String? profileId,
  }) {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    if (profileId == null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection(
        'healthReadings',
      );
    }

    return _firestore
        .collection('profiles')
        .doc(profileId)
        .collection(
      'healthReadings',
    );
  }

  // =====================================================
  // CREATE HEALTH READING
  // =====================================================

  Future<String>
  createHealthReading({
    String? profileId,
    required String readingType,
    required Map<String, dynamic> data,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    final document =
    _healthReadingsCollection(
      profileId: profileId,
    ).doc();

    await document.set({
      ...data,

      'readingId':
      document.id,

      'ownerUid':
      user.uid,

      'profileId':
      profileId,

      'readingType':
      readingType,

      'recordedAt':
      Timestamp.now(),

      'createdAt':
      FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  // =====================================================
  // HEALTH READINGS STREAM
  // =====================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
  healthReadingsStream({
    String? profileId,
  }) {
    return _healthReadingsCollection(
      profileId: profileId,
    )
        .orderBy(
      'recordedAt',
      descending: true,
    )
        .snapshots();
  }

  // =====================================================
  // DELETE HEALTH READING
  // =====================================================

  Future<void>
  deleteHealthReading({
    required String readingId,
    String? profileId,
  }) async {
    await _healthReadingsCollection(
      profileId: profileId,
    ).doc(
      readingId,
    ).delete();
  }

  // =====================================================
  // MEDICINE DOSE LOGS COLLECTION
  // =====================================================

  CollectionReference<Map<String, dynamic>>
  _medicineDoseLogsCollection({
    String? profileId,
  }) {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    if (profileId == null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection(
        'medicineDoseLogs',
      );
    }

    return _firestore
        .collection('profiles')
        .doc(profileId)
        .collection(
      'medicineDoseLogs',
    );
  }

  // =====================================================
  // MEDICINE DOSE LOG ID
  // =====================================================

  String _medicineDoseLogId({
    required String medicineId,
    required String scheduledTime,
    required DateTime date,
  }) {
    final String dateKey =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final String safeTime =
    scheduledTime.replaceAll(
      ':',
      '-',
    );

    return '${medicineId}_${dateKey}_$safeTime';
  }

  // =====================================================
  // SAVE MEDICINE DOSE STATUS
  // =====================================================

  Future<void>
  saveMedicineDoseStatus({
    String? profileId,
    required String medicineId,
    required String medicineName,
    required String scheduledTime,
    required DateTime date,
    required String status,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    if (status != 'taken' &&
        status != 'skipped') {
      throw Exception(
        'Invalid medicine dose status.',
      );
    }

    final String documentId =
    _medicineDoseLogId(
      medicineId: medicineId,
      scheduledTime: scheduledTime,
      date: date,
    );

    final String dateKey =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    await _medicineDoseLogsCollection(
      profileId: profileId,
    ).doc(
      documentId,
    ).set(
      {
        'doseLogId':
        documentId,

        'ownerUid':
        user.uid,

        'profileId':
        profileId,

        'medicineId':
        medicineId,

        'medicineName':
        medicineName,

        'scheduledTime':
        scheduledTime,

        'dateKey':
        dateKey,

        'status':
        status,

        'markedAt':
        Timestamp.now(),

        'updatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // =====================================================
  // TODAY'S MEDICINE DOSE LOGS
  // =====================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
  medicineDoseLogsStream({
    String? profileId,
    required DateTime date,
  }) {
    final String dateKey =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return _medicineDoseLogsCollection(
      profileId: profileId,
    )
        .where(
      'dateKey',
      isEqualTo: dateKey,
    )
        .snapshots();
  }

  // =====================================================
  // REMOVE MEDICINE DOSE STATUS
  // =====================================================

  Future<void>
  clearMedicineDoseStatus({
    String? profileId,
    required String medicineId,
    required String scheduledTime,
    required DateTime date,
  }) async {
    final String documentId =
    _medicineDoseLogId(
      medicineId: medicineId,
      scheduledTime: scheduledTime,
      date: date,
    );

    await _medicineDoseLogsCollection(
      profileId: profileId,
    ).doc(
      documentId,
    ).delete();
  }
}