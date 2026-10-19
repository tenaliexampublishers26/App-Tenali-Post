import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../providers/admin_provider.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadAuditLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm:ss a');

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Administrative Audit Logs'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNavy),
            onPressed: () => admin.loadAuditLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Security Explainer
          Container(
            padding: const EdgeInsets.all(14),
            color: AppTheme.surfaceWarmWhite,
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: AppTheme.primaryNavy, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Immutable audit records tracked for all content creations, modifications, deletions, and student suspensions.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: admin.auditLogs.isEmpty
                ? const Center(child: Text('No audit log entries recorded yet.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: admin.auditLogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final log = admin.auditLogs[idx];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWarmWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderWarmSubtle),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _actionBadge(log.actionType),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppTheme.surfaceCream, borderRadius: BorderRadius.circular(4)),
                                  child: Text(log.targetEntity, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryNavy)),
                                ),
                                const Spacer(),
                                Text(
                                  dateFormat.format(log.timestamp),
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              log.description,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.account_circle_outlined, size: 13, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  log.adminEmail,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                const Spacer(),
                                Text(
                                  'Ref: ${log.targetId}',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _actionBadge(String action) {
    Color color = AppTheme.primaryNavy;
    if (action == 'CREATE' || action == 'IMPORT') color = AppTheme.successGreen;
    if (action == 'DELETE' || action == 'SUSPEND') color = AppTheme.errorRed;
    if (action == 'UPDATE') color = AppTheme.goldBell;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        action,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}
