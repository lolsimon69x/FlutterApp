import 'package:flutter/material.dart';
import 'sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SyncHarnessScreen(),
  ));
}

class SyncHarnessScreen extends StatefulWidget {
  const SyncHarnessScreen({super.key});

  @override
  State<SyncHarnessScreen> createState() => _SyncHarnessScreenState();
}

class _SyncHarnessScreenState extends State<SyncHarnessScreen> {
  // Config & Auth Controllers
  final _urlController = TextEditingController(text: 'https://dementia-care-yne7.onrender.com');
  final _emailController = TextEditingController(text: 'deepak.singh@outlook.com');
  final _passwordController = TextEditingController(text: 'qwerty123');

  // Input Controllers
  final _reminderMsgController = TextEditingController(text: 'Take Inhaler');
  final _reminderTimeController = TextEditingController(text: '08:30');
  final _gameTypeController = TextEditingController(text: 'reaction_test');
  final _gameDataController = TextEditingController(text: '{"score": 95}');
  final _lookupIdController = TextEditingController();

  List<dynamic> _remindersList = [];
  String _statusLog = 'Ready. SyncManager not initialized.';

  void _log(String msg) {
    setState(() {
      _statusLog = '[${DateTime.now().toIso8601String().substring(11, 19)}] $msg';
    });
  }

  // --- ACTIONS ---

  Future<void> _handleLogin() async {
    _log('Initializing and logging in...');
    final success = await SyncManager.instance.initialize(
      backendBaseUrl: _urlController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (success) {
      _log('Logged in! Token: ${SyncManager.instance.currentToken?.substring(0, 15)}...');
    } else {
      _log('Login failed. Check server URL or credentials.');
    }
  }

  Future<void> _addReminder() async {
    final msg = _reminderMsgController.text.trim();
    final time = _reminderTimeController.text.trim();
    if (msg.isEmpty || time.isEmpty) return;

    final id = await localRepo.createReminder(message: msg, time: time);
    _log('Reminder saved offline with Local ID: $id');
    await _loadAllReminders();
  }

  Future<void> _addGameSession() async {
    final type = _gameTypeController.text.trim();
    final data = _gameDataController.text.trim();
    if (type.isEmpty || data.isEmpty) return;

    final id = await localRepo.createGameSession(gameType: type, gameData: data);
    _log('Game session saved offline with Local ID: $id');
  }

  Future<void> _loadAllReminders() async {
    final results = await localRepo.getReminder();
    setState(() {
      _remindersList = results;
    });
    _log('Loaded ${results.length} reminder(s) from SQLite.');
  }

  Future<void> _lookupReminderById() async {
    final idText = _lookupIdController.text.trim();
    if (idText.isEmpty) return;

    final id = int.tryParse(idText);
    if (id == null) {
      _log('Invalid ID format');
      return;
    }

    final results = await localRepo.getReminder(id);
    if (results.isEmpty) {
      _log('No reminder found with Local ID: $id');
    } else {
      final r = results.first;
      _log('Found ID $id: "${r.message}" | time: ${r.time} | globalId: ${r.globalId} | isSynced: ${r.isSynced}');
    }
  }

  Future<void> _forceSync() async {
    _log('Triggering background sync manually...');
    await SyncManager.instance.triggerSync();
    await _loadAllReminders();
    _log('Sync completed. Table reloaded.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync Test Harness'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Force Sync',
            onPressed: _forceSync,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh List',
            onPressed: _loadAllReminders,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Log Banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                border: Border.all(color: Colors.blueGrey.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusLog,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Authentication Section
            _buildSection(
              title: '1. Backend & Login',
              children: [
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Base URL (10.0.2.2 for Android Emulator, 127.0.0.1 for Desktop)',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password', isDense: true),
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _handleLogin,
                  child: const Text('Initialize & Login (POST /myaccount)'),
                ),
              ],
            ),

            // Reminder Creation
            _buildSection(
              title: '2. Add Reminder (Offline)',
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _reminderMsgController,
                        decoration: const InputDecoration(labelText: 'Message', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _reminderTimeController,
                        decoration: const InputDecoration(labelText: 'Time', isDense: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addReminder,
                  child: const Text('Insert Reminder to SQLite'),
                ),
              ],
            ),

            // Game Session Creation
            _buildSection(
              title: '3. Add Game Session (Offline)',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gameTypeController,
                        decoration: const InputDecoration(labelText: 'Game Type', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _gameDataController,
                        decoration: const InputDecoration(labelText: 'Game Data JSON', isDense: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addGameSession,
                  child: const Text('Insert Game Session to SQLite'),
                ),
              ],
            ),

            // Query Specific ID
            _buildSection(
              title: '4. Lookup Reminder by Local ID',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lookupIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Local ID (integer)', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _lookupReminderById,
                      child: const Text('Fetch Single'),
                    ),
                  ],
                ),
              ],
            ),

            // Live Database Table View
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Local SQLite "Reminders" Table',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                TextButton(
                  onPressed: _loadAllReminders,
                  child: const Text('Refresh Table'),
                ),
              ],
            ),
            if (_remindersList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No reminders found in local SQLite.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _remindersList.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _remindersList[index];
                  final bool isSynced = item.isSynced;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(item.message, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Local ID: ${item.id} | Server globalId: ${item.globalId ?? "NULL"} | Time: ${item.time}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Chip(
                      label: Text(
                        isSynced ? 'SYNCED' : 'PENDING PUSH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSynced ? Colors.green.shade900 : Colors.deepOrange.shade900,
                        ),
                      ),
                      backgroundColor: isSynced ? Colors.green.shade100 : Colors.deepOrange.shade100,
                      padding: EdgeInsets.zero,
                    ),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}