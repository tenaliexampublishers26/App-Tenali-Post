import 'package:flutter_test/flutter_test.dart';
import 'package:tenali_post/models/user_profile.dart';
import 'package:tenali_post/services/auth_service.dart';
import 'package:tenali_post/services/announcement_service.dart';
import 'package:tenali_post/providers/auth_provider.dart';
import 'package:tenali_post/providers/notification_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Requirement 2: Registration Validation & Password Matching', () {
    test('Validates email formatting correctly', () {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      expect(emailRegex.hasMatch('test@gmail.com'), isTrue);
      expect(emailRegex.hasMatch('aspirant.postal@india.gov.in'), isTrue);
      expect(emailRegex.hasMatch('not-an-email'), isFalse);
      expect(emailRegex.hasMatch('missing@domain'), isFalse);
    });

    test('Rejects passwords shorter than 6 characters and mismatched passwords', () {
      bool validateRegistration(String name, String email, String pwd, String confirmPwd) {
        if (name.trim().isEmpty) return false;
        if (!email.contains('@')) return false;
        if (pwd.length < 6) return false;
        if (pwd != confirmPwd) return false;
        return true;
      }

      expect(validateRegistration('', 'user@test.com', '123456', '123456'), isFalse);
      expect(validateRegistration('Srikanth', 'invalid', '123456', '123456'), isFalse);
      expect(validateRegistration('Srikanth', 'user@test.com', '12345', '12345'), isFalse);
      expect(validateRegistration('Srikanth', 'user@test.com', '123456', 'different'), isFalse);
      expect(validateRegistration('Srikanth', 'user@test.com', '123456', '123456'), isTrue);
    });
  });

  group('Requirement 3: Mandatory User Profile Completion Enforcement', () {
    test('Profile is incomplete if ANY of the 4 required fields are missing', () {
      // Missing phone and location
      final p1 = UserProfile(
        id: 'u-1',
        email: 'user1@test.com',
        fullName: 'Candidate One',
        phoneNumber: null,
        location: null,
      );
      expect(p1.isProfileComplete, isFalse);

      // Missing phone number only
      final p2 = UserProfile(
        id: 'u-2',
        email: 'user2@test.com',
        fullName: 'Candidate Two',
        phoneNumber: '',
        location: 'Tenali, Andhra Pradesh',
      );
      expect(p2.isProfileComplete, isFalse);

      // Missing location only
      final p3 = UserProfile(
        id: 'u-3',
        email: 'user3@test.com',
        fullName: 'Candidate Three',
        phoneNumber: '9876543210',
        location: '',
      );
      expect(p3.isProfileComplete, isFalse);

      // Empty name
      final p4 = UserProfile(
        id: 'u-4',
        email: 'user4@test.com',
        fullName: '',
        phoneNumber: '9876543210',
        location: 'Tenali',
      );
      expect(p4.isProfileComplete, isFalse);
    });

    test('Profile is complete ONLY when all 4 mandatory fields are present and valid', () {
      final completeProfile = UserProfile(
        id: 'u-complete',
        email: 'candidate@india.gov.in',
        fullName: 'Srikanth Verma',
        phoneNumber: '9876543210',
        location: 'Guntur Division, AP',
      );
      expect(completeProfile.isProfileComplete, isTrue);
    });

    test('AuthProvider accurately signals needsProfileCompletion state', () async {
      final auth = AuthProvider();

      // Initially not authenticated
      expect(auth.isAuthenticated, isFalse);
      expect(auth.needsProfileCompletion, isFalse);

      // User with incomplete profile logs in
      final incompleteUser = UserProfile(
        id: 'inc-01',
        email: 'newuser@india.gov.in',
        fullName: 'New Aspirant',
        phoneNumber: null,
        location: null,
      );
      AuthService().setCurrentUser(incompleteUser);
      await auth.restoreSession();

      expect(auth.isAuthenticated, isTrue);
      expect(auth.isProfileComplete, isFalse);
      expect(auth.needsProfileCompletion, isTrue);

      // User completes profile
      await auth.updateProfile(
        fullName: 'New Aspirant',
        phoneNumber: '9876543210',
        location: 'Tenali Postal Division',
      );

      expect(auth.isProfileComplete, isTrue);
      expect(auth.needsProfileCompletion, isFalse);

      await auth.signOut();
    });
  });

  group('Requirement 4: Profile Persistence across Logout and Subsequent Login', () {
    test('Profile information persists across sign out and subsequent session restore', () async {
      final auth = AuthProvider();

      // Sign in and set full profile
      final user = UserProfile(
        id: 'persist-01',
        email: 'persistent.aspirant@gov.in',
        fullName: 'Ravi Kumar',
        phoneNumber: '9123456780',
        location: 'Vijayawada Circle',
      );
      await AuthService().saveProfile(user);
      AuthService().setCurrentUser(user);
      await auth.restoreSession();

      expect(auth.user?.fullName, 'Ravi Kumar');
      expect(auth.user?.phoneNumber, '9123456780');
      expect(auth.user?.location, 'Vijayawada Circle');

      // Logout
      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.user, isNull);

      // Subsequent session restore
      AuthService().setCurrentUser(user);
      await auth.restoreSession();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.user?.fullName, 'Ravi Kumar');
      expect(auth.user?.phoneNumber, '9123456780');
      expect(auth.user?.location, 'Vijayawada Circle');

      await auth.signOut();
    });
  });

  group('Requirement 7: Admin Account Authorization', () {
    test('Authorizes only the designated email tenaliexampublishers26@gmail.com', () {
      // Exact match
      expect(AuthService.isAuthorizedAdminEmail('tenaliexampublishers26@gmail.com'), isTrue);

      // Case-insensitive check
      expect(AuthService.isAuthorizedAdminEmail('TENALIEXAMPUBLISHERS26@GMAIL.COM'), isTrue);
      expect(AuthService.isAuthorizedAdminEmail('TenaliExamPublishers26@Gmail.Com'), isTrue);

      // Trimmed whitespace check
      expect(AuthService.isAuthorizedAdminEmail('  tenaliexampublishers26@gmail.com  '), isTrue);

      // Rejects regular candidates
      expect(AuthService.isAuthorizedAdminEmail('student@india.gov.in'), isFalse);
      expect(AuthService.isAuthorizedAdminEmail('fakeadmin@gmail.com'), isFalse);
      expect(AuthService.isAuthorizedAdminEmail(null), isFalse);
      expect(AuthService.isAuthorizedAdminEmail(''), isFalse);
    });

    test('Regular user cannot claim admin privileges through editable profile attributes', () async {
      // Normal candidate tries setting role in profile JSON
      final candidate = UserProfile(
        id: 'cand-09',
        email: 'aspirant@india.gov.in',
        fullName: 'Normal Aspirant',
        role: 'admin', // Maliciously spoofed in local model
      );

      final isActuallyAdmin = await AuthService().verifyAdminStatus(candidate.id, candidate.email);
      expect(isActuallyAdmin, isFalse);
    });
  });

  group('Example Email Login Access', () {
    test('Authenticates student@example.com with valid example password and complete profile', () async {
      final auth = AuthProvider();

      final wrongResult = await auth.signInWithPassword('student@example.com', 'WrongPass');
      expect(wrongResult, isFalse);
      expect(auth.isAuthenticated, isFalse);

      final success = await auth.signInWithPassword('student@example.com', 'Password@123');
      expect(success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.isAdmin, isFalse);
      expect(auth.isProfileComplete, isTrue);
      expect(auth.user?.email, 'student@example.com');

      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
    });

    test('Authenticates administrator email with Admin@123 and grants admin access', () async {
      final auth = AuthProvider();

      final success = await auth.signInWithPassword('tenaliexampublishers26@gmail.com', 'Admin@123');
      expect(success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.isAdmin, isTrue);
      expect(auth.isProfileComplete, isTrue);
      expect(auth.user?.role, 'admin');

      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.isAdmin, isFalse);
    });
  });

  group('Requirement 9: Announcements & Notifications System', () {
    test('Manages announcement creation, user unread status, and mark as read', () async {
      final notificationProvider = NotificationProvider();

      await notificationProvider.loadAnnouncements(userId: 'test-user-1', isAdmin: false);
      expect(notificationProvider.announcements, isNotEmpty);

      // Check unread count calculation
      final initialUnread = notificationProvider.unreadCount;
      expect(initialUnread, greaterThanOrEqualTo(1));

      // Mark first as read
      final firstId = notificationProvider.announcements.first.id;
      await notificationProvider.markAsRead(firstId, 'test-user-1');

      final updated = notificationProvider.announcements.firstWhere((a) => a.id == firstId);
      expect(updated.isRead, isTrue);

      // Mark all as read
      await notificationProvider.markAllAsRead('test-user-1');
      expect(notificationProvider.unreadCount, 0);
    });

    test('Admin can create, toggle publish, and delete announcements', () async {
      final service = AnnouncementService();

      // Create
      final announcement = await service.createAnnouncement(
        title: 'Test Exam Alert',
        message: 'Important test instructions for Sunday.',
        isPublished: true,
      );
      expect(announcement.title, 'Test Exam Alert');
      expect(announcement.isPublished, isTrue);

      // Toggle deactivate
      await service.togglePublishStatus(announcement.id, false);
      final adminList = await service.fetchAnnouncements(userId: 'admin-1', isAdmin: true);
      final updated = adminList.firstWhere((a) => a.id == announcement.id);
      expect(updated.isPublished, isFalse);

      // Regular user cannot see deactivated announcement
      final studentList = await service.fetchAnnouncements(userId: 'student-1', isAdmin: false);
      expect(studentList.any((a) => a.id == announcement.id), isFalse);

      // Delete
      await service.deleteAnnouncement(announcement.id);
      final afterDelete = await service.fetchAnnouncements(userId: 'admin-1', isAdmin: true);
      expect(afterDelete.any((a) => a.id == announcement.id), isFalse);
    });
  });
}
