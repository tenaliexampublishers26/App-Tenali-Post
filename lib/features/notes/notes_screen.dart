import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/widgets/admin_ui.dart';
import '../../models/lms_models.dart';
import '../../providers/lms_admin_provider.dart';
import '../../shared/tenali_top_app_bar.dart';
import 'protected_pdf_viewer_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String? _currentFolderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LmsAdminProvider>(context, listen: false).loadNotesAndFolders();
    });
  }

  Future<void> _downloadNote(PdfMaterial note) async {
    try {
      final res = await Provider.of<LmsAdminProvider>(context, listen: false)
          .requestNoteDownload(note);
      if (res.signedUrl != null && res.signedUrl!.isNotEmpty) {
        await launchUrl(Uri.parse(res.signedUrl!), mode: LaunchMode.externalApplication);
      } else if (res.bytes != null) {
        if (kIsWeb) {
          await Share.shareXFiles([
            XFile.fromData(res.bytes!, mimeType: 'application/pdf', name: res.fileName),
          ]);
        } else {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/${res.fileName}');
          await file.writeAsBytes(res.bytes!, flush: true);
          await Share.shareXFiles([XFile(file.path)]);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lms = Provider.of<LmsAdminProvider>(context);
    final breadcrumbs = lms.getFolderBreadcrumb(_currentFolderId);
    final folders = lms.noteFolders.where((f) => f.parentId == _currentFolderId).toList();
    final notes = lms.notes.where((n) => n.folderId == _currentFolderId).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: TenaliTopAppBar(
        title: 'Study Notes',
        extraActions: [
          IconButton(
            tooltip: 'Refresh Notes',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNavy),
            onPressed: () => lms.loadNotesAndFolders(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_currentFolderId != null || lms.noteFolders.isNotEmpty)
            Container(
              width: double.infinity,
              color: AppTheme.surfaceCream,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _crumbChip('All Folders', () => setState(() => _currentFolderId = null),
                        active: _currentFolderId == null),
                    for (final f in breadcrumbs) ...[
                      const Icon(Icons.chevron_right_rounded, size: 16),
                      _crumbChip(
                        f.name,
                        () => setState(() => _currentFolderId = f.id),
                        active: f.id == _currentFolderId,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Expanded(
            child: (folders.isEmpty && notes.isEmpty)
                ? const EmptyStateView(
                    icon: Icons.description_outlined,
                    title: 'No Study Notes Available',
                    subtitle: 'Study notes and revision PDFs uploaded by administrators will appear here.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final folder in folders)
                        AdminCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          onTap: () => setState(() => _currentFolderId = folder.id),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppTheme.surfaceCream,
                                child: Icon(Icons.folder_rounded, color: AppTheme.goldBell),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(folder.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    Text(
                                      '${lms.getRecursiveNoteCount(folder.id)} PDF(s)',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                            ],
                          ),
                        ),
                      for (final note in notes) _buildNoteCard(note),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(PdfMaterial note) {
    final bool canPreview = note.isPreviewable;
    final bool canDownload = note.allowDownload;
    final bool lockedBoth = !canPreview && !canDownload;

    return AdminCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryMaroon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.secondaryMaroon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    if (note.description.isNotEmpty)
                      Text(
                        note.description,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${note.fileSize} • ${note.pagesCount} page(s)',
                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (lockedBoth)
                const StatusBadge(text: 'Restricted by Admin', color: AppTheme.errorRed)
              else if (canPreview && canDownload)
                const StatusBadge(text: 'Download Available', color: AppTheme.successGreen)
              else if (canPreview)
                const StatusBadge(text: 'Preview Only', color: AppTheme.goldBell)
              else
                const StatusBadge(text: 'Download Only', color: AppTheme.infoBlue),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (canPreview)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: const Text('Preview PDF', style: TextStyle(fontSize: 12)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProtectedPdfViewerScreen(note: note)),
                    ),
                  ),
                ),
              if (canPreview && canDownload) const SizedBox(width: 8),
              if (canDownload)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download', style: TextStyle(fontSize: 12)),
                    onPressed: () => _downloadNote(note),
                  ),
                ),
              if (lockedBoth)
                const Expanded(
                  child: Text(
                    'Currently restricted by admin.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _crumbChip(String label, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderWarmSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppTheme.primaryNavy,
          ),
        ),
      ),
    );
  }
}
