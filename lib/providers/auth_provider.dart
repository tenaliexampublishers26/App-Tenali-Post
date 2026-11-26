import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserProfile? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _user = _authService.currentUser;
  }

  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _authService.isAdmin || (_user?.isAdmin ?? false);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Mandatory Profile Completion Check
  /// True if user is logged in but has missing Full Name, Email, Phone, or Location
  bool get isProfileComplete => _user?.isProfileComplete ?? false;
  bool get needsProfileCompletion => isAuthenticated && !isProfileComplete;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.restoreSession();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign In with Email & Password
  Future<bool> signInWithPassword(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authService.signInWithPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register new user with Full Name, Email, Password
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authService.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('over_email_send_rate_limit') || msg.contains('email rate limit')) {
        _errorMessage = 'Supabase email rate limit exceeded (shared free limit is 3 emails/hr). Please turn OFF "Confirm email" in your Supabase Dashboard (Authentication -> Providers -> Email) to allow instant registration without email limits.';
      } else {
        _errorMessage = msg.replaceAll('Exception: ', '').replaceAll('AuthException: ', '').replaceAll('AuthApiException: ', '');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update Profile information (Full Name, Phone Number, Location)
  Future<bool> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String location,
  }) async {
    if (_user == null) {
      _errorMessage = 'No authenticated user to update profile for.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = _user!.copyWith(
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        location: location.trim(),
        postalCircle: location.trim(),
      );

      final saved = await _authService.saveProfile(updated);
      _user = saved;
      return true;
    } on PostgrestException catch (pe) {
      _errorMessage = pe.message;
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('PostgrestException: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Backward-compatible candidate sign in for unit tests
  Future<bool> signInAsDemoCandidate({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? postalCircle,
    String? location,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = UserProfile(
        id: 'candidate-01',
        email: email ?? 'postal.candidate@india.gov.in',
        fullName: fullName ?? 'Srikanth Verma (Aspirant)',
        phoneNumber: phoneNumber ?? '9876543210',
        location: location ?? postalCircle ?? 'Andhra Pradesh Circle',
        postalCircle: postalCircle ?? location ?? 'Andhra Pradesh Circle',
        role: 'student',
      );
      _authService.setCurrentUser(_user, isAdmin: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Backward-compatible admin sign in for unit tests
  Future<bool> signInAsAdminDemo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = UserProfile(
        id: 'admin-01',
        email: 'tenaliexampublishers26@gmail.com',
        fullName: 'Tenali Postal Admin',
        phoneNumber: '9988776655',
        location: 'Headquarters',
        postalCircle: 'Headquarters',
        role: 'admin',
      );
      _authService.setCurrentUser(_user, isAdmin: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
