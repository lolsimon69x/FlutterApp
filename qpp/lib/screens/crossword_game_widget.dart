import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showCrosswordGame(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const CrosswordGamePage()),
  );
}

// ---------------------------------------------------------------------------
// Puzzle Data
// ---------------------------------------------------------------------------

enum Direction { across, down }

class CrosswordEntry {
  final String answer;
  final String clue;
  final int row;
  final int col;
  final Direction direction;

  const CrosswordEntry({
    required this.answer,
    required this.clue,
    required this.row,
    required this.col,
    required this.direction,
  });
}

const int _gridRows = 5;
const int _gridCols = 7;

final List<CrosswordEntry> _puzzleEntries = [
  const CrosswordEntry(
    answer: 'FLUTTER',
    clue: 'Google\'s cross-platform UI toolkit',
    row: 0,
    col: 0,
    direction: Direction.across,
  ),
  const CrosswordEntry(
    answer: 'FLOW',
    clue: 'A steady, continuous stream',
    row: 0,
    col: 0,
    direction: Direction.down,
  ),
  const CrosswordEntry(
    answer: 'TEST',
    clue: 'A trial run to check something works',
    row: 0,
    col: 3,
    direction: Direction.down,
  ),
  const CrosswordEntry(
    answer: 'ERROR',
    clue: 'A mistake, often shown in red',
    row: 0,
    col: 5,
    direction: Direction.down,
  ),
];

// ---------------------------------------------------------------------------
// Internal Grid Model
// ---------------------------------------------------------------------------

class _Cell {
  String? correctLetter;
  int? number;
  String userInput = '';
  bool isRevealedByHint = false;

  _Cell({this.correctLetter});

  bool get isBlocked => correctLetter == null;
}

class _NumberedEntry {
  final CrosswordEntry entry;
  final int number;
  int hintsUsed = 0;

  _NumberedEntry(this.entry, this.number);

  String get label =>
      '$number. ${entry.direction == Direction.across ? "Across" : "Down"}';
}

// ---------------------------------------------------------------------------
// Main Page
// ---------------------------------------------------------------------------

class CrosswordGamePage extends StatefulWidget {
  const CrosswordGamePage({super.key});

  @override
  State<CrosswordGamePage> createState() => _CrosswordGamePageState();
}

class _CrosswordGamePageState extends State<CrosswordGamePage> {
  static const int _totalHintsAllowed = 6;

  late List<List<_Cell>> _grid;
  late List<_NumberedEntry> _numberedEntries;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  int _hintsRemaining = _totalHintsAllowed;
  bool _solvedPuzzle = false;
  
  // Tracking
  Timer? _timer;
  int _secondsElapsed = 0;
  int _mistakesMade = 0;
  int _totalLetters = 0;

  @override
  void initState() {
    super.initState();
    _buildGrid();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers.values) c.dispose();
    for (final f in _focusNodes.values) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
  }

  String get _formattedTime {
    final m = _secondsElapsed ~/ 60;
    final s = _secondsElapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _accuracyPercentage {
    if (_totalLetters == 0) return 100;
    final totalAttempts = _totalLetters + _mistakesMade;
    return ((_totalLetters / totalAttempts) * 100).round();
  }

  String _key(int r, int c) => '$r-$c';

  void _buildGrid() {
    _grid = List.generate(
      _gridRows,
      (_) => List.generate(_gridCols, (_) => _Cell()),
    );
    _totalLetters = 0;

    for (final entry in _puzzleEntries) {
      for (int i = 0; i < entry.answer.length; i++) {
        final r = entry.direction == Direction.down ? entry.row + i : entry.row;
        final c = entry.direction == Direction.across ? entry.col + i : entry.col;
        final letter = entry.answer[i];
        final cell = _grid[r][c];
        
        if (cell.correctLetter == null) {
          cell.correctLetter = letter;
          _totalLetters++;
        }
      }
    }

    for (int r = 0; r < _gridRows; r++) {
      for (int c = 0; c < _gridCols; c++) {
        if (!_grid[r][c].isBlocked) {
          _controllers[_key(r, c)] = TextEditingController();
          _focusNodes[_key(r, c)] = FocusNode();
        }
      }
    }

    bool blocked(int r, int c) {
      if (r < 0 || r >= _gridRows || c < 0 || c >= _gridCols) return true;
      return _grid[r][c].isBlocked;
    }

    int nextNumber = 1;
    final Map<String, int> numberAt = {};
    for (int r = 0; r < _gridRows; r++) {
      for (int c = 0; c < _gridCols; c++) {
        if (_grid[r][c].isBlocked) continue;
        final startsAcross = blocked(r, c - 1) && !blocked(r, c + 1);
        final startsDown = blocked(r - 1, c) && !blocked(r + 1, c);
        if (startsAcross || startsDown) {
          _grid[r][c].number = nextNumber;
          numberAt[_key(r, c)] = nextNumber;
          nextNumber++;
        }
      }
    }

    _numberedEntries = _puzzleEntries
        .map((e) => _NumberedEntry(e, numberAt[_key(e.row, e.col)]!))
        .toList()
      ..sort((a, b) {
        final byNumber = a.number.compareTo(b.number);
        if (byNumber != 0) return byNumber;
        return a.entry.direction.index.compareTo(b.entry.direction.index);
      });
  }

  void _onLetterChanged(int r, int c, String value) {
    final upper = value.toUpperCase();
    final cell = _grid[r][c];

    // Track mistakes if they typed a wrong letter
    if (upper.isNotEmpty && upper != cell.correctLetter && cell.userInput != upper) {
      _mistakesMade++;
    }

    cell.userInput = upper;
    setState(() {});
    
    if (upper.isNotEmpty) {
      _advanceFocus(r, c);
    }
    _checkForWin();
  }

  void _advanceFocus(int r, int c) {
    if (c + 1 < _gridCols && !_grid[r][c + 1].isBlocked) {
      _focusNodes[_key(r, c + 1)]?.requestFocus();
    } else if (r + 1 < _gridRows && !_grid[r + 1][c].isBlocked) {
      _focusNodes[_key(r + 1, c)]?.requestFocus();
    } else {
      _focusNodes[_key(r, c)]?.unfocus();
    }
  }

  bool _isCellCorrect(int r, int c) {
    final cell = _grid[r][c];
    if (cell.isBlocked) return true;
    return cell.userInput.isNotEmpty && cell.userInput == cell.correctLetter;
  }

  bool _isCellWrong(int r, int c) {
    final cell = _grid[r][c];
    if (cell.isBlocked) return true;
    return cell.userInput.isNotEmpty && cell.userInput != cell.correctLetter;
  }

  void _checkForWin() {
    for (int r = 0; r < _gridRows; r++) {
      for (int c = 0; c < _gridCols; c++) {
        if (!_isCellCorrect(r, c)) return;
      }
    }
    if (!_solvedPuzzle) {
      _solvedPuzzle = true;
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWinDialog());
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Solved it!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: $_formattedTime'),
            const SizedBox(height: 8),
            Text('Accuracy: $_accuracyPercentage%'),
            const SizedBox(height: 8),
            Text('Mistakes: $_mistakesMade'),
            const SizedBox(height: 8),
            Text('Hints Used: ${_totalHintsAllowed - _hintsRemaining}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: const Text('Play again'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _hintsRemaining = _totalHintsAllowed;
      _solvedPuzzle = false;
      _mistakesMade = 0;
      for (final row in _grid) {
        for (final cell in row) {
          cell.userInput = '';
          cell.isRevealedByHint = false;
        }
      }
      for (final c in _controllers.values) c.clear();
      for (final ne in _numberedEntries) ne.hintsUsed = 0;
    });
    _startTimer();
  }

  void _useHint(_NumberedEntry numberedEntry) {
    if (_hintsRemaining <= 0) return;

    final entry = numberedEntry.entry;
    for (int i = 0; i < entry.answer.length; i++) {
      final r = entry.direction == Direction.down ? entry.row + i : entry.row;
      final c = entry.direction == Direction.across ? entry.col + i : entry.col;
      final cell = _grid[r][c];
      
      if (cell.userInput != cell.correctLetter) {
        setState(() {
          cell.userInput = cell.correctLetter!;
          cell.isRevealedByHint = true;
          _controllers[_key(r, c)]?.text = cell.correctLetter!;
          _hintsRemaining--;
          numberedEntry.hintsUsed++;
        });
        _checkForWin();
        return;
      }
    }
  }

  bool _isEntrySolved(_NumberedEntry ne) {
    final entry = ne.entry;
    for (int i = 0; i < entry.answer.length; i++) {
      final r = entry.direction == Direction.down ? entry.row + i : entry.row;
      final c = entry.direction == Direction.across ? entry.col + i : entry.col;
      if (_grid[r][c].userInput != _grid[r][c].correctLetter) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final wideLayout = MediaQuery.of(context).size.width >= 760;

    final sidebar = _HintSidebar(
      entries: _numberedEntries,
      hintsRemaining: _hintsRemaining,
      totalHints: _totalHintsAllowed,
      isEntrySolved: _isEntrySolved,
      onHintRequested: _useHint,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossword'),
        actions: [
          IconButton(
            tooltip: 'Restart',
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
          if (!wideLayout)
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Hints',
                icon: const Icon(Icons.lightbulb_outline),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
        ],
      ),
      endDrawer: wideLayout ? null : Drawer(child: SafeArea(child: sidebar)),
      body: SafeArea(
        child: Column(
          children: [
            // Stats Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(_formattedTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.analytics_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text('Accuracy: $_accuracyPercentage%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: wideLayout
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Center(child: _buildScrollableGrid())),
                        SizedBox(
                          width: 300,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: sidebar,
                          ),
                        ),
                      ],
                    )
                  : Center(child: _buildScrollableGrid()),
            ),
          ],
        ),
      ),
    );
  }

  // Nested scroll views fix the right-side overflow issue
  Widget _buildScrollableGrid() {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: _buildGridWidget(),
      ),
    );
  }

  Widget _buildGridWidget() {
    const cellSize = 46.0;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_gridRows, (r) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_gridCols, (c) {
              final cell = _grid[r][c];
              if (cell.isBlocked) {
                return const SizedBox(width: cellSize, height: cellSize);
              }
              
              final correct = _isCellCorrect(r, c);
              final wrong = _isCellWrong(r, c);

              Color fillColor = Colors.white;
              if (cell.isRevealedByHint) fillColor = Colors.amber.shade100;
              else if (correct) fillColor = Colors.green.shade100;
              else if (wrong) fillColor = Colors.red.shade50;

              return Container(
                width: cellSize,
                height: cellSize,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: fillColor,
                  border: Border.all(color: Colors.black87, width: 1),
                ),
                child: Stack(
                  children: [
                    if (cell.number != null)
                      Positioned(
                        left: 2,
                        top: 1,
                        child: Text(
                          '${cell.number}',
                          style: const TextStyle(fontSize: 9, color: Colors.black54),
                        ),
                      ),
                    Center(
                      child: SizedBox(
                        width: cellSize - 6,
                        height: cellSize - 6,
                        child: TextField(
                          controller: _controllers[_key(r, c)],
                          focusNode: _focusNodes[_key(r, c)],
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) => _onLetterChanged(r, c, v),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hint Sidebar
// ---------------------------------------------------------------------------

class _HintSidebar extends StatelessWidget {
  final List<_NumberedEntry> entries;
  final int hintsRemaining;
  final int totalHints;
  final bool Function(_NumberedEntry) isEntrySolved;
  final void Function(_NumberedEntry) onHintRequested;

  const _HintSidebar({
    required this.entries,
    required this.hintsRemaining,
    required this.totalHints,
    required this.isEntrySolved,
    required this.onHintRequested,
  });

  @override
  Widget build(BuildContext context) {
    final across = entries.where((e) => e.entry.direction == Direction.across);
    final down = entries.where((e) => e.entry.direction == Direction.down);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Hints: $hintsRemaining / $totalHints',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: totalHints == 0 ? 0 : hintsRemaining / totalHints,
          minHeight: 6,
          backgroundColor: Colors.grey.shade300,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              if (across.isNotEmpty) const _SectionHeader('Across'),
              ...across.map((e) => _ClueTile(
                    entry: e,
                    solved: isEntrySolved(e),
                    disabled: hintsRemaining <= 0,
                    onHint: () => onHintRequested(e),
                  )),
              const SizedBox(height: 12),
              if (down.isNotEmpty) const _SectionHeader('Down'),
              ...down.map((e) => _ClueTile(
                    entry: e,
                    solved: isEntrySolved(e),
                    disabled: hintsRemaining <= 0,
                    onHint: () => onHintRequested(e),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ClueTile extends StatelessWidget {
  final _NumberedEntry entry;
  final bool solved;
  final bool disabled;
  final VoidCallback onHint;

  const _ClueTile({
    required this.entry,
    required this.solved,
    required this.disabled,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: solved ? Colors.green.shade50 : null,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: solved ? Colors.green : Colors.blueGrey.shade100,
          child: Text(
            '${entry.number}',
            style: TextStyle(
              fontSize: 12,
              color: solved ? Colors.white : Colors.black87,
            ),
          ),
        ),
        title: Text(
          entry.entry.clue,
          style: TextStyle(
            decoration: solved ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: solved
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.lightbulb_outline),
                tooltip: 'Reveal next letter',
                onPressed: disabled ? null : onHint,
              ),
      ),
    );
  }
}