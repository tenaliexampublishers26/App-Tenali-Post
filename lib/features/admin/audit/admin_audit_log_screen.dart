import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../models/lms_models.dart';
import '../../../providers/lms_admin_provider.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  String _selectedType = 'all';
  String _search = '';

  static const _filters = ['all', 'settings', 'profile', 'mcq', 'live_test', 'notes'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LmsAdminProvider>(context, listen: false).loadAuditLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lms = Provider.of<LmsAdminProvider>(context);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final logs = lms.auditLogs.where((l) {
      final typeOk = _selectedType == 'all' ||
          l.targetType.toLowerCase() == _selectedType.toLowerCase();
      final q = _search.trim().toLowerCase();
      final searchOk = q.isEmpty ||
          l.actionType.toLowerCase().contains(q) ||
          l.targetName.toLowerCase().contains(q) ||
          l.adminEmail.toLowerCase().contains(q);
      return typeOk && searchOk;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Audit History'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => lms.loadAuditLogs(targetType: _selectedType, search: _search),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surfaceWarmWhite,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search action, target, or admin email...',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, idx) {
                      final f = _filters[idx];
                      final selected = _selectedType == f;
                      return ChoiceChip(
                        label: Text(
                          f.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppTheme.primaryNavy,
                          ),
                        ),
                        selected: selected,
                        selectedColor: AppTheme.primaryNavy,
                        onSelected: (_) => setState(() => _selectedType = f),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: logs.isEmpty
                ? const EmptyStateView(
                    icon: Icons.history_edu_rounded,
                    title: 'No Audit Records Found',
                    subtitle: 'Admin mutations and changes will appear here.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, idx) => _AuditLogTile(
                      log: logs[idx],
                      dateLabel: dateFormat.format(logs[idx].createdAt.toLocal()),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  final LmsAuditLog log;
  final String dateLabel;

  const _AuditLogTile({required this.log, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    const encoder = JsonEncoder.withIndent('  ');
    return AdminCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          children: [
            StatusBadge(text: log.actionType, color: AppTheme.primaryNavy),
            const SizedBox(width: 6),
            StatusBadge(text: log.targetType, color: AppTheme.goldBell),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.targetName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${log.adminEmail} • $dateLabel',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${log.locationName} (${log.ipAddress})',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          if (log.previousValue != null) ...[
            const SizedBox(height: 8),
            const Text('Previous:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorRedBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                encoder.convert(log.previousValue),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5),
              ),
            ),
          ],
          if (log.newValue != null) ...[
            const SizedBox(height: 8),
            const Text('New:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successGreenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                encoder.convert(log.newValue),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
