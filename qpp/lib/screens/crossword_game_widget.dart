import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// NOTE: This file requires the `google_fonts` package so that Assamese
// (Bengali-Assamese script) and Manipuri (Meetei Mayek script) render
// correctly on every device, even ones without those fonts installed.
// Add this to your pubspec.yaml:
//
//   dependencies:
//     google_fonts: ^6.2.1

enum PuzzleLanguage { assamese, manipuri }

/// Holds everything that differs between languages: the grid, the target
/// words, their English glosses (shown so players know what they're
/// hunting for), and the font used to render the script correctly.
class _LanguagePack {
  final String languageLabel; // name of the language, in its own script
  final String languageLabelEnglish;
  final int gridCols;
  final List<String> gridLetters; // each entry is one grapheme "cell"
  final List<String> wordsToFind;
  final Map<String, String> glosses; // word -> English meaning
  final TextStyle Function({double? fontSize, FontWeight? fontWeight, Color? color}) fontBuilder;

  const _LanguagePack({
    required this.languageLabel,
    required this.languageLabelEnglish,
    required this.gridCols,
    required this.gridLetters,
    required this.wordsToFind,
    required this.glosses,
    required this.fontBuilder,
  });
}

TextStyle _assameseFont({double? fontSize, FontWeight? fontWeight, Color? color}) {
  return GoogleFonts.notoSansBengali(fontSize: fontSize, fontWeight: fontWeight, color: color);
}

TextStyle _manipuriFont({double? fontSize, FontWeight? fontWeight, Color? color}) {
  return GoogleFonts.notoSansMeeteiMayek(fontSize: fontSize, fontWeight: fontWeight, color: color);
}

// --- Assamese pack -----------------------------------------------------
// Words are laid out one per row, left to right, exactly like the
// original puzzle. Each grid "letter" is a full grapheme cluster
// (consonant + vowel sign together) since that's the unit a reader
// actually perceives as one character in this script.
final _LanguagePack _assamesePack = _LanguagePack(
  languageLabel: 'অসমীয়া',
  languageLabelEnglish: 'Assamese',
  gridCols: 8,
  fontBuilder: _assameseFont,
  wordsToFind: const ['অসম', 'পানী', 'বাঘ', 'জোনাক', 'অসমীয়া', 'গাখীৰ'],
  glosses: const {
    'অসম': 'Assam',
    'পানী': 'Water',
    'বাঘ': 'Tiger',
    'জোনাক': 'Firefly',
    'অসমীয়া': 'Assamese',
    'গাখীৰ': 'Milk',
  },
  gridLetters: const [
    // Row 0: অসম (Assam)
    'অ', 'স', 'ম', 'ক', 'খ', 'গ', 'ঘ', 'চ',
    // Row 1: পানী (water)
    'পা', 'নী', 'ছ', 'জ', 'ঝ', 'ট', 'ঠ', 'ড',
    // Row 2: বাঘ (tiger)
    'বা', 'ঘ', 'ঢ', 'ণ', 'ত', 'থ', 'দ', 'ধ',
    // Row 3: জোনাক (firefly)
    'জো', 'না', 'ক', 'ন', 'প', 'ফ', 'ব', 'ভ',
    // Row 4: অসমীয়া (Assamese)
    'অ', 'স', 'মী', 'য়া', 'ম', 'য', 'ৰ', 'ল',
    // Row 5: গাখীৰ (milk)
    'গা', 'খী', 'ৰ', 'ৱ', 'শ', 'ষ', 'স', 'হ',
    // Row 6: filler
    'ক', 'খ', 'গ', 'ঘ', 'চ', 'ছ', 'জ', 'ঝ',
    // Row 7: filler
    'ট', 'ঠ', 'ড', 'ঢ', 'ণ', 'ত', 'থ', 'দ',
  ],
);

// --- Manipuri (Meetei Mayek) pack ---------------------------------------
final _LanguagePack _manipuriPack = _LanguagePack(
  languageLabel: 'ꯃꯩꯇꯩꯂꯣꯟ',
  languageLabelEnglish: 'Manipuri (Meetei Mayek)',
  gridCols: 8,
  fontBuilder: _manipuriFont,
  wordsToFind: const ['ꯃꯩꯇꯩ', 'ꯃꯅꯤꯄꯨꯔ', 'ꯅꯨꯃꯤꯠ', 'ꯀꯪꯂꯥꯁꯥ', 'ꯆꯤꯡ', 'ꯍꯣꯢ'],
  glosses: const {
    'ꯃꯩꯇꯩ': 'Meitei',
    'ꯃꯅꯤꯄꯨꯔ': 'Manipur',
    'ꯅꯨꯃꯤꯠ': 'Sun',
    'ꯀꯪꯂꯥꯁꯥ': 'Kanglasha',
    'ꯆꯤꯡ': 'Hill',
    'ꯍꯣꯢ': 'Yes',
  },
  gridLetters: const [
    // Row 0: ꯃꯩꯇꯩ (Meitei)
    'ꯃꯩ', 'ꯇꯩ', 'ꯀ', 'ꯈ', 'ꯒ', 'ꯆ', 'ꯖ', 'ꯇ',
    // Row 1: ꯃꯅꯤꯄꯨꯔ (Manipur)
    'ꯃ', 'ꯅꯤ', 'ꯄꯨ', 'ꯔ', 'ꯊ', 'ꯗ', 'ꯅ', 'ꯄ',
    // Row 2: ꯅꯨꯃꯤꯠ (Sun)
    'ꯅꯨ', 'ꯃꯤ', 'ꯠ', 'ꯕ', 'ꯃ', 'ꯌ', 'ꯔ', 'ꯂ',
    // Row 3: ꯀꯪꯂꯥꯁꯥ (Kanglasha)
    'ꯀꯪ', 'ꯂꯥ', 'ꯁꯥ', 'ꯋ', 'ꯁ', 'ꯍ', 'ꯑ', 'ꯏ',
    // Row 4: ꯆꯤꯡ (Hill)
    'ꯆꯤ', 'ꯪ', 'ꯎ', 'ꯀ', 'ꯈ', 'ꯒ', 'ꯆ', 'ꯖ',
    // Row 5: ꯍꯣꯢ (Yes)
    'ꯍꯣ', 'ꯢ', 'ꯇ', 'ꯊ', 'ꯗ', 'ꯅ', 'ꯄ', 'ꯕ',
    // Row 6: filler
    'ꯃ', 'ꯌ', 'ꯔ', 'ꯂ', 'ꯋ', 'ꯁ', 'ꯍ', 'ꯑ',
    // Row 7: filler
    'ꯏ', 'ꯎ', 'ꯀ', 'ꯈ', 'ꯒ', 'ꯆ', 'ꯖ', 'ꯇ',
  ],
);

class WordSearchGamePage extends StatefulWidget {
  const WordSearchGamePage({super.key});

  @override
  State<WordSearchGamePage> createState() => _WordSearchGamePageState();
}

class _WordSearchGamePageState extends State<WordSearchGamePage> {
  // --- Language / Game Data ---
  PuzzleLanguage _language = PuzzleLanguage.assamese;

  _LanguagePack get _pack =>
      _language == PuzzleLanguage.assamese ? _assamesePack : _manipuriPack;

  int get _gridCols => _pack.gridCols;
  List<String> get _gridLetters => _pack.gridLetters;
  List<String> get _wordsToFind => _pack.wordsToFind;

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
            ),
          );
        }
      }
    });
  }

  void _submitWord() {
    if (_currentSelection.isEmpty) return;

    setState(() {
      _totalSubmissions++;

      // Build the string from the selected cells (each cell may be a
      // multi-codepoint grapheme cluster, e.g. a consonant + vowel sign).
      String selectedWord = _currentSelection.map((i) => _gridLetters[i]).join();
      // Reverse by cell, not by UTF-16 code unit, so multi-codepoint
      // clusters (used by Assamese and Manipuri script) don't get corrupted.
      String reversedWord =
          _currentSelection.reversed.map((i) => _gridLetters[i]).join();

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
          ),
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
      _timer.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() {});
      });
    });
  }

  void _switchLanguage(PuzzleLanguage newLanguage) {
    if (newLanguage == _language) return;
    setState(() {
      _language = newLanguage;
    });
    _resetGame();
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

    final pack = _pack;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Search'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 0. Language switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedButton<PuzzleLanguage>(
                segments: [
                  ButtonSegment(
                    value: PuzzleLanguage.assamese,
                    label: Text(
                      _assamesePack.languageLabel,
                      style: _assameseFont(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ButtonSegment(
                    value: PuzzleLanguage.manipuri,
                    label: Text(
                      _manipuriPack.languageLabel,
                      style: _manipuriFont(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                selected: {_language},
                onSelectionChanged: (selection) => _switchLanguage(selection.first),
              ),
            ),

            // 1. Stats Bar
            Container(
              margin: const EdgeInsets.only(top: 12),
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

            // 2. Word Bank (script word + English gloss)
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          word,
                          style: pack.fontBuilder(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isFound ? Colors.green.shade700 : Colors.black87,
                          ).copyWith(
                            decoration: isFound ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        Text(
                          pack.glosses[word] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: isFound ? Colors.green.shade700 : Colors.black54,
                          ),
                        ),
                      ],
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
                                  ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))]
                                  : [],
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Text(
                                    _gridLetters[index],
                                    style: pack.fontBuilder(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
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