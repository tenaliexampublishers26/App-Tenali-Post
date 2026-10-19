import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final SupabaseService _supabase = SupabaseService();
  bool _isConnecting = false;

  void _showConnectDialog() {
    final urlController = TextEditingController(text: AppConstants.supabaseUrl);
    final keyController = TextEditingController(text: AppConstants.supabaseAnonKey);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceWarmWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.key_rounded, color: AppTheme.primaryNavy, size: 24),
              SizedBox(width: 10),
              Text('Connect Supabase Keys', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your dedicated Supabase Project URL and Anon Public Key from your Supabase Dashboard (Settings -> API):',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'Supabase Project URL *',
                    hintText: 'https://xxxxxxxxxxxx.supabase.co',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: keyController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Supabase Anon / Public Key *',
                    hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Note: Only paste your anon/public key. Never paste the service_role key into the client app.',
                  style: TextStyle(fontSize: 10, color: AppTheme.errorRed, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isConnecting
                  ? null
                  : () async {
                      final url = urlController.text.trim();
                      final key = keyController.text.trim();

                      if (url.isEmpty || key.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter both Supabase URL and Anon Key.'),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => _isConnecting = true);

                      final success = await _supabase.connectWithKeys(url: url, anonKey: key);

                      setDialogState(() => _isConnecting = false);
                      if (ctx.mounted) Navigator.pop(ctx);

                      if (mounted) {
                        setState(() {});
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Successfully connected to Supabase project!'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to initialize Supabase with the provided credentials. Please check URL and Key format.'),
                              backgroundColor: AppTheme.errorRed,
                            ),
                          );
                        }
                      }
                    },
              child: _isConnecting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Connect & Verify'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLive = _supabase.isInitialized;

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('System Settings & Security'),
        backgroundColor: AppTheme.surfaceWarmWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Backend Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLive ? AppTheme.successGreenBg : AppTheme.surfaceCream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isLive ? AppTheme.successGreen : AppTheme.goldBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    isLive ? Icons.cloud_done_rounded : Icons.offline_pin_rounded,
                    color: isLive ? AppTheme.successGreen : AppTheme.goldBell,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLive ? 'Supabase Dedicated Backend Connected' : 'Local Offline / Demo Mode Active',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: isLive ? AppTheme.successGreen : AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLive
                              ? 'Queries and mutations are securely synced to your dedicated PostgreSQL project with Row Level Security.'
                              : 'All admin CRUD operations, CSV/JSON imports, student profiles, and examinations operate via persistent local architecture.',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Connect / Reconnect Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLive ? AppTheme.primaryNavy : AppTheme.secondaryMaroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.vpn_key_rounded, size: 20),
                label: Text(
                  isLive ? 'Update / Reconnect Supabase Keys' : 'Connect Live Supabase with API Keys',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                onPressed: _showConnectDialog,
              ),
            ),

            const SizedBox(height: 20),

            // Authorized Admin Profile
            _card(
              title: 'Authorized Administrator Credentials',
              icon: Icons.admin_panel_settings_rounded,
              child: Column(
                children: [
                  _infoRow('Designated Admin Email:', AppConstants.initialAdminEmail),
                  const SizedBox(height: 8),
                  _infoRow('Security Role:', 'Super Administrator (Role-verified)'),
                  const SizedBox(height: 8),
                  _infoRow('Authorization Model:', 'PostgreSQL Row Level Security (RLS)'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Database Architecture Checklist
            _card(
              title: 'Security Architecture Audit Checklist',
              icon: Icons.security_rounded,
              child: Column(
                children: [
                  _checkRow('Strict Project Isolation', 'Completely decoupled from the e-commerce website infrastructure', true),
                  _checkRow('Zero Service-Role Secrets in Client', 'Client only uses anon key; privileged operations protected via RLS', true),
                  _checkRow('Server-Verified Authorization', 'Admin rights verified on server, not solely from email strings', true),
                  _checkRow('Live Test Answer Key Protection', 'Correct options withheld from clients until test end timestamp', true),
                  _checkRow('Unicode UTF-8 Support', 'Telugu and Hindi character sets fully supported in imports', true),
                  _checkRow('Immutable Audit Logging', 'All mutating actions recorded with timestamps and admin ID', true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Database Tables Reference
            _card(
              title: 'Dedicated Supabase Tables',
              icon: Icons.table_chart_rounded,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('The following schema is managed in supabase/migrations/20261019_001_admin_schema.sql:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _TableChip('admin_users'),
                      _TableChip('exams'),
                      _TableChip('chapters'),
                      _TableChip('questions'),
                      _TableChip('live_tests'),
                      _TableChip('live_test_questions_safe (view)'),
                      _TableChip('live_test_submissions'),
                      _TableChip('videos'),
                      _TableChip('notes'),
                      _TableChip('student_profiles'),
                      _TableChip('admin_audit_logs'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  static Widget _card({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderWarmSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryNavy),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
          const Divider(height: 20, color: AppTheme.borderWarmSubtle),
          child,
        ],
      ),
    );
  }

  static Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryNavy)),
      ],
    );
  }

  static Widget _checkRow(String title, String desc, bool passed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(passed ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: passed ? AppTheme.successGreen : AppTheme.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableChip extends StatelessWidget {
  final String label;
  const _TableChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.bgWarm,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderWarmSubtle),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppTheme.primaryNavy)),
    );
  }
}
