import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

class SupabaseConnectionResult {
  final bool isClientInitialized;
  final bool isDatabaseReachable;
  final String status;
  final String message;
  final int? latencyMs;

  const SupabaseConnectionResult({
    required this.isClientInitialized,
    required this.isDatabaseReachable,
    required this.status,
    required this.message,
    this.latencyMs,
  });
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize({String? supabaseUrl, String? supabaseAnonKey}) async {
    if (_isInitialized) return;

    final String url = (supabaseUrl ?? AppConstants.supabaseUrl).trim();
    final String anonKey = (supabaseAnonKey ?? AppConstants.supabaseAnonKey).trim();

    if (url.isNotEmpty && anonKey.isNotEmpty && !url.contains('placeholder')) {
      try {
        await Supabase.initialize(
          url: url,
          publishableKey: anonKey,
        );
        _isInitialized = true;
        if (kDebugMode) {
          print('[SupabaseService] Connected to Supabase project: $url');
        }
      } catch (e) {
        _isInitialized = false;
        if (kDebugMode) {
          print('[SupabaseService] Initialization warning, operating with local fallback: $e');
        }
      }
    } else {
      _isInitialized = false;
    }
  }

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  /// Tests connectivity to the Supabase project
  Future<SupabaseConnectionResult> testConnection() async {
    if (!_isInitialized || client == null) {
      return const SupabaseConnectionResult(
        isClientInitialized: false,
        isDatabaseReachable: false,
        status: 'Client Not Initialized',
        message: 'Supabase client has not been initialized. Check credentials in AppConstants.',
      );
    }

    final stopwatch = Stopwatch()..start();
    try {
      await client!.from('exams').select('id').limit(1);
      stopwatch.stop();

      return SupabaseConnectionResult(
        isClientInitialized: true,
        isDatabaseReachable: true,
        status: 'Online & Verified',
        message: 'Successfully reached Supabase project at ${AppConstants.supabaseUrl} in ${stopwatch.elapsedMilliseconds}ms.',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } on PostgrestException catch (pe) {
      stopwatch.stop();
      final bool isTableMissing = pe.code == '42P01' ||
          pe.code == 'PGRST205' ||
          pe.message.toLowerCase().contains('schema cache') ||
          pe.message.toLowerCase().contains('relation') ||
          pe.message.toLowerCase().contains('does not exist');

      return SupabaseConnectionResult(
        isClientInitialized: true,
        isDatabaseReachable: true,
        status: isTableMissing ? 'Reachable (Schema Pending)' : 'Server Reachable (${pe.code})',
        message: isTableMissing
            ? 'Supabase server reached in ${stopwatch.elapsedMilliseconds}ms! Schema migration is pending. Run supabase/migrations/20261019_001_admin_schema.sql in the SQL Editor.'
            : 'Supabase server responded in ${stopwatch.elapsedMilliseconds}ms: ${pe.message}',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return SupabaseConnectionResult(
        isClientInitialized: true,
        isDatabaseReachable: false,
        status: 'Network Query Failed',
        message: 'Client is initialized, but network query failed after ${stopwatch.elapsedMilliseconds}ms: $e',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
}
