import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_service.dart';

/// Lightweight, centralized Supabase service for V-Hab.
/// Handles authentication, profiles, exercise sessions, progress,
/// and dashboard statistics with graceful offline fallback.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  bool _isInitialized = false;
  String? _configuredUrl;
  String? _configuredAnonKey;

  bool get isConfigured =>
      _isInitialized &&
      _configuredUrl != null &&
      _configuredUrl!.isNotEmpty &&
      _configuredAnonKey != null &&
      _configuredAnonKey!.isNotEmpty;

  SupabaseClient? get client {
    if (!isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => client?.auth.currentUser;
  Session? get currentSession => client?.auth.currentSession;
  String? get currentUserId => currentUser?.id;

  /// Initializes Supabase using environment variables or optional parameters.
  /// Does not crash if unconfigured; gracefully falls back to local storage mode.
  Future<bool> init({String? url, String? anonKey, StorageService? storage}) async {
    // 1. Check dart defines (--dart-define)
    String effectiveUrl = url ??
        const String.fromEnvironment('VITE_SUPABASE_URL', defaultValue: '')
            .trim();
    if (effectiveUrl.isEmpty) {
      effectiveUrl =
          const String.fromEnvironment('SUPABASE_URL', defaultValue: '').trim();
    }

    String effectiveKey = anonKey ??
        const String.fromEnvironment('VITE_SUPABASE_PUBLISHABLE_KEY',
                defaultValue: '')
            .trim();
    if (effectiveKey.isEmpty) {
      effectiveKey = const String.fromEnvironment('SUPABASE_ANON_KEY',
              defaultValue: '')
          .trim();
    }

    // 2. Check local storage if passed
    if ((effectiveUrl.isEmpty || effectiveKey.isEmpty) && storage != null) {
      final savedUrl = storage.getCustomSupabaseUrl();
      final savedKey = storage.getCustomSupabaseKey();
      if (savedUrl != null && savedUrl.isNotEmpty) effectiveUrl = savedUrl;
      if (savedKey != null && savedKey.isNotEmpty) effectiveKey = savedKey;
    }

    if (effectiveUrl.isEmpty || effectiveKey.isEmpty) {
      debugPrint(
          '[SupabaseService] No Supabase credentials detected. Running in local fallback mode.');
      _isInitialized = false;
      return false;
    }

    try {
      await Supabase.initialize(
        url: effectiveUrl,
        anonKey: effectiveKey,
        debug: kDebugMode,
      );
      _configuredUrl = effectiveUrl;
      _configuredAnonKey = effectiveKey;
      _isInitialized = true;
      debugPrint('[SupabaseService] Initialized successfully with: $effectiveUrl');

      // Attempt syncing any pending offline sessions
      if (storage != null && currentUserId != null) {
        // Run in background without blocking startup
        syncOfflineQueue(storage).ignore();
      }

      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Initialization warning: $e');
      _isInitialized = false;
      return false;
    }
  }

  // ===========================================================================
  // AUTHENTICATION
  // ===========================================================================

  /// Sign up with email, password, and metadata
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    if (!isConfigured || client == null) return null;
    try {
      final response = await client!.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          'role': role,
        },
      );

      if (response.user != null) {
        // Upsert profile record
        await upsertProfile(
          userId: response.user!.id,
          name: name.trim(),
          email: email.trim(),
        );
      }
      return response;
    } catch (e) {
      debugPrint('[SupabaseService] Sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    if (!isConfigured || client == null) return null;
    try {
      final response = await client!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('[SupabaseService] Sign in error: $e');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    if (!isConfigured || client == null) return;
    try {
      await client!.auth.signOut();
    } catch (e) {
      debugPrint('[SupabaseService] Sign out error: $e');
    }
  }

  /// Send a password reset email via Supabase Auth.
  /// [redirectTo] should be the base URL of the deployed V-Hab app.
  Future<void> sendPasswordResetEmail({
    required String email,
    required String redirectTo,
  }) async {
    if (!isConfigured || client == null) {
      throw Exception('Supabase is not configured. Password reset requires a Supabase account.');
    }
    await client!.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  /// Update the authenticated user's password.
  /// Only valid when called during a PASSWORD_RECOVERY session.
  Future<void> updatePassword(String newPassword) async {
    if (!isConfigured || client == null) {
      throw Exception('Supabase is not configured.');
    }
    await client!.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Expose the auth state change stream for listening to PASSWORD_RECOVERY events.
  Stream<AuthState>? get authStateStream => client?.auth.onAuthStateChange;


  // ===========================================================================
  // PROFILES
  // ===========================================================================

  /// Fetch user profile
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    if (!isConfigured || client == null) return null;
    try {
      final data = await client!
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('[SupabaseService] getProfile error: $e');
      return null;
    }
  }

  /// Upsert profile record
  Future<bool> upsertProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    if (!isConfigured || client == null) return false;
    try {
      await client!.from('profiles').upsert({
        'id': userId,
        'name': name,
        'email': email,
      });
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] upsertProfile error: $e');
      return false;
    }
  }

  // ===========================================================================
  // EXERCISE SESSIONS
  // ===========================================================================

  /// Save an exercise session
  Future<bool> saveExerciseSession({
    required String userId,
    required String exerciseName,
    required String exerciseType,
    required int score,
    required double accuracy,
    required int durationSeconds,
    required bool completed,
  }) async {
    if (!isConfigured || client == null) return false;
    try {
      await client!.from('exercise_sessions').insert({
        'user_id': userId,
        'exercise_name': exerciseName,
        'exercise_type': exerciseType,
        'score': score,
        'accuracy': accuracy,
        'duration_seconds': durationSeconds,
        'completed': completed,
      });
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] saveExerciseSession error: $e');
      return false;
    }
  }

  /// Get recent sessions for a user
  Future<List<Map<String, dynamic>>> getRecentSessions(
    String userId, {
    int limit = 10,
  }) async {
    if (!isConfigured || client == null) return [];
    try {
      final List<dynamic> data = await client!
          .from('exercise_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[SupabaseService] getRecentSessions error: $e');
      return [];
    }
  }

  // ===========================================================================
  // EXERCISE PROGRESS
  // ===========================================================================

  /// Upserts aggregated exercise progress (best score, best accuracy, attempts)
  Future<bool> upsertExerciseProgress({
    required String userId,
    required String exerciseName,
    required int score,
    required double accuracy,
    required bool completed,
  }) async {
    if (!isConfigured || client == null) return false;
    try {
      // 1. Fetch existing progress row if any
      final existing = await client!
          .from('exercise_progress')
          .select()
          .eq('user_id', userId)
          .eq('exercise_name', exerciseName)
          .maybeSingle();

      int bestScore = score;
      double bestAccuracy = accuracy;
      int totalAttempts = 1;
      int completedAttempts = completed ? 1 : 0;

      if (existing != null) {
        final currentBestScore = (existing['best_score'] as num?)?.toInt() ?? 0;
        final currentBestAcc =
            (existing['best_accuracy'] as num?)?.toDouble() ?? 0.0;
        final currentTotal =
            (existing['total_attempts'] as num?)?.toInt() ?? 0;
        final currentCompleted =
            (existing['completed_attempts'] as num?)?.toInt() ?? 0;

        bestScore = score > currentBestScore ? score : currentBestScore;
        bestAccuracy =
            accuracy > currentBestAcc ? accuracy : currentBestAcc;
        totalAttempts = currentTotal + 1;
        completedAttempts = currentCompleted + (completed ? 1 : 0);
      }

      await client!.from('exercise_progress').upsert(
        {
          'user_id': userId,
          'exercise_name': exerciseName,
          'best_score': bestScore,
          'best_accuracy': bestAccuracy,
          'total_attempts': totalAttempts,
          'completed_attempts': completedAttempts,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,exercise_name',
      );
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] upsertExerciseProgress error: $e');
      return false;
    }
  }

  /// Get exercise progress list for a user
  Future<List<Map<String, dynamic>>> getExerciseProgress(String userId) async {
    if (!isConfigured || client == null) return [];
    try {
      final List<dynamic> data = await client!
          .from('exercise_progress')
          .select()
          .eq('user_id', userId);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[SupabaseService] getExerciseProgress error: $e');
      return [];
    }
  }

  // ===========================================================================
  // DASHBOARD STATISTICS
  // ===========================================================================

  /// Aggregated dashboard statistics computed directly from Supabase
  Future<Map<String, dynamic>?> getDashboardStats(String userId) async {
    if (!isConfigured || client == null) return null;
    try {
      final sessions = await getRecentSessions(userId, limit: 100);
      final progressList = await getExerciseProgress(userId);

      int totalCompleted = 0;
      int totalAttempts = sessions.length;
      double sumAccuracy = 0.0;
      int bestScore = 0;

      for (final s in sessions) {
        if (s['completed'] == true) totalCompleted++;
        final acc = (s['accuracy'] as num?)?.toDouble() ?? 0.0;
        sumAccuracy += acc;
        final sc = (s['score'] as num?)?.toInt() ?? 0;
        if (sc > bestScore) bestScore = sc;
      }

      final double avgAccuracy =
          sessions.isNotEmpty ? sumAccuracy / sessions.length : 0.0;

      return {
        'totalCompleted': totalCompleted,
        'totalAttempts': totalAttempts,
        'averageAccuracy': double.parse(avgAccuracy.toStringAsFixed(1)),
        'bestScore': bestScore,
        'recentSessions': sessions.take(10).toList(),
        'progressByExercise': progressList,
      };
    } catch (e) {
      debugPrint('[SupabaseService] getDashboardStats error: $e');
      return null;
    }
  }

  // ===========================================================================
  // OFFLINE RESILIENCE & QUEUE SYNC
  // ===========================================================================

  /// Uploads any exercise sessions that were saved locally while offline
  Future<void> syncOfflineQueue(StorageService storage) async {
    if (!isConfigured || client == null || currentUserId == null) return;
    final queue = storage.getOfflineSessionQueue();
    if (queue.isEmpty) return;

    debugPrint('[SupabaseService] Syncing ${queue.length} offline sessions...');
    final remainingQueue = <Map<String, dynamic>>[];

    for (final item in queue) {
      try {
        final success = await saveExerciseSession(
          userId: currentUserId!,
          exerciseName: item['exercise_name'] as String? ?? 'Exercise',
          exerciseType: item['exercise_type'] as String? ?? 'exercise',
          score: (item['score'] as num?)?.toInt() ?? 0,
          accuracy: (item['accuracy'] as num?)?.toDouble() ?? 0.0,
          durationSeconds: (item['duration_seconds'] as num?)?.toInt() ?? 0,
          completed: item['completed'] as bool? ?? false,
        );

        if (success) {
          await upsertExerciseProgress(
            userId: currentUserId!,
            exerciseName: item['exercise_name'] as String? ?? 'Exercise',
            score: (item['score'] as num?)?.toInt() ?? 0,
            accuracy: (item['accuracy'] as num?)?.toDouble() ?? 0.0,
            completed: item['completed'] as bool? ?? false,
          );
        } else {
          remainingQueue.add(item);
        }
      } catch (_) {
        remainingQueue.add(item);
      }
    }

    await storage.saveOfflineSessionQueue(remainingQueue);
    debugPrint(
        '[SupabaseService] Offline sync finished. Remaining pending: ${remainingQueue.length}');
  }
}
