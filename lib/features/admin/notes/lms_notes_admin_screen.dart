import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/utils/size_formatter.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../models/lms_models.dart';
import '../../../providers/lms_admin_provider.dart';
import '../../notes/protected_pdf_viewer_screen.dart';

class LmsNotesAdminScreen extends StatefulWidget {
  const LmsNotesAdminScreen({super.key});

  @override
  State<LmsNotesAdminScreen> createState() => _LmsNotesAdminScreenState();
}

class _LmsNotesAdminScreenState extends State<LmsNotesAdminScreen> {
  String? _currentFolderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LmsAdminProvider>(context, listen: false).loadNotesAndFolders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lms = Provider.of<LmsAdminProvider>(context);
    final breadcrumbs = lms.getFolderBreadcrumb(_currentFolderId);
    final childFolders = lms.noteFolders.where((f) => f.parentId == _currentFolderId).toList();
    final directNotes = lms.notes.where((n) => n.folderId == _currentFolderId).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Notes & PDF Controls'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            tooltip: 'New Folder',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _showFolderDialog(parentId: _currentFolderId),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => lms.loadNotesAndFolders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb Navigation
          Container(
            width: double.infinity,
            color: AppTheme.surfaceCream,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _crumbChip('Root', () => setState(() => _currentFolderId = null),
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
            child: (childFolders.isEmpty && directNotes.isEmpty)
                ? EmptyStateView(
                    icon: Icons.folder_copy_rounded,
                    title: 'Folder Is Empty',
                    subtitle: 'Create subfolders or upload study PDFs (<= 50MB) with Preview & Download controls.',
                    actionLabel: 'Upload PDF',
                    onAction: _openUploadPdfSheet,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                    children: [
                      if (childFolders.isNotEmpty) ...[
                        const Text('Folders', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        for (final folder in childFolders)
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
                                      const SizedBox(height: 2),
                                      Text(
                                        '${lms.getRecursiveNoteCount(folder.id)} PDFs • ${SizeFormatter.formatBytesToMB(lms.getRecursiveFolderBytes(folder.id))}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    if (action == 'edit') {
                                      _showFolderDialog(existing: folder);
                                    } else if (action == 'subfolder') {
                                      _showFolderDialog(parentId: folder.id);
                                    } else if (action == 'delete') {
                                      await _confirmCascadeDeleteFolder(folder);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Rename / Move')),
                                    PopupMenuItem(value: 'subfolder', child: Text('Create Subfolder')),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete Folder Tree', style: TextStyle(color: AppTheme.errorRed)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                      if (directNotes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('PDF Notes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        for (final note in directNotes)
                          AdminCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.secondaryMaroon),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(note.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                          Text(
                                            '${note.fileSize} • ${note.downloadCount} downloads',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (action) async {
                                        if (action == 'edit') {
                                          _openEditNoteSheet(note);
                                        } else if (action == 'move') {
                                          _openQuickMoveSheet(note);
                                        } else if (action == 'delete') {
                                          await lms.deleteNote(note.id);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Edit / Permissions')),
                                        PopupMenuItem(value: 'move', child: Text('Quick Move Folder')),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete PDF', style: TextStyle(color: AppTheme.errorRed)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    StatusBadge(
                                      text: note.isPreviewable ? 'PREVIEW ON' : 'PREVIEW OFF',
                                      color: note.isPreviewable ? AppTheme.successGreen : AppTheme.errorRed,
                                    ),
                                    StatusBadge(
                                      text: note.allowDownload ? 'DOWNLOAD ON' : 'VIEW ONLY',
                                      color: note.allowDownload ? AppTheme.infoBlue : AppTheme.goldBell,
                                    ),
                                  ],
                                ),
                                const Divider(height: 16, color: AppTheme.borderWarmSubtle),
                                Row(
                                  children: [
                                    const Text('Allow Download', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    Switch(
                                      value: note.allowDownload,
                                      onChanged: (val) => lms.updateNote(note.copyWith(allowDownload: val)),
                                    ),
                                    if (note.isPreviewable)
                                      TextButton.icon(
                                        icon: const Icon(Icons.visibility_rounded, size: 16),
                                        label: const Text('Preview', style: TextStyle(fontSize: 12)),
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProtectedPdfViewerScreen(note: note),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.secondaryMaroon,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload PDF'),
        onPressed: _openUploadPdfSheet,
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

  void _showFolderDialog({NoteFolder? existing, String? parentId}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String? targetParent = existing?.parentId ?? parentId;
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'Create Folder' : 'Rename / Move Folder',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Folder Name *')),
              if (existing != null) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: targetParent,
                  decoration: const InputDecoration(labelText: 'Parent Folder'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Root Directory')),
                    for (final f in lms.noteFolders.where((x) => x.id != existing.id))
                      DropdownMenuItem(value: f.id, child: Text(f.name)),
                  ],
                  onChanged: (v) => setModalState(() => targetParent = v),
                ),
              ],
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  try {
                    if (existing == null) {
                      await lms.createNoteFolder(nameCtrl.text.trim(), targetParent);
                    } else {
                      await lms.updateNoteFolder(existing.id, nameCtrl.text.trim(), targetParent);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                  }
                },
                child: Text(existing == null ? 'Create Folder' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCascadeDeleteFolder(NoteFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${folder.name}" Tree?'),
        content: const Text(
          'Deletes this folder, all subfolders, all PDFs inside, and backing storage objects.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await Provider.of<LmsAdminProvider>(context, listen: false).deleteNoteFolderTree(folder.id);
  }

  void _openUploadPdfSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    Uint8List? pickedBytes;
    String? pickedName;
    bool isPreviewable = true;
    bool allowDownload = false;
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Upload PDF Note (Max 50 MB)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(pickedName ?? 'Select .pdf File'),
                  onPressed: () async {
                    final res = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                      withData: true,
                    );
                    if (res == null || res.files.isEmpty) return;
                    final f = res.files.first;
                    if (f.bytes == null) return;
                    if (f.bytes!.lengthInBytes > SizeFormatter.maxNoteBytes) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('File exceeds 50 MB limit.'),
                          backgroundColor: AppTheme.errorRed,
                        ),
                      );
                      return;
                    }
                    setModalState(() {
                      pickedBytes = f.bytes;
                      pickedName = f.name;
                      if (titleCtrl.text.trim().isEmpty) {
                        titleCtrl.text = f.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow In-App Preview (is_previewable)'),
                  value: isPreviewable,
                  onChanged: (v) => setModalState(() => isPreviewable = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow Download (allow_download)'),
                  value: allowDownload,
                  onChanged: (v) => setModalState(() => allowDownload = v),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: (pickedBytes == null || uploading)
                      ? null
                      : () async {
                          if (titleCtrl.text.trim().isEmpty) return;
                          setModalState(() => uploading = true);
                          try {
                            await Provider.of<LmsAdminProvider>(context, listen: false).uploadNote(
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              folderId: _currentFolderId,
                              fileBytes: pickedBytes!,
                              fileName: pickedName!,
                              isPreviewable: isPreviewable,
                              allowDownload: allowDownload,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setModalState(() => uploading = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed),
                            );
                          }
                        },
                  child: Text(uploading ? 'Uploading...' : 'Upload PDF'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditNoteSheet(PdfMaterial note) {
    final titleCtrl = TextEditingController(text: note.title);
    final descCtrl = TextEditingController(text: note.description);
    bool isPreviewable = note.isPreviewable;
    bool allowDownload = note.allowDownload;
    String? folderId = note.folderId;
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Edit Note & Access Flags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: folderId,
                  decoration: const InputDecoration(labelText: 'Folder'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Root Directory')),
                    for (final f in lms.noteFolders)
                      DropdownMenuItem(value: f.id, child: Text(f.name)),
                  ],
                  onChanged: (v) => setModalState(() => folderId = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('is_previewable'),
                  value: isPreviewable,
                  onChanged: (v) => setModalState(() => isPreviewable = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('allow_download'),
                  value: allowDownload,
                  onChanged: (v) => setModalState(() => allowDownload = v),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await lms.updateNote(
                      note.copyWith(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        folderId: folderId,
                        clearFolderId: folderId == null,
                        isPreviewable: isPreviewable,
                        allowDownload: allowDownload,
                      ),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openQuickMoveSheet(PdfMaterial note) {
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Move PDF to Folder', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Root Directory'),
              onTap: () async {
                Navigator.pop(ctx);
                await lms.updateNote(note.copyWith(clearFolderId: true));
              },
            ),
            for (final f in lms.noteFolders)
              ListTile(
                leading: const Icon(Icons.folder_rounded, color: AppTheme.goldBell),
                title: Text(f.name),
                onTap: () async {
                  Navigator.pop(ctx);
                  await lms.updateNote(note.copyWith(folderId: f.id));
                },
              ),
          ],
        ),
      ),
    );
  }
}
