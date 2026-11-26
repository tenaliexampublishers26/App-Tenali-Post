import 'dart:math';

class SizeFormatter {
  static const int maxNoteBytes = 50 * 1024 * 1024; // 50 MB

  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${max(1, (bytes / 1024).round())} KB';
  }

  static int parseSizeToBytes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 0;
    final match = RegExp(r'^([\d.]+)\s*([a-zA-Z]+)?$').firstMatch(raw.trim());
    if (match == null) return 0;
    final value = double.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = (match.group(2) ?? 'B').toUpperCase();
    switch (unit) {
      case 'GB':
        return (value * 1024 * 1024 * 1024).round();
      case 'MB':
        return (value * 1024 * 1024).round();
      case 'KB':
        return (value * 1024).round();
      default:
        return value.round();
    }
  }

  static String formatBytesToMB(int bytes) {
    if (bytes <= 0) return '0 MB';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${max(1, (bytes / 1024).round())} KB';
  }

  static String sanitizeStorageKey(String originalFileName) {
    final safeName = originalFileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '_')
        .toLowerCase();
    final rand = Random().nextInt(999999);
    return 'note-${DateTime.now().millisecondsSinceEpoch}-$rand-$safeName';
  }

  static String slugify(String input) {
    final base = input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return base.isEmpty ? 'item-${DateTime.now().millisecondsSinceEpoch}' : base;
  }
}
