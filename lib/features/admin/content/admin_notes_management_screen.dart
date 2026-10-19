import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/study_note.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';

class AdminNotesManagementScreen extends StatefulWidget {
  const AdminNotesManagementScreen({super.key});

  @override
  State<AdminNotesManagementScreen> createState() => _AdminNotesManagementScreenState();
}

class _AdminNotesManagementScreenState extends State<AdminNotesManagementScreen> {
  String? _selectedExamId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminEmail = auth.user?.email ?? 'admin@tenalipost.gov.in';

    final notes = _selectedExamId == null || _selectedExamId!.isEmpty
        ? admin.notes
        : admin.notes.where((n) => n.examId == _selectedExamId).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Notes & PDF Management'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNavy),
            onPressed: () => admin.loadNotes(examId: _selectedExamId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Add PDF Note', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => _showNoteDialog(context, admin, adminEmail),
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.surfaceWarmWhite,
            child: Row(
              children: [
                const Text('Filter by Exam:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.bgWarm,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderWarmSubtle),
                    ),
                    child: DropdownButton<String?>(
                      value: _selectedExamId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('All Departmental Exams', style: TextStyle(fontSize: 12)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Exams', style: TextStyle(fontSize: 12))),
                        ...admin.exams.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.code} (${e.title})', style: const TextStyle(fontSize: 12)))),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedExamId = val);
                        admin.loadNotes(examId: val);
                      },
                    ),
                  ),
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
                Text('${notes.length} Study PDF Documents', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const Text('Supabase Secure Storage Supported', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),

          // Notes List
          Expanded(
            child: notes.isEmpty
                ? const Center(child: Text('No notes found for this filter.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final n = notes[idx];
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.goldBorder.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.goldBell, size: 26),
                          ),
                          title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(n.description, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _badge(n.examId.toUpperCase(), AppTheme.primaryNavy),
                                  const SizedBox(width: 6),
                                  _badge('${n.pageCount} Pages', AppTheme.textSecondary),
                                  const SizedBox(width: 6),
                                  _badge(n.fileSize ?? 'PDF', AppTheme.goldBell),
                                  const SizedBox(width: 6),
                                  _badge(n.isFree ? 'FREE' : 'PRO', n.isFree ? AppTheme.successGreen : AppTheme.secondaryMaroon),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryNavy),
                                onPressed: () => _showNoteDialog(context, admin, adminEmail, noteToEdit: n),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorRed),
                                onPressed: () => _confirmDeleteNote(context, admin, n, adminEmail),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, AdminProvider admin, String adminEmail, {StudyNote? noteToEdit}) {
    final titleController = TextEditingController(text: noteToEdit?.title ?? '');
    final descController = TextEditingController(text: noteToEdit?.description ?? '');
    final urlController = TextEditingController(text: noteToEdit?.fileUrl ?? '');
    final pagesController = TextEditingController(text: (noteToEdit?.pageCount ?? 12).toString());
    final sizeController = TextEditingController(text: noteToEdit?.fileSize ?? '1.5 MB');
    String examId = noteToEdit?.examId ?? (admin.exams.isNotEmpty ? admin.exams.first.id : 'mts');
    String lang = noteToEdit?.languageCode ?? 'en';
    bool isFree = noteToEdit?.isFree ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(noteToEdit != null ? 'Edit Study Note' : 'Add PDF Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: examId,
                  decoration: const InputDecoration(labelText: 'Exam Cadre *'),
                  items: admin.exams.map((e) => DropdownMenuItem(value: e.id, child: Text(e.title))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => examId = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Document Title *')),
                const SizedBox(height: 10),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description / Scope')),
                const SizedBox(height: 10),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'PDF URL or Storage Bucket Path *',
                    hintText: 'https://... or notes/mts/po_guide.pdf',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: pagesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Page Count')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(controller: sizeController, decoration: const InputDecoration(labelText: 'File Size (e.g. 2.4 MB)')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: lang,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'te', child: Text('Telugu (తెలుగు)')),
                    DropdownMenuItem(value: 'hi', child: Text('Hindi (हिन्दी)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => lang = val);
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Free for all students', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  value: isFree,
                  onChanged: (val) => setDialogState(() => isFree = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
              onPressed: () async {
                final title = titleController.text.trim();
                final url = urlController.text.trim();
                if (title.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title and Document URL are required.')),
                  );
                  return;
                }

                final note = StudyNote(
                  id: noteToEdit?.id ?? 'n-${DateTime.now().millisecondsSinceEpoch}',
                  examId: examId,
                  title: title,
                  description: descController.text.trim(),
                  fileUrl: url,
                  fileSize: sizeController.text.trim(),
                  pageCount: int.tryParse(pagesController.text.trim()) ?? 1,
                  languageCode: lang,
                  isFree: isFree,
                );

                await admin.saveNote(note, adminEmail: adminEmail);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Note ${noteToEdit != null ? 'updated' : 'added'} successfully.')),
                  );
                }
              },
              child: const Text('Save Document'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteNote(BuildContext context, AdminProvider admin, StudyNote n, String adminEmail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Study Note?'),
        content: Text('Are you sure you want to remove "${n.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await admin.deleteNote(n.id, adminEmail: adminEmail);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Study note deleted successfully.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
