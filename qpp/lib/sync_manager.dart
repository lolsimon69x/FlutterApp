import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'database.dart';
import 'local_repository.dart';
import 'sync_service.dart';

LocalRepository get localRepo => SyncManager.instance.repository;

class SyncManager {
  SyncManager._internal();
  static final SyncManager instance = SyncManager._internal();

  AppDatabase? _db;
  LocalRepository? _repository;
  SyncService? _syncService;

  String? _backendBaseUrl;
  String? _email;
  String? _password;
  String? _authToken;

  Timer? _authRefreshTimer;
  Timer? _heartbeatTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  LocalRepository get repository {
    if (_repository == null) {
      throw StateError(
        'SyncManager must be initialized before accessing localRepo. '
        'Call SyncManager.instance.initialize(...) first.',
      );
    }
    return _repository!;
  }

  String? get currentToken => _authToken;

  Future<bool> initialize({
    required String backendBaseUrl,
    required String email,
    required String password,
  }) async {
    // Strip any trailing slash if present to avoid redirect issues
    _backendBaseUrl = backendBaseUrl.endsWith('/')
        ? backendBaseUrl.substring(0, backendBaseUrl.length - 1)
        : backendBaseUrl;
    _email = email;
    _password = password;

    // Initialize database and repository singletons if not yet set
    _db ??= AppDatabase();
    _repository ??= LocalRepository(_db!);
    _syncService = SyncService(db: _db!, backendBaseUrl: _backendBaseUrl!);

    // Cancel existing background listeners if re-initializing
    await _connectivitySubscription?.cancel();
    _authRefreshTimer?.cancel();
    _heartbeatTimer?.cancel();

    // Authenticate against backend
    final loggedIn = await _login();
    if (loggedIn) {
      _startAuthRefreshLoop();
      _startHeartbeatLoop();
      _startConnectivityListener();
      // Trigger initial synchronization pass
      unawaited(triggerSync());
    }

    return loggedIn;
  }

  Future<bool> _login() async {
    if (_email == null || _password == null || _backendBaseUrl == null) {
      debugPrint('[AUTH] Missing credentials or base URL. Aborting login.');
      return false;
    }

    final url = Uri.parse('$_backendBaseUrl/myaccount');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final payload = {
      'email': _email,
      'password': _password,
    };
    final jsonBody = jsonEncode(payload);

    debugPrint('==================== [HTTP REQUEST: LOGIN] ====================');
    debugPrint('Method:  POST');
    debugPrint('URL:     $url');
    debugPrint('Headers: ${jsonEncode(headers)}');
    debugPrint('Body:    $jsonBody');
    debugPrint('===============================================================');

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonBody,
          )
          .timeout(const Duration(seconds: 25));

      debugPrint('==================== [HTTP RESPONSE: LOGIN] ===================');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Headers:     ${response.headers}');
      debugPrint('Body:        ${response.body}');
      debugPrint('===============================================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('access_token')) {
          _authToken = data['access_token'] as String?;
        } else if (data['data'] is Map<String, dynamic>) {
          final inner = data['data'] as Map<String, dynamic>;
          _authToken = inner['access_token'] as String?;
        }

        if (_authToken != null) {
          debugPrint('[AUTH SUCCESS] Extracted Token: $_authToken');
          return true;
        } else {
          debugPrint('[AUTH FAILURE] 200 OK received, but "access_token" key was not found in response JSON.');
          return false;
        }
      } else {
        debugPrint('[AUTH FAILURE] Server rejected request with status: ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      debugPrint('==================== [HTTP EXCEPTION: LOGIN] ==================');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      debugPrint('===============================================================');
      return false;
    }
  }

  void _startAuthRefreshLoop() {
    _authRefreshTimer?.cancel();
    // Refresh token every 10 minutes
    _authRefreshTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      debugPrint('[AUTH] Executing scheduled token refresh...');
      await _login();
    });
  }

  void _startHeartbeatLoop() {
    _heartbeatTimer?.cancel();
    // Verify true internet reachability every 1 minute
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final hasInternet = await _checkInternetAccess();
      if (hasInternet && _authToken != null) {
        await triggerSync();
      }
    });
  }

  void _startConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (hasInterface) {
        final hasInternet = await _checkInternetAccess();
        if (hasInternet && _authToken != null) {
          await triggerSync();
        }
      }
    });
  }

  Future<bool> _checkInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('1.1.1.1')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> triggerSync() async {
    if (_isSyncing || _authToken == null || _syncService == null) return;
    _isSyncing = true;

    try {
      debugPrint('[SYNC] Starting upstream/downstream cycle...');
      await _syncService!.syncReminders(_authToken!);
      await _syncService!.syncGameSessions(_authToken!);
      await _syncService!.fetchRemoteReminders(_authToken!);
      debugPrint('[SYNC] Cycle completed successfully.');
    } catch (e) {
      debugPrint('[SYNC ERROR] Cycle failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Triggers sync and returns the number of newly fetched remote reminders.
  Future<int> triggerSyncAndDetectNew() async {
    if (_authToken == null || _syncService == null) {
      // Attempt login fallback if token is missing
      final loggedIn = await _login();
      if (!loggedIn || _authToken == null || _syncService == null) return 0;
    }

    if (_isSyncing) return 0;
    _isSyncing = true;

    int newRemindersCount = 0;
    try {
      await _syncService!.syncReminders(_authToken!);
      await _syncService!.syncGameSessions(_authToken!);
      newRemindersCount = await _syncService!.fetchRemoteReminders(_authToken!);
    } catch (e) {
      debugPrint('[SYNC ERROR] triggerSyncAndDetectNew failed: $e');
    } finally {
      _isSyncing = false;
    }

    return newRemindersCount;
  }

  Future<void> dispose() async {
    _authRefreshTimer?.cancel();
    _heartbeatTimer?.cancel();
    await _connectivitySubscription?.cancel();
    await _db?.close();
    _db = null;
    _repository = null;
    _syncService = null;
  }
}