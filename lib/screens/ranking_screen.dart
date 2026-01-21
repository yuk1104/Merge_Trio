import 'package:flutter/material.dart';
import '../managers/ranking_manager.dart';
import '../managers/sound_manager.dart';
import '../managers/language_manager.dart';
import '../widgets/game_colors.dart';

enum RankingType { allTime, weekly }

class RankingScreen extends StatefulWidget {
  final int initialBoardSize;

  const RankingScreen({super.key, this.initialBoardSize = 4});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final SoundManager _soundManager = SoundManager();
  List<RankingEntry> _rankings = [];
  bool _isLoading = true;
  late int _selectedBoardSize; // 4x4 or 5x5
  RankingType _rankingType = RankingType.allTime;
  DateTime _currentWeek = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedBoardSize = widget.initialBoardSize;
    _loadRankings();
    // LanguageManagerの変更をリッスン
    LanguageManager().addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageManager().removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadRankings() async {
    setState(() {
      _isLoading = true;
    });

    final rankings = _rankingType == RankingType.allTime
        ? await RankingManager().getTopRankings(limit: 100, boardSize: _selectedBoardSize)
        : await RankingManager().getWeeklyRankings(
            limit: 100,
            boardSize: _selectedBoardSize,
            targetDate: _currentWeek,
          );

    if (mounted) {
      setState(() {
        _rankings = rankings;
        _isLoading = false;
      });
    }
  }

  void _switchBoardSize(int newSize) {
    if (_selectedBoardSize != newSize) {
      setState(() {
        _selectedBoardSize = newSize;
      });
      _loadRankings();
    }
  }

  void _switchRankingType(RankingType type) {
    if (_rankingType != type) {
      setState(() {
        _rankingType = type;
        if (type == RankingType.weekly) {
          _currentWeek = DateTime.now();
        }
      });
      _loadRankings();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildRankingTypeToggle(),
              _buildBoardSizeToggle(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: GameColors.accentPink,
                        ),
                      )
                    : _rankings.isEmpty
                        ? _buildEmptyState()
                        : _buildRankingList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () {
              _soundManager.playButton();
              Navigator.pop(context);
            },
          ),
          const Expanded(
            child: Text(
              'RANKING',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: GameColors.accentPink,
                    blurRadius: 15,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildRankingTypeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                label: LanguageManager().translate('all_time'),
                isSelected: _rankingType == RankingType.allTime,
                onTap: () {
                  _soundManager.playButton();
                  _switchRankingType(RankingType.allTime);
                },
              ),
            ),
            Expanded(
              child: _buildToggleButton(
                label: LanguageManager().translate('weekly'),
                isSelected: _rankingType == RankingType.weekly,
                onTap: () {
                  _soundManager.playButton();
                  _switchRankingType(RankingType.weekly);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBoardSizeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                label: '4 × 4',
                isSelected: _selectedBoardSize == 4,
                onTap: () {
                  _soundManager.playButton();
                  _switchBoardSize(4);
                },
              ),
            ),
            Expanded(
              child: _buildToggleButton(
                label: '5 × 5',
                isSelected: _selectedBoardSize == 5,
                onTap: () {
                  _soundManager.playButton();
                  _switchBoardSize(5);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [GameColors.accentPink, GameColors.accentPinkLight],
                )
              : null,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.leaderboard,
            size: 80,
            color: Colors.white38,
          ),
          const SizedBox(height: 20),
          Text(
            LanguageManager().translate('no_rankings'),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _rankings.length,
      itemBuilder: (context, index) {
        final entry = _rankings[index];
        return _buildRankingTile(index + 1, entry);
      },
    );
  }

  Widget _buildRankingTile(int rank, RankingEntry entry) {
    Color rankColor = Colors.white;
    IconData? medalIcon;

    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      medalIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      medalIcon = Icons.emoji_events;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: rank <= 3 ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank <= 3
              ? rankColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
          width: rank <= 3 ? 2 : 1.5,
        ),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // ランク
          SizedBox(
            width: 50,
            child: Row(
              children: [
                if (medalIcon != null)
                  Icon(
                    medalIcon,
                    color: rankColor,
                    size: 24,
                  )
                else
                  Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: rankColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // プレイヤー名
          Expanded(
            child: Text(
              entry.playerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // スコア
          Text(
            '${entry.score}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: GameColors.accentPink,
            ),
          ),
        ],
      ),
    );
  }
}
