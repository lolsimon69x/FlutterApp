import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:qpp/screens/reminder.dart';
import 'package:qpp/screens/Listen_Music.dart';
import 'package:qpp/screens/call_doctor.dart';
import 'package:qpp/screens/chatbot.dart';
import 'package:qpp/screens/data/local/db_helper.dart';
import 'package:qpp/screens/LOGINPAGE.dart';
import 'package:qpp/screens/game_page.dart';
import '../sync_manager.dart'; // Ensure path points correctly to your SyncManager

class HomePage extends StatefulWidget {
  final String userEmail;
  final String userPassword;

  const HomePage({
    super.key,
    this.userEmail = '',
    this.userPassword = '',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _pollingTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _newRemindersCount = 0;
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _initializeAndStartSync();
  }

  Future<void> _initializeAndStartSync() async {
    // 1. Initialize SyncManager with credentials if required by your backend
    await SyncManager.instance.initialize(
      backendBaseUrl: 'https://dementia-care-yne7.onrender.com',
      email: widget.userEmail,
      password: widget.userPassword,
    );
    
    // 2. Start the polling timer
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    // Triggers sync every 4 seconds while the user is on the homepage
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final newItemsAdded = await SyncManager.instance.triggerSyncAndDetectNew(
        
      );

      if (newItemsAdded > 0 && mounted) {
        setState(() {
          _newRemindersCount += (newItemsAdded as num).toInt();
          _hasUnread = true;
        });
        _playNotificationSound();
      }
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/ding.mp3'));
    } catch (_) {
      // Fallback if asset file is missing or path is invalid
    }
  }

  Future<String> name() async {
    DBhelper dbh = DBhelper.getInstance();
    String username = await dbh.getname();
    return username;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final double buttonHeight = screenHeight * 0.13;
    final double buttonWidth = screenWidth * 0.85;
    final double avatarRadius = buttonHeight * 0.35;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: name(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                'Welcome...',
                style: TextStyle(
                  fontFamily: 'AtkinsonHyperlegible',
                  fontSize: 26.0,
                  fontWeight: FontWeight.bold,
                ),
              );
            }

            final username = snapshot.data ?? '';
            return Text(
              'Welcome $username',
              style: const TextStyle(
                fontFamily: 'AtkinsonHyperlegible',
                fontSize: 26.0,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Reminders with WhatsApp-style Badge & Audio Notification Alert
              SizedBox(
                height: buttonHeight,
                width: buttonWidth,
                child: Badge(
                  isLabelVisible: _hasUnread,
                  label: Text('$_newRemindersCount'),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasUnread = false;
                        _newRemindersCount = 0;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SyncHarnessScreen(
                            userEmail: widget.userEmail,
                            userPassword: widget.userPassword,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              "Reminders",
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundImage:
                              const AssetImage('assets/images/a.jpg'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15.0),

              // 2. Play Games
              SizedBox(
                height: buttonHeight,
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GamePageWidget(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage:
                            const AssetImage('assets/images/b.jpg'),
                      ),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: const Text(
                            "Play Games",
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15.0),

              // 3. Listen Music
              SizedBox(
                height: buttonHeight,
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocalAudioPlayer(
                          source:
                              LocalAudioSource.asset('audio/ki_naam_di_matim.mp3'),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            "Listen Music",
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage:
                            const AssetImage('assets/images/c.jpg'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15.0),

              // 4. Call CareTaker
              SizedBox(
                height: buttonHeight,
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CallDoctor(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage:
                            const AssetImage('assets/images/d.jpg'),
                      ),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: const Text(
                            "Call CareTaker",
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15.0),

              // 5. Talk to AI Sahayak
              SizedBox(
                width: buttonWidth,
                height: buttonHeight * 0.7,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AiAssistantPage(),
                      ),
                    );
                  },
                  label: const Text(
                    "Talk to AI Sahayak",
                    style: TextStyle(
                        fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.chat),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}