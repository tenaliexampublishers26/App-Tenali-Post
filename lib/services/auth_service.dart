import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../core/constants.dart';
import 'supabase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient? get _client => SupabaseService().client;

  UserProfile? _currentUser;
  bool _isAdmin = false;
  bool _isLocalSession = false;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _isAdmin;
  bool get isLocalSession => _isLocalSession;

  /// Checks if given email is the designated administrator email (case-insensitive & trimmed)
  static bool isAuthorizedAdminEmail(String? email) {
    if (email == null) return false;
    final normalized = email.trim().toLowerCase();
    return normalized == AppConstants.authorizedAdminEmail.toLowerCase() ||
        normalized == AppConstants.legacyAdminEmail.toLowerCase();
  }

  /// Restores active session on app startup or page reload
  Future<UserProfile?> restoreSession() async {
    if (_isLocalSession && _currentUser != null) {
      return _currentUser;
    }

    final client = _client;
    if (client == null) {
      return _currentUser;
    }

    try {
      final session = client.auth.currentSession;
      final user = client.auth.currentUser ?? session?.user;

      if (user != null) {
        final profile = await fetchProfile(
          user.id,
          defaultEmail: user.email,
          defaultFullName: user.userMetadata?['full_name'] as String?,
        );
        _currentUser = profile;
        _isAdmin = await verifyAdminStatus(user.id, user.email);
        return _currentUser;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService] Error restoring session: $e');
      }
    }

    return _currentUser;
  }

  /// Sign In with Email & Password using Supabase Auth
  Future<UserProfile> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final client = _client;
    final trimmedEmail = email.trim();

    // Instant access for documented example student credential
    if (trimmedEmail.toLowerCase() == AppConstants.exampleLoginEmail) {
      if (password != AppConstants.exampleLoginPassword) {
        throw const AuthException(
          'Invalid password for ${AppConstants.exampleLoginEmail}. '
          'Use ${AppConstants.exampleLoginPassword}.',
        );
      }
      _isLocalSession = true;
      _isAdmin = false;
      _currentUser = UserProfile(
        id: 'example-student-01',
        email: AppConstants.exampleLoginEmail,
        fullName: 'Example Candidate',
        phoneNumber: '9876543210',
        location: 'Tenali Postal Division',
        postalCircle: 'Andhra Pradesh Circle',
        role: 'student',
      );
      return _currentUser!;
    }

    // Instant access for documented administrator credential
    if (isAuthorizedAdminEmail(trimmedEmail) &&
        password == AppConstants.exampleAdminPassword) {
      _isLocalSession = true;
      _isAdmin = true;
      _currentUser = UserProfile(
        id: 'admin-01',
        email: AppConstants.authorizedAdminEmail,
        fullName: 'Tenali Postal Admin',
        phoneNumber: '9988776655',
        location: 'Headquarters',
        postalCircle: 'Headquarters',
        role: 'admin',
      );
      return _currentUser!;
    }

    if (client == null) {
      // Offline fallback mock session only if client uninitialized
      _isLocalSession = true;
      final adminCheck = isAuthorizedAdminEmail(trimmedEmail);
      _isAdmin = adminCheck;
      _currentUser = UserProfile(
        id: adminCheck ? 'admin-01' : 'user-${trimmedEmail.hashCode}',
        email: trimmedEmail,
        fullName: adminCheck ? 'Tenali Postal Admin' : 'Postal Candidate',
        phoneNumber: null,
        location: null,
        role: adminCheck ? 'admin' : 'student',
      );
      return _currentUser!;
    }

    // Real Supabase Auth signInWithPassword
    final response = await client.auth.signInWithPassword(
      email: trimmedEmail,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Authentication failed: No user returned from server.');
    }

    // Verify backend admin status
    _isAdmin = await verifyAdminStatus(user.id, user.email);

    // Fetch saved profile
    final profile = await fetchProfile(
      user.id,
      defaultEmail: user.email,
      defaultFullName: user.userMetadata?['full_name'] as String?,
    );

    _currentUser = profile;
    return _currentUser!;
  }

  /// User Registration with Full Name, Email, Password
  /// Password is never saved in plaintext or in profile table.
  Future<UserProfile> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final client = _client;
    final trimmedEmail = email.trim();
    final trimmedName = fullName.trim();

    if (client == null) {
      final adminCheck = isAuthorizedAdminEmail(trimmedEmail);
      _isAdmin = adminCheck;
      _currentUser = UserProfile(
        id: 'user-${trimmedEmail.hashCode}',
        email: trimmedEmail,
        fullName: trimmedName,
        role: adminCheck ? 'admin' : 'student',
      );
      return _currentUser!;
    }

    final response = await client.auth.signUp(
      email: trimmedEmail,
      password: password,
      data: {'full_name': trimmedName},
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Registration failed: User could not be created.');
    }

    // Check admin authorization
    _isAdmin = await verifyAdminStatus(user.id, user.email);

    // Save initial profile information with Full Name & Email
    final initialProfile = UserProfile(
      id: user.id,
      email: user.email ?? trimmedEmail,
      fullName: trimmedName,
      role: _isAdmin ? 'admin' : 'student',
    );

    try {
      await saveProfile(initialProfile);
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService] Could not write initial profile to DB: $e');
      }
    }

    _currentUser = initialProfile;
    return initialProfile;
  }

  /// Fetch user profile from Supabase profiles table
  Future<UserProfile> fetchProfile(
    String userId, {
    String? defaultEmail,
    String? defaultFullName,
  }) async {
    final client = _client;
    if (client == null) {
      return _currentUser ??
          UserProfile(
            id: userId,
            email: defaultEmail ?? '',
            fullName: defaultFullName ?? 'Candidate',
          );
    }

    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        return UserProfile.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService] Error fetching profile: $e');
      }
    }

    // Default if not yet written to profiles table
    return UserProfile(
      id: userId,
      email: defaultEmail ?? '',
      fullName: defaultFullName ?? 'Candidate',
      role: _isAdmin ? 'admin' : 'student',
    );
  }

  /// Save or update profile in Supabase profiles table
  Future<UserProfile> saveProfile(UserProfile profile) async {
    final client = _client;
    _currentUser = profile;

    if (client != null && !_isLocalSession) {
      try {
        await client.from('profiles').upsert({
          'id': profile.id,
          'email': profile.email,
          'full_name': profile.fullName.trim(),
          'phone_number': profile.phoneNumber?.trim(),
          'location': profile.location?.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (kDebugMode) {
          print('[AuthService] Supabase profile upsert error: $e');
        }
        rethrow;
      }
    }

    return profile;
  }

  /// Strict backend authorization verification for Administrator access
  /// Checks public.users.role = 'admin', admin_users table, and designated admin email.
  Future<bool> verifyAdminStatus(String userId, String? email) async {
    final client = _client;
    if (client != null) {
      try {
        // 1. Check authoritative public.users table (users.role == 'admin')
        final userRow = await client
            .from('users')
            .select('role')
            .eq('id', userId)
            .maybeSingle();
        if (userRow != null &&
            (userRow['role']?.toString().toLowerCase() == 'admin')) {
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('[AuthService] public.users role check notice: $e');
        }
      }
    }

    if (!isAuthorizedAdminEmail(email)) {
      return false;
    }

    if (client == null) {
      return isAuthorizedAdminEmail(email);
    }

    try {
      // 2. Fallback check admin_users table in Supabase
      final adminRow = await client
          .from('admin_users')
          .select('user_id, role')
          .eq('user_id', userId)
          .maybeSingle();

      if (adminRow != null) {
        return true;
      }

      // 3. If user is verified in auth.users with the designated email
      final currentUserEmail = client.auth.currentUser?.email;
      if (isAuthorizedAdminEmail(currentUserEmail)) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService] Backend admin check error: $e');
      }
      // If table query failed due to schema pending, verify via authenticated JWT email
      final currentUserEmail = client.auth.currentUser?.email;
      return isAuthorizedAdminEmail(currentUserEmail);
    }

    return false;
  }

  /// Sign out
  Future<void> signOut() async {
    final client = _client;
    if (client != null && !_isLocalSession) {
      try {
        await client.auth.signOut();
      } catch (e) {
        if (kDebugMode) {
          print('[AuthService] Error during Supabase signOut: $e');
        }
      }
    }
    _isLocalSession = false;
    _currentUser = null;
    _isAdmin = false;
  }

  /// Test harness helper for student candidate session
  Future<UserProfile> signInAsDemoCandidate({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? postalCircle,
    String? location,
  }) async {
    _isAdmin = false;
    _currentUser = UserProfile(
      id: 'candidate-01',
      email: email ?? 'postal.candidate@india.gov.in',
      fullName: fullName ?? 'Srikanth Verma (Aspirant)',
      phoneNumber: phoneNumber ?? '9876543210',
      location: location ?? postalCircle ?? 'Andhra Pradesh Circle',
      postalCircle: postalCircle ?? location ?? 'Andhra Pradesh Circle',
      role: 'student',
    );
    return _currentUser!;
  }

  /// Test harness helper for administrator session
  Future<UserProfile> signInAsAdminDemo() async {
    _isAdmin = true;
    _currentUser = UserProfile(
      id: 'admin-01',
      email: AppConstants.authorizedAdminEmail,
      fullName: 'Tenali Postal Admin',
      phoneNumber: '9988776655',
      location: 'Headquarters',
      postalCircle: 'Headquarters',
      role: 'admin',
    );
    return _currentUser!;
  }

  /// Local setter for test harness
  void setCurrentUser(UserProfile? user, {bool? isAdmin}) {
    _currentUser = user;
    if (isAdmin != null) {
      _isAdmin = isAdmin;
    } else {
      _isAdmin = user?.isAdmin ?? false;
    }
  }
}
