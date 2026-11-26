import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../models/lms_models.dart';
import '../../../providers/lms_admin_provider.dart';

class LmsSettingsScreen extends StatefulWidget {
  const LmsSettingsScreen({super.key});

  @override
  State<LmsSettingsScreen> createState() => _LmsSettingsScreenState();
}

class _LmsSettingsScreenState extends State<LmsSettingsScreen> {
  late bool _mcqEnabled;
  late bool _liveTestEnabled;
  late bool _maintenanceMode;
  late bool _notifEnabled;
  final TextEditingController _notifTextCtrl = TextEditingController();
  final TextEditingController _notifLinkCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = Provider.of<LmsAdminProvider>(context, listen: false).settings;
    _mcqEnabled = s.mcqEnabled;
    _liveTestEnabled = s.liveTestEnabled;
    _maintenanceMode = s.maintenanceMode;
    _notifEnabled = s.liveNotificationEnabled;
    _notifTextCtrl.text = s.liveNotificationText;
    _notifLinkCtrl.text = s.liveNotificationLink;
  }

  @override
  void dispose() {
    _notifTextCtrl.dispose();
    _notifLinkCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);
    setState(() => _saving = true);
    try {
      await lms.updateSettings(
        LmsSettings(
          mcqEnabled: _mcqEnabled,
          liveTestEnabled: _liveTestEnabled,
          maintenanceMode: _maintenanceMode,
          liveNotificationEnabled: _notifEnabled,
          liveNotificationText: _notifTextCtrl.text.trim(),
          liveNotificationLink: _notifLinkCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Global LMS settings updated and logged.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('LMS Controls & Settings'),
        backgroundColor: AppTheme.surfaceWarmWhite,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Global LMS Feature Switches',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Toggle student access across MCQ Practice, Live Tests, and Maintenance Mode.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const Divider(height: 20, color: AppTheme.borderWarmSubtle),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('MCQ Practice Module', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(
                    _mcqEnabled ? 'Active for students' : 'Shows "Coming Soon" screen',
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: _mcqEnabled,
                  onChanged: (v) => setState(() => _mcqEnabled = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Live Tests Module', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(
                    _liveTestEnabled ? 'Published live tests visible' : 'Live tests hidden from students',
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: _liveTestEnabled,
                  onChanged: (v) => setState(() => _liveTestEnabled = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppTheme.errorRed,
                  title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(
                    _maintenanceMode ? 'Student portal paused for maintenance' : 'Normal operation',
                    style: TextStyle(
                      fontSize: 11,
                      color: _maintenanceMode ? AppTheme.errorRed : AppTheme.textSecondary,
                    ),
                  ),
                  value: _maintenanceMode,
                  onChanged: (v) => setState(() => _maintenanceMode = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Notification Banner',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Flash Notification Banner', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  value: _notifEnabled,
                  onChanged: (v) => setState(() => _notifEnabled = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notifTextCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Banner Announcement Text',
                    hintText: 'e.g., Weekly All-India Postal Mock Test is now LIVE!',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notifLinkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Optional Deep Link / Route',
                    hintText: '/live-tests or https://...',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.verified_user_rounded),
            label: Text(_saving ? 'Saving...' : 'Save Settings'),
            onPressed: _saving ? null : _saveSettings,
          ),
        ],
      ),
    );
  }
}
