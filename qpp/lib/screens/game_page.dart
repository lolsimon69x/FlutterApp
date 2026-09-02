import 'package:flutter/material.dart';
import 'package:qpp/screens/crossword_game_widget.dart';
import 'package:qpp/screens/playgames.dart';

// ==========================================
// 1. How to integrate with any button
// ==========================================
// Copy this button anywhere in your app to open the Game Page:
/*
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GamePageWidget()),
    );
  },
  child: const Text('Open Game Hub'),
)
*/

// ==========================================
// 2. The Main Game Page Widget
// ==========================================
class GamePageWidget extends StatelessWidget {
  const GamePageWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GyanGayming'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose Your Game!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // Button for Game 1
            ElevatedButton.icon(
              icon: const Icon(Icons.videogame_asset),
              label: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Text('Crossword Game', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CrosswordGamePage()),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Button for Game 2
            ElevatedButton.icon(
              icon: const Icon(Icons.casino),
              label: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Text('Memory Game', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GameScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
