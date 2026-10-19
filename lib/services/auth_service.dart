import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../core/constants.dart';
import 'supabase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<UserProfile?> restoreSession() async {
    final supabase = SupabaseService();
    if (supabase.isInitialized && supabase.client?.auth.currentUser != null) {
      final user = supabase.client!.auth.currentUser!;
      final bool isAdmin = user.email?.toLowerCase() == AppConstants.initialAdminEmail.toLowerCase();
      _currentUser = UserProfile(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] ?? 'Candidate',
        role: isAdmin ? 'admin' : 'student',
        avatarUrl: user.userMetadata?['avatar_url'],
      );
      return _currentUser;
    }
    return null;
  }

  Future<UserProfile> signInWithGoogle() async {
    final supabase = SupabaseService();
    if (supabase.isInitialized && supabase.client != null) {
      try {
        await supabase.client!.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'tenalipost://login-callback',
        );
      } catch (e) {
        if (kDebugMode) print('[AuthService] Google OAuth error: $e');
      }
    }

    // Default demonstration login
    _currentUser = UserProfile(
      id: 'demo-student-01',
      email: 'postal.candidate@india.gov.in',
      fullName: 'Srikanth Verma (MTS Aspirant)',
      phoneNumber: '9876543210',
      postalCircle: 'Andhra Pradesh Circle',
      role: 'student',
    );
    return _currentUser!;
  }

  Future<UserProfile> signInAsAdminDemo() async {
    _currentUser = UserProfile(
      id: 'admin-01',
      email: AppConstants.initialAdminEmail,
      fullName: 'Tenali Postal Academy Admin',
      phoneNumber: '9988776655',
      postalCircle: 'Headquarters',
      role: 'admin',
    );
    return _currentUser!;
  }

  Future<void> signOut() async {
    final supabase = SupabaseService();
    if (supabase.isInitialized && supabase.client != null) {
      try {
        await supabase.client!.auth.signOut();
      } catch (_) {}
    }
    _currentUser = null;
  }
}
