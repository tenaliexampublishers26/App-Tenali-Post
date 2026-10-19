import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/student_record.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';

class AdminStudentManagementScreen extends StatefulWidget {
  const AdminStudentManagementScreen({super.key});

  @override
  State<AdminStudentManagementScreen> createState() => _AdminStudentManagementScreenState();
}

class _AdminStudentManagementScreenState extends State<AdminStudentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminEmail = auth.user?.email ?? 'admin@tenalipost.gov.in';

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Student & Profile Management'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.primaryNavy),
            tooltip: 'Export Student Roster (CSV)',
            onPressed: () {
              final csv = admin.exportStudentsCsv();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Export Students Roster'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Student CSV data ready for download/export.')),
                        );
                      },
                      child: const Text('Copy / Download'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNavy),
            onPressed: () => admin.loadStudents(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: AppTheme.surfaceWarmWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by student name, email, phone...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              admin.setStudentSearch('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    fillColor: AppTheme.bgWarm,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderWarmSubtle),
                    ),
                  ),
                  onChanged: (val) => admin.setStudentSearch(val),
                ),
                const SizedBox(height: 10),

                // Filters: Circle and Status
                Row(
                  children: [
                    // Circle Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.bgWarm,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderWarmSubtle),
                        ),
                        child: DropdownButton<String>(
                          value: admin.studentCircleFilter,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'All Circles', child: Text('All Postal Circles', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Andhra Pradesh Circle', child: Text('Andhra Pradesh', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Telangana Circle', child: Text('Telangana', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Karnataka Circle', child: Text('Karnataka', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Maharashtra Circle', child: Text('Maharashtra', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) admin.setStudentCircle(val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.bgWarm,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderWarmSubtle),
                        ),
                        child: DropdownButton<String>(
                          value: admin.studentStatusFilter,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'All Status', child: Text('All Status', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Active', child: Text('Active Only', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'Suspended', child: Text('Suspended Only', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) admin.setStudentStatus(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total Count Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.bgWarm,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${admin.students.length} Registered Aspirants',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                ),
                const Text('Tap student card to view full profile & attempts', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: admin.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryMaroon))
                : admin.students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 54, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            const Text('No students match your filter criteria.', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                admin.setStudentSearch('');
                                admin.setStudentCircle('All Circles');
                                admin.setStudentStatus('All Status');
                              },
                              child: const Text('Reset Filters'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: admin.students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final stu = admin.students[idx];
                          return _studentCard(context, stu, admin, adminEmail);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _studentCard(BuildContext context, StudentRecord s, AdminProvider admin, String adminEmail) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderWarmSubtle),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.08),
          child: Text(
            s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'C',
            style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryNavy, fontSize: 16),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                s.fullName,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: s.isActive ? AppTheme.successGreenBg : AppTheme.errorRedBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: s.isActive ? AppTheme.successGreen : AppTheme.errorRed,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(s.email, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCream,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(s.targetExam, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryNavy)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.postalCircle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
        onTap: () => _openStudentDetailsModal(context, s, admin, adminEmail),
      ),
    );
  }

  void _openStudentDetailsModal(BuildContext context, StudentRecord s, AdminProvider admin, String adminEmail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StudentProfileSheet(student: s, admin: admin, adminEmail: adminEmail),
    );
  }
}

class _StudentProfileSheet extends StatefulWidget {
  final StudentRecord student;
  final AdminProvider admin;
  final String adminEmail;

  const _StudentProfileSheet({
    required this.student,
    required this.admin,
    required this.adminEmail,
  });

  @override
  State<_StudentProfileSheet> createState() => _StudentProfileSheetState();
}

class _StudentProfileSheetState extends State<_StudentProfileSheet> {
  late String _circle;
  late String _targetExam;

  @override
  void initState() {
    super.initState();
    _circle = widget.student.postalCircle;
    _targetExam = widget.student.targetExam;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWarmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.borderWarmSubtle, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryNavy,
                  child: Text(
                    s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'C',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
                      Text(s.email, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      Text('User ID: ${s.id}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: s.isActive ? AppTheme.successGreenBg : AppTheme.errorRedBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: s.isActive ? AppTheme.successGreen : AppTheme.errorRed),
                  ),
                  child: Text(
                    s.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: s.isActive ? AppTheme.successGreen : AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24, color: AppTheme.borderWarmSubtle),

            // Student Performance Stats
            Row(
              children: [
                Expanded(child: _perfCard('Tests Attempted', '${s.totalTestsAttempted}', Icons.assignment_turned_in_rounded, AppTheme.primaryNavy)),
                const SizedBox(width: 10),
                Expanded(child: _perfCard('Avg Score', '${s.averagePercentage.toStringAsFixed(1)}%', Icons.score_rounded, AppTheme.successGreen)),
                const SizedBox(width: 10),
                Expanded(child: _perfCard('Status', s.status, Icons.verified_user_rounded, s.isActive ? AppTheme.successGreen : AppTheme.errorRed)),
              ],
            ),

            const SizedBox(height: 16),

            // Registration & Activity timestamps
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgWarm,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderWarmSubtle),
              ),
              child: Column(
                children: [
                  _metaRow('Registered On:', dateFormat.format(s.registeredAt)),
                  const SizedBox(height: 6),
                  _metaRow('Last Active:', dateFormat.format(s.lastActiveAt)),
                  const SizedBox(height: 6),
                  _metaRow('Mobile Contact:', s.phoneNumber.isNotEmpty ? s.phoneNumber : 'Not provided'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Permitted Profile Fields Editor
            const Text('Permitted Profile Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _circle,
              decoration: const InputDecoration(labelText: 'Postal Circle'),
              items: const [
                DropdownMenuItem(value: 'Andhra Pradesh Circle', child: Text('Andhra Pradesh Circle')),
                DropdownMenuItem(value: 'Telangana Circle', child: Text('Telangana Circle')),
                DropdownMenuItem(value: 'Karnataka Circle', child: Text('Karnataka Circle')),
                DropdownMenuItem(value: 'Maharashtra Circle', child: Text('Maharashtra Circle')),
                DropdownMenuItem(value: 'All Circles', child: Text('All Circles')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _circle = val);
              },
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              initialValue: _targetExam,
              decoration: const InputDecoration(labelText: 'Target Exam Cadre'),
              items: const [
                DropdownMenuItem(value: 'MTS Examination', child: Text('MTS Examination')),
                DropdownMenuItem(value: 'Postman & Mail Guard', child: Text('Postman & Mail Guard')),
                DropdownMenuItem(value: 'PA / SA Examination', child: Text('PA / SA Examination')),
                DropdownMenuItem(value: 'LGO Examination', child: Text('LGO Examination')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _targetExam = val);
              },
            ),

            const SizedBox(height: 16),

            // Recent Test Attempt History
            const Text('Examination History & Attempts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),

            if (s.testAttempts.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(color: AppTheme.bgWarm, borderRadius: BorderRadius.circular(10)),
                child: const Text('No live test attempts recorded for this student yet.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              )
            else
              ...s.testAttempts.map((attempt) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgWarm,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderWarmSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded, size: 20, color: AppTheme.secondaryMaroon),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(attempt.testId, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            Text(
                              'Score: ${attempt.marksObtained} / ${attempt.totalMarks} (${attempt.percentage.toStringAsFixed(1)}%) • Rank #${attempt.rank}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yy').format(attempt.submittedAt),
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Actions: Save Profile & Suspend/Activate
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await widget.admin.updateStudentProfile(
                        s.id,
                        postalCircle: _circle,
                        targetExam: _targetExam,
                        adminEmail: widget.adminEmail,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Student profile updated successfully.')),
                        );
                      }
                    },
                    child: const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: s.isActive ? AppTheme.errorRed : AppTheme.successGreen,
                    side: BorderSide(color: s.isActive ? AppTheme.errorRed : AppTheme.successGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await widget.admin.toggleStudentStatus(s.id, adminEmail: widget.adminEmail);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Student status changed to ${s.isActive ? 'Suspended' : 'Active'}')),
                      );
                    }
                  },
                  child: Text(s.isActive ? 'Suspend' : 'Activate', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _perfCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      ],
    );
  }
}
