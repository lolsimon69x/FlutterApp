import 'dart:async';
import 'package:flutter/material.dart';

class WordSearchGamePage extends StatefulWidget {
  const WordSearchGamePage({super.key});

  @override
  State<WordSearchGamePage> createState() => _WordSearchGamePageState();
}

class _WordSearchGamePageState extends State<WordSearchGamePage> {
  // --- Game Data ---
  final int _gridCols = 8;
  
  // An 8x8 grid filled with letters containing hidden words
  final List<String> _gridLetters = [
    'F', 'A', 'Q', 'W', 'E', 'R', 'T', 'Y',
    'L', 'A', 'P', 'P', 'K', 'L', 'M', 'N',
    'U', 'B', 'C', 'O', 'D', 'E', 'G', 'H',
    'T', 'D', 'W', 'I', 'D', 'G', 'E', 'T',
    'T', 'E', 'M', 'O', 'B', 'I', 'L', 'E',
    'E', 'F', 'X', 'Y', 'Z', 'A', 'B', 'C',
    'R', 'G', 'D', 'A', 'R', 'T', 'K', 'L',
    'Z', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
  ];

  final List<String> _wordsToFind = [
    'FLUTTER', // Down (col 0)
    'APP',     // Across (row 1)
    'CODE',    // Across (row 2)
    'WIDGET',  // Across (row 3)
    'MOBILE',  // Across (row 4)
    'DART',    // Across (row 6)
  ];

  // --- Game State ---
  Set<String> _foundWords = {};
  List<int> _currentSelection = []; // Track indices the user has tapped
  Set<int> _permanentlyHighlighted = {}; // Indices of correctly found words

  // Stats
  int _totalSubmissions = 0;
  int _correctSubmissions = 0;
  
  // Timer
  late Stopwatch _stopwatch;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  // --- Logic ---

  bool _isAdjacent(int index1, int index2) {
    int r1 = index1 ~/ _gridCols;
    int c1 = index1 % _gridCols;
    int r2 = index2 ~/ _gridCols;
    int c2 = index2 % _gridCols;
    // Check if the new tap is touching the previous one (horizontally, vertically, or diagonally)
    return (r1 - r2).abs() <= 1 && (c1 - c2).abs() <= 1;
  }

  void _onCellTapped(int index) {
    if (_permanentlyHighlighted.contains(index)) return; // Already solved

    setState(() {
      if (_currentSelection.contains(index)) {
        // Allow un-selecting the very last letter tapped
        if (_currentSelection.last == index) {
          _currentSelection.removeLast();
        }
      } else {
        // Enforce that they tap letters in a continuous chain
        if (_currentSelection.isEmpty || _isAdjacent(_currentSelection.last, index)) {
          _currentSelection.add(index);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Select adjacent letters to form a word!'),
              duration: Duration(milliseconds: 1500),
            )
          );
        }
      }
    });
  }

  void _submitWord() {
    if (_currentSelection.isEmpty) return;

    setState(() {
      _totalSubmissions++;
      
      // Build the string from the selected indices
      String selectedWord = _currentSelection.map((i) => _gridLetters[i]).join();
      String reversedWord = selectedWord.split('').reversed.join('');

      bool isMatch = _wordsToFind.contains(selectedWord) || _wordsToFind.contains(reversedWord);
      bool isAlreadyFound = _foundWords.contains(selectedWord) || _foundWords.contains(reversedWord);

      if (isMatch && !isAlreadyFound) {
        _correctSubmissions++;
        _foundWords.add(selectedWord); // or reversedWord, both count as finding it
        _permanentlyHighlighted.addAll(_currentSelection);
        _currentSelection.clear();
        _checkWinCondition();
      } else {
        // Wrong attempt
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAlreadyFound ? 'Already found that word!' : 'Not a valid hidden word.'),
            backgroundColor: Colors.red.shade400,
            duration: const Duration(seconds: 1),
          )
        );
        _currentSelection.clear();
      }
    });
  }

  void _checkWinCondition() {
    if (_foundWords.length == _wordsToFind.length) {
      _stopwatch.stop();
      _timer.cancel();
      
      int accuracy = ((_correctSubmissions / _totalSubmissions) * 100).round();
      String timeStr = _formatTime(_stopwatch.elapsed.inSeconds);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('🎉 Puzzle Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: $timeStr', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Accuracy: $accuracy%', style: const TextStyle(fontSize: 18)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      );
    }
  }

  void _resetGame() {
    setState(() {
      _foundWords.clear();
      _currentSelection.clear();
      _permanentlyHighlighted.clear();
      _totalSubmissions = 0;
      _correctSubmissions = 0;
      _stopwatch.reset();
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() {});
      });
    });
  }

  String _formatTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    int accuracy = _totalSubmissions == 0 
        ? 100 
        : ((_correctSubmissions / _totalSubmissions) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Search'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Stats Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(_stopwatch.elapsed.inSeconds),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.track_changes, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Accuracy: $accuracy%',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Word Bank
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _wordsToFind.map((word) {
                  bool isFound = _foundWords.contains(word);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFound ? Colors.green.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      word,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFound ? Colors.green.shade700 : Colors.black87,
                        decoration: isFound ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 3. The Grid (Responsive and scaled)
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1, // Keeps the grid perfectly square
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(), // Prevents scrolling issues
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridCols,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: _gridLetters.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _currentSelection.contains(index);
                        bool isFound = _permanentlyHighlighted.contains(index);

                        Color bgColor = Colors.white;
                        Color textColor = Colors.black87;

                        if (isFound) {
                          bgColor = Colors.green.shade300;
                          textColor = Colors.white;
                        } else if (isSelected) {
                          bgColor = Colors.blue.shade300;
                          textColor = Colors.white;
                        }

                        return GestureDetector(
                          onTap: () => _onCellTapped(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected || isFound ? Colors.transparent : Colors.grey.shade300,
                              ),
                              boxShadow: isSelected || isFound
                                  ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                _gridLetters[index],
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // 4. Controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentSelection.isEmpty 
                          ? null 
                          : () => setState(() => _currentSelection.clear()),
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _currentSelection.isEmpty ? null : _submitWord,
                      icon: const Icon(Icons.check),
                      label: const Text('Submit Word'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}