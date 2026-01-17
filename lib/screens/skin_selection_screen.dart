import 'package:flutter/material.dart';
import '../managers/skin_manager.dart';
import '../managers/sound_manager.dart';
import '../managers/language_manager.dart';
import '../widgets/game_colors.dart';
import 'unlock_pastel_dialog.dart';

class SkinSelectionScreen extends StatefulWidget {
  const SkinSelectionScreen({super.key});

  @override
  State<SkinSelectionScreen> createState() => _SkinSelectionScreenState();
}

class _SkinSelectionScreenState extends State<SkinSelectionScreen> {
  final SoundManager _soundManager = SoundManager();
  final SkinManager _skinManager = SkinManager();

  @override
  void initState() {
    super.initState();
    // LanguageManagerの変更をリッスン
    LanguageManager().addListener(_onLanguageChanged);
    // SkinManagerの変更をリッスン
    _skinManager.addListener(_onSkinChanged);
  }

  @override
  void dispose() {
    LanguageManager().removeListener(_onLanguageChanged);
    _skinManager.removeListener(_onSkinChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSkinChanged() {
    if (mounted) {
      setState(() {});
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
              Expanded(
                child: _buildSkinList(),
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
          Expanded(
            child: Text(
              LanguageManager().translate('tile_skin'),
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  Widget _buildSkinList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        Text(
          LanguageManager().translate('select_skin'),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        ...TileSkin.values.map((skin) => _buildSkinCard(skin)),
      ],
    );
  }

  Widget _buildSkinCard(TileSkin skin) {
    final isSelected = skin == _skinManager.currentSkin;
    final isLocked = skin == TileSkin.pastel && !_skinManager.isPastelUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isSelected ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? GameColors.accentPink
              : Colors.white.withValues(alpha: 0.2),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: GameColors.accentPink.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            _soundManager.playButton();

            // パステルがロックされている場合はアンロックダイアログを表示
            if (isLocked) {
              showDialog(
                context: context,
                builder: (context) => const UnlockPastelDialog(),
              );
              return;
            }

            await _skinManager.setSkin(skin);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // スキン名とステータス
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            _skinManager.getSkinName(skin),
                            style: TextStyle(
                              color: isSelected
                                  ? GameColors.accentPinkLight
                                  : isLocked
                                      ? Colors.white60
                                      : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              letterSpacing: 1,
                            ),
                          ),
                          if (isLocked) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    LanguageManager().translate('locked'),
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: GameColors.accentPink,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: GameColors.accentPink.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // タイルプレビュー
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [1, 2, 3, 4, 5, 6].map((number) {
                    final colors = _skinManager.getTileGradient(number, skin);
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colors.first.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: TextStyle(
                            color: _skinManager.getTileTextColor(number, skin),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (isLocked) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            LanguageManager().translate('unlock_skin_info'),
                            style: TextStyle(
                              color: Colors.orange.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
