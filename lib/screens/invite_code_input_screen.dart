import 'package:flutter/material.dart';
import '../managers/invite_manager.dart';
import '../managers/language_manager.dart';
import '../widgets/game_colors.dart';
import 'home_screen.dart';

class InviteCodeInputScreen extends StatefulWidget {
  const InviteCodeInputScreen({super.key});

  @override
  State<InviteCodeInputScreen> createState() => _InviteCodeInputScreenState();
}

class _InviteCodeInputScreenState extends State<InviteCodeInputScreen> {
  final TextEditingController _codeController = TextEditingController();
  final InviteManager _inviteManager = InviteManager();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = LanguageManager().translate('enter_invite_code');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _inviteManager.useInviteCode(code);

    if (!mounted) return;

    if (success) {
      // 成功したらネオンスキンのアンロックに1歩近づく
      // （招待コードを使用することで、自分も招待にカウントされる）

      if (!mounted) return;

      // ダイアログを表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: const Color(0xFF00FF88).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          title: Column(
            children: [
              Icon(
                Icons.check_circle,
                color: const Color(0xFF00FF88),
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                LanguageManager().translate('invite_code_success'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            LanguageManager().translate('invite_code_success_message'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ダイアログを閉じる
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              },
              child: Text(
                LanguageManager().translate('close'),
                style: const TextStyle(
                  color: GameColors.accentPink,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = LanguageManager().translate('invalid_invite_code');
      });
    }
  }

  Future<void> _skip() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                // タイトル
                Icon(
                  Icons.card_giftcard,
                  size: 80,
                  color: GameColors.accentPink,
                ),
                const SizedBox(height: 24),
                Text(
                  LanguageManager().translate('have_invite_code'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  LanguageManager().translate('invite_code_description'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // 招待コード入力フィールド
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 4,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: GameColors.accentPink,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    errorText: _errorMessage,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),

                // 送信ボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameColors.accentPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            LanguageManager().translate('submit'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // スキップボタン
                TextButton(
                  onPressed: _isLoading ? null : _skip,
                  child: Text(
                    LanguageManager().translate('skip'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
