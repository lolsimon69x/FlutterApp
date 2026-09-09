import 'package:flutter/material.dart';
import 'package:qpp/sync_manager.dart';
import 'package:qpp/local_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SyncHarnessApp());
}

class SyncHarnessApp extends StatelessWidget {
  const SyncHarnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Database Sync Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          surface: const Color(0xFFF8FAFC),
        ),
      ),
      // Example default parameters; pass user credentials dynamically when navigating from LoginPage/MyHomePage
      home: const SyncHarnessScreen(
        userEmail: 'deepak.singh@outlook.com',
        userPassword: 'qwerty123',
        baseUrl: 'https://dementia-care-yne7.onrender.com',
      ),
    );
  }
}

class SyncHarnessScreen extends StatefulWidget {
  final String userEmail;
  final String userPassword;
  final String baseUrl;

  const SyncHarnessScreen({
    super.key,
    required this.userEmail,
    required this.userPassword,
    this.baseUrl = 'https://dementia-care-yne7.onrender.com',
  });

  @override
  State<SyncHarnessScreen> createState() => _SyncHarnessScreenState();
}

class _SyncHarnessScreenState extends State<SyncHarnessScreen> {
  List<dynamic> _remindersList = [];
  String _statusLog = 'Initializing...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoInitializeAndFetch();
  }

  void _log(String msg) {
    if (!mounted) return;
    setState(() {
      _statusLog = '[${DateTime.now().toIso8601String().substring(11, 19)}] $msg';
    });
  }

  /// Automatically initializes SyncManager, logs in, and loads reminders on screen start
  Future<void> _autoInitializeAndFetch() async {
    setState(() => _isLoading = true);
    _log('Authenticating in background...');

    try {
      final success = await SyncManager.instance.initialize(
        backendBaseUrl: widget.baseUrl,
        email: widget.userEmail,
        password: widget.userPassword,
      );

      if (success) {
        _log('Authenticated successfully!');
        await _loadAllReminders();
      } else {
        _log('Authentication failed. Check credentials.');
      }
    } catch (e) {
      _log('Connection error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAllReminders() async {
    final results = await localRepo.getReminder();
    if (!mounted) return;
    setState(() {
      _remindersList = results;
    });
    _log('Loaded ${results.length} record(s) from SQLite.');
  }

  Future<void> _forceSync() async {
    setState(() => _isLoading = true);
    _log('Triggering background sync...');
    try {
      await SyncManager.instance.triggerSync();
      await _loadAllReminders();
      _log('Sync completed. Table refreshed.');
    } catch (e) {
      _log('Sync error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Sync Database Console',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Refresh Records',
            onPressed: _loadAllReminders,
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Force Sync Now',
            onPressed: _isLoading ? null : _forceSync,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Log Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _isLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.terminal_rounded,
                    color: const Color(0xFF38BDF8),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusLog,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Header: Local SQLite Data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Local SQLite Storage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_remindersList.length} items',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Dynamic List View
            if (_remindersList.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.inbox_rounded,
                        size: 36, color: Color(0xFF94A3B8)),
                    SizedBox(height: 8),
                    Text(
                      'No reminders found in local SQLite storage',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _remindersList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _remindersList[index];

                  final int? localId = item is Map ? item['id'] : item.id;
                  final int? globalId =
                      item is Map ? item['globalId'] : item.globalId;
                  final bool isSynced = item is Map
                      ? (item['isSynced'] ?? false)
                      : item.isSynced;
                  final String message =
                      (item is Map ? item['message'] : item.message) ??
                          'No Title';
                  final String time =
                      (item is Map ? item['time'] : item.time) ?? '--:--';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF334155),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Local ID: #$localId • Time: $time • Server ID: ${globalId ?? "Pending"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSynced
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSynced ? 'SYNCED' : 'PENDING',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSynced
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}