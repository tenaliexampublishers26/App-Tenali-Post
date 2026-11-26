import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement.dart';
import 'supabase_service.dart';

class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  SupabaseClient? get _client => SupabaseService().client;

  // Local fallback storage for resilient offline / pre-migration functionality
  final List<Announcement> _localAnnouncements = [
    Announcement(
      id: 'ann-01',
      title: 'Welcome to Tenali Post Preparation Portal',
      message: 'Prepare with confidence for India Post MTS, Postman, Mail Guard, and PA/SA departmental examinations. Complete your profile to access all practice features.',
      isPublished: true,
      publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    Announcement(
      id: 'ann-02',
      title: 'Upcoming Weekly All-India Live Mock Test',
      message: 'The next Live Postal Examination will be conducted this Sunday. Ensure you review the updated Post Office Guide Part 1 syllabus notes.',
      isPublished: true,
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final Set<String> _localReadIds = {};

  /// Fetches announcements with user-specific read status
  Future<List<Announcement>> fetchAnnouncements({
    required String? userId,
    bool isAdmin = false,
  }) async {
    final client = _client;
    if (client == null) {
      return _getLocalAnnouncements(userId, isAdmin);
    }

    try {
      // 1. Fetch announcements
      var query = client.from('announcements').select();
      if (!isAdmin) {
        query = query.eq('is_published', true);
      }
      final response = await query.order('published_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;

      // 2. Fetch read statuses for this user
      final Set<String> readAnnouncementIds = <String>{};
      if (userId != null && userId.isNotEmpty) {
        try {
          final readsResponse = await client
              .from('announcement_reads')
              .select('announcement_id')
              .eq('user_id', userId);
          for (final row in (readsResponse as List<dynamic>)) {
            final aid = row['announcement_id'] as String?;
            if (aid != null) readAnnouncementIds.add(aid);
          }
        } catch (e) {
          if (kDebugMode) {
            print('[AnnouncementService] Could not fetch reads from DB, using local cache: $e');
          }
          readAnnouncementIds.addAll(_localReadIds);
        }
      }

      return data.map((json) {
        final id = json['id']?.toString() ?? '';
        final isRead = readAnnouncementIds.contains(id);
        return Announcement.fromJson(Map<String, dynamic>.from(json), isRead: isRead);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('[AnnouncementService] Error querying Supabase announcements: $e. Falling back to local data.');
      }
      return _getLocalAnnouncements(userId, isAdmin);
    }
  }

  List<Announcement> _getLocalAnnouncements(String? userId, bool isAdmin) {
    return _localAnnouncements
        .where((a) => isAdmin || a.isPublished)
        .map((a) => a.copyWith(isRead: _localReadIds.contains(a.id)))
        .toList();
  }

  /// Marks an announcement as read for the authenticated user
  Future<void> markAsRead(String announcementId, String userId) async {
    _localReadIds.add(announcementId);

    final client = _client;
    if (client == null || userId.isEmpty) return;

    try {
      await client.from('announcement_reads').upsert({
        'announcement_id': announcementId,
        'user_id': userId,
        'read_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('[AnnouncementService] Error upserting read receipt to Supabase: $e');
      }
    }
  }

  /// Marks all visible announcements as read
  Future<void> markAllAsRead(List<String> announcementIds, String userId) async {
    for (final id in announcementIds) {
      _localReadIds.add(id);
    }

    final client = _client;
    if (client == null || userId.isEmpty || announcementIds.isEmpty) return;

    try {
      final records = announcementIds.map((aid) => {
        'announcement_id': aid,
        'user_id': userId,
        'read_at': DateTime.now().toIso8601String(),
      }).toList();

      await client.from('announcement_reads').upsert(records);
    } catch (e) {
      if (kDebugMode) {
        print('[AnnouncementService] Error upserting all read receipts: $e');
      }
    }
  }

  /// Admin: Create announcement
  Future<Announcement> createAnnouncement({
    required String title,
    required String message,
    bool isPublished = true,
    String? createdBy,
  }) async {
    final client = _client;
    final newId = 'ann_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final localItem = Announcement(
      id: newId,
      title: title.trim(),
      message: message.trim(),
      isPublished: isPublished,
      publishedAt: now,
      createdAt: now,
      createdBy: createdBy,
      isRead: false,
    );

    if (client != null) {
      try {
        final inserted = await client.from('announcements').insert({
          'title': title.trim(),
          'message': message.trim(),
          'is_published': isPublished,
          'published_at': now.toIso8601String(),
          'created_at': now.toIso8601String(),
          if (createdBy != null) 'created_by': createdBy,
        }).select().single();

        final created = Announcement.fromJson(Map<String, dynamic>.from(inserted));
        _localAnnouncements.insert(0, created);
        return created;
      } catch (e) {
        if (kDebugMode) {
          print('[AnnouncementService] Supabase insert failed: $e. Storing locally.');
        }
      }
    }

    _localAnnouncements.insert(0, localItem);
    return localItem;
  }

  /// Admin: Update announcement title, message, or published status
  Future<void> updateAnnouncement({
    required String id,
    String? title,
    String? message,
    bool? isPublished,
  }) async {
    final idx = _localAnnouncements.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _localAnnouncements[idx] = _localAnnouncements[idx].copyWith(
        title: title,
        message: message,
        isPublished: isPublished,
      );
    }

    final client = _client;
    if (client != null) {
      try {
        final updates = <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (title != null) updates['title'] = title.trim();
        if (message != null) updates['message'] = message.trim();
        if (isPublished != null) updates['is_published'] = isPublished;

        await client.from('announcements').update(updates).eq('id', id);
      } catch (e) {
        if (kDebugMode) {
          print('[AnnouncementService] Supabase update failed: $e');
        }
      }
    }
  }

  /// Admin: Toggle publish status
  Future<void> togglePublishStatus(String id, bool isPublished) async {
    await updateAnnouncement(id: id, isPublished: isPublished);
  }

  /// Admin: Delete announcement
  Future<void> deleteAnnouncement(String id) async {
    _localAnnouncements.removeWhere((a) => a.id == id);
    _localReadIds.remove(id);

    final client = _client;
    if (client != null) {
      try {
        await client.from('announcements').delete().eq('id', id);
      } catch (e) {
        if (kDebugMode) {
          print('[AnnouncementService] Supabase delete failed: $e');
        }
      }
    }
  }
}
