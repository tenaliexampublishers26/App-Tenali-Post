import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/widgets/admin_ui.dart';
import '../../models/lms_models.dart';
import '../../providers/lms_admin_provider.dart';

class ProtectedPdfViewerScreen extends StatefulWidget {
  final PdfMaterial note;
  const ProtectedPdfViewerScreen({super.key, required this.note});

  @override
  State<ProtectedPdfViewerScreen> createState() => _ProtectedPdfViewerScreenState();
}

class _ProtectedPdfViewerScreenState extends State<ProtectedPdfViewerScreen> {
  Uint8List? _bytes;
  String? _error;
  bool _loading = true;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _applyAndroidFlagSecure();
    _loadPdf();
  }

  Future<void> _applyAndroidFlagSecure() async {
    if (!widget.note.allowDownload &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        await ScreenProtector.protectDataLeakageOn();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    if (!widget.note.allowDownload &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      ScreenProtector.protectDataLeakageOff().catchError((_) {});
    }
    super.dispose();
  }

  Future<void> _loadPdf() async {
    if (!widget.note.isPreviewable) {
      setState(() {
        _error = 'Preview is disabled by the administrator for this document.';
        _loading = false;
      });
      return;
    }

    try {
      final bytes = await Provider.of<LmsAdminProvider>(context, listen: false)
          .fetchNotePreviewBytes(widget.note);
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _handleDownload() async {
    if (!widget.note.allowDownload || _downloading) return;
    setState(() => _downloading = true);
    try {
      final res = await Provider.of<LmsAdminProvider>(context, listen: false)
          .requestNoteDownload(widget.note);
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
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewOnly = !widget.note.allowDownload;

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: Text(widget.note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          if (viewOnly)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: StatusBadge(text: 'VIEW ONLY', color: AppTheme.goldBell),
              ),
            )
          else
            IconButton(
              tooltip: 'Download PDF',
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, color: AppTheme.primaryNavy),
              onPressed: _downloading ? null : _handleDownload,
            ),
        ],
      ),
      body: Column(
        children: [
          if (viewOnly)
            Container(
              width: double.infinity,
              color: AppTheme.goldGradientStart,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: AppTheme.primaryNavy),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Protected View: Downloading and screen capture are disabled.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryNavy),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? EmptyStateView(
                        icon: Icons.lock_outline_rounded,
                        title: 'Preview Unavailable',
                        subtitle: _error!,
                      )
                    : PdfViewer.data(
                        _bytes!,
                        sourceName: widget.note.title,
                      ),
          ),
        ],
      ),
    );
  }
}
