import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/game_model.dart';
import '../theme/theme_provider.dart';

class FunGameScreen extends StatefulWidget {
  const FunGameScreen({super.key});

  @override
  State<FunGameScreen> createState() => _FunGameScreenState();
}

class _FunGameScreenState extends State<FunGameScreen> {
  late GameModel game;
  Offset startSwipeOffset = Offset.zero;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    game = GameModel();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _updateHighScore() async {
    if (game.score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', game.score);
      setState(() {
        highScore = game.score;
      });
    }
  }

  void _handleSwipe(String direction) {
    setState(() {
      bool moved = game.move(direction);
      if (moved) {
        _updateHighScore();
        if (game.isGameOver()) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _showGameOverDialog();
          });
        }
      }
    });
  }

  void _restartGame() {
    setState(() {
      game.resetGame();
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final textStyle = GoogleFonts.poppins(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            );

            return AlertDialog(
              backgroundColor: themeProvider.isDarkMode ? const Color(0xFF2E2E2E) : Colors.white,
              title: Text(
                'Game Over!',
                style: textStyle.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              content: Text('Looks like youâ€™re out of moves!', style: textStyle),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _restartGame();
                  },
                  child: Text('Play Again', style: textStyle),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text('Go to Home', style: textStyle),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black;

          return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 81, 190, 240),
        title: Text('2048',
            style: GoogleFonts.urbanist(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: _restartGame,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: themeProvider.isDarkMode
                ? [const Color(0xFF121212), const Color(0xFF263238)]
                : [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: GestureDetector(
          onPanStart: (details) => startSwipeOffset = details.localPosition,
          onPanEnd: (details) {
            final dx = details.velocity.pixelsPerSecond.dx;
            final dy = details.velocity.pixelsPerSecond.dy;

            if (dx.abs() > dy.abs()) {
              _handleSwipe(dx > 0 ? 'right' : 'left');
            } else {
              _handleSwipe(dy > 0 ? 'down' : 'up');
            }
          },
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Score: ${game.score}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'High Score: $highScore',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('highScore');
                  setState(() => highScore = 0);
                },
                child: const Text('Reset High Score',
                    style: TextStyle(color: Colors.redAccent)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: GameModel.gridSize * GameModel.gridSize,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: GameModel.gridSize,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        int x = index % GameModel.gridSize;
                        int y = index ~/ GameModel.gridSize;
                        int value = game.board[y][x];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: _getTileColor(value, themeProvider.isDarkMode),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              value == 0 ? '' : '$value',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color:
                                    value <= 4 ? Colors.black87 : Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );});
  }

  Color _getTileColor(int value, bool isDark) {
    switch (value) {
      case 2:
        return isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
      case 4:
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1E88E5);
      case 8:
        return isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00ACC1);
      case 16:
        return isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32);
      case 32:
        return isDark ? const Color(0xFFFFF176) : const Color(0xFFFBC02D);
      case 64:
        return isDark ? const Color(0xFFFFD54F) : const Color(0xFFFFA000);
      case 128:
        return isDark ? const Color(0xFFEF9A9A) : const Color(0xFFD32F2F);
      case 256:
        return isDark ? const Color(0xFFCE93D8) : const Color(0xFF8E24AA);
      case 512:
        return isDark ? const Color(0xFFB39DDB) : const Color(0xFF5E35B1);
      case 1024:
        return isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB);
      case 2048:
        return isDark ? const Color(0xFF80CBC4) : const Color(0xFF00796B);
      default:
        return isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);
    }
  }
}
