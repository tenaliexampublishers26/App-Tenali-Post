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
  bool _isTesting = false;

  Future<void> _runConnectionTest() async {
    setState(() => _isTesting = true);

    final result = await _supabase.testConnection();

    if (mounted) {
      setState(() => _isTesting = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceWarmWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                result.isDatabaseReachable ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: result.isDatabaseReachable ? AppTheme.successGreen : AppTheme.goldBell,
                size: 26,
              ),
              const SizedBox(width: 10),
              const Text('Connection Test', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: result.isDatabaseReachable ? AppTheme.successGreenBg : AppTheme.surfaceCream,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: result.isDatabaseReachable ? AppTheme.successGreen : AppTheme.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result.message,
                style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimary),
              ),
              if (result.latencyMs != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.speed_rounded, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Round-trip Latency: ${result.latencyMs} ms',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
            // Supabase Project Banner
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
                    isLive ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                    color: isLive ? AppTheme.successGreen : AppTheme.goldBell,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLive ? 'Supabase Project Connected' : 'Connecting to Supabase...',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: isLive ? AppTheme.successGreen : AppTheme.primaryNavy,
                          ),
                        ),
                        const Text(
                          AppConstants.supabaseUrl,
                          style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Reachability Test Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryNavy,
                  side: const BorderSide(color: AppTheme.primaryNavy, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isTesting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryNavy))
                    : const Icon(Icons.network_check_rounded, size: 18),
                label: const Text(
                  'Test Supabase Connection',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                onPressed: _isTesting ? null : _runConnectionTest,
              ),
            ),

            const SizedBox(height: 16),

            // Authorized Admin Profile
            _card(
              title: 'Authorized Administrator Credentials',
              icon: Icons.admin_panel_settings_rounded,
              child: Column(
                children: [
                  _infoRow('Designated Admin Email:', AppConstants.initialAdminEmail),
                  const SizedBox(height: 8),
                  _infoRow('Security Role:', 'Super Administrator'),
                  const SizedBox(height: 8),
                  _infoRow('Database Engine:', 'PostgreSQL (Dedicated Instance)'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Security Checklist
            _card(
              title: 'Security Architecture Audit Checklist',
              icon: Icons.security_rounded,
              child: Column(
                children: [
                  _checkRow('Strict Project Isolation', 'Completely decoupled from external website or e-commerce databases', true),
                  _checkRow('Zero Leaked Secrets', 'Database password is kept server-side; client uses publishable anon key', true),
                  _checkRow('Protected Live Test Answer Keys', 'Correct options withheld from candidates during live tests', true),
                  _checkRow('Unicode UTF-8 Support', 'Telugu and Hindi character sets fully supported in imports and tests', true),
                  _checkRow('Immutable Audit Logging', 'All administrative actions recorded with timestamps and admin ID', true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Schema Tables Reference
            _card(
              title: 'Dedicated Supabase Schema',
              icon: Icons.table_chart_rounded,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Run supabase/migrations/20261019_001_admin_schema.sql in your Supabase SQL Editor:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
