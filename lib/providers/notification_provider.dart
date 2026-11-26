import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';

class NotificationProvider extends ChangeNotifier {
  final AnnouncementService _service = AnnouncementService();

  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _announcements.where((a) => !a.isRead && a.isPublished).length;

  Future<void> loadAnnouncements({required String? userId, bool isAdmin = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _announcements = await _service.fetchAnnouncements(
        userId: userId,
        isAdmin: isAdmin,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String announcementId, String? userId) async {
    final idx = _announcements.indexWhere((a) => a.id == announcementId);
    if (idx != -1 && !_announcements[idx].isRead) {
      _announcements[idx] = _announcements[idx].copyWith(isRead: true);
      notifyListeners();
    }

    if (userId != null && userId.isNotEmpty) {
      await _service.markAsRead(announcementId, userId);
    }
  }

  Future<void> markAllAsRead(String? userId) async {
    _announcements = _announcements.map((a) => a.copyWith(isRead: true)).toList();
    notifyListeners();

    if (userId != null && userId.isNotEmpty) {
      final ids = _announcements.map((a) => a.id).toList();
      await _service.markAllAsRead(ids, userId);
    }
  }

  Future<bool> createAnnouncement({
    required String title,
    required String message,
    bool isPublished = true,
    String? createdBy,
  }) async {
    try {
      final created = await _service.createAnnouncement(
        title: title,
        message: message,
        isPublished: isPublished,
        createdBy: createdBy,
      );
      _announcements.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAnnouncement({
    required String id,
    String? title,
    String? message,
    bool? isPublished,
  }) async {
    try {
      await _service.updateAnnouncement(
        id: id,
        title: title,
        message: message,
        isPublished: isPublished,
      );
      final idx = _announcements.indexWhere((a) => a.id == id);
      if (idx != -1) {
        _announcements[idx] = _announcements[idx].copyWith(
          title: title,
          message: message,
          isPublished: isPublished,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePublish(String id, bool isPublished) async {
    return updateAnnouncement(id: id, isPublished: isPublished);
  }

  Future<bool> deleteAnnouncement(String id) async {
    try {
      await _service.deleteAnnouncement(id);
      _announcements.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
