import 'package:flutter/material.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/features/profile/widgets/profile_page_scaffold.dart';
import 'package:sehatfile/services/firestore_service.dart';

class NotificationSettingsScreen
    extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
  });

  @override
  State<NotificationSettingsScreen>
  createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<
        NotificationSettingsScreen> {
  final FirestoreService _firestore =
  FirestoreService();

  bool medicine = true;
  bool appointment = true;
  bool health = true;
  bool records = true;

  bool loading = true;

  @override
  void initState() {
    super.initState();

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data =
    await _firestore.getUserProfile();

    final settings =
    data?['notificationSettings'];

    if (settings is Map) {
      medicine =
          settings['medicine'] ?? true;

      appointment =
          settings['appointment'] ?? true;

      health =
          settings['health'] ?? true;

      records =
          settings['records'] ?? true;
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    await _firestore.updateUserProfile({
      'notificationSettings': {
        'medicine': medicine,
        'appointment': appointment,
        'health': health,
        'records': records,
      },
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Notification settings saved.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'Notifications',
      body: loading
          ? Center(
        child:
        CircularProgressIndicator(
          color: AppColors.primary,
        ),
      )
          : ListView(
        padding:
        const EdgeInsets.all(18),
        children: [
          SwitchListTile(
            value: medicine,
            activeThumbColor:
            AppColors.primary,
            title: const Text(
              'Medicine reminders',
            ),
            subtitle: const Text(
              'Remind me when it is time to take medicine.',
            ),
            onChanged: (value) {
              setState(() {
                medicine = value;
              });
            },
          ),

          SwitchListTile(
            value: appointment,
            activeThumbColor:
            AppColors.primary,
            title: const Text(
              'Appointment reminders',
            ),
            onChanged: (value) {
              setState(() {
                appointment = value;
              });
            },
          ),

          SwitchListTile(
            value: health,
            activeThumbColor:
            AppColors.primary,
            title: const Text(
              'Health reminders',
            ),
            onChanged: (value) {
              setState(() {
                health = value;
              });
            },
          ),

          SwitchListTile(
            value: records,
            activeThumbColor:
            AppColors.primary,
            title: const Text(
              'Record updates',
            ),
            subtitle: const Text(
              'Notify me about changes to my health records.',
            ),
            onChanged: (value) {
              setState(() {
                records = value;
              });
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                AppColors.primary,
              ),
              onPressed: _saveSettings,
              child: const Text(
                'Save Preferences',
              ),
            ),
          ),
        ],
      ),
    );
  }
}