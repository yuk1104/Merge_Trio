import 'package:flutter/material.dart';
import '../managers/skin_manager.dart';
import '../managers/invite_manager.dart';
import '../managers/language_manager.dart';
import '../widgets/game_colors.dart';

class UnlockNeonDialog extends StatefulWidget {
  const UnlockNeonDialog({super.key});

  @override
  State<UnlockNeonDialog> createState() => _UnlockNeonDialogState();
}

class _UnlockNeonDialogState extends State<UnlockNeonDialog> {
  final SkinManager _skinManager = SkinManager();
  final InviteManager _inviteManager = InviteManager();

  @override
  void initState() {
    super.initState();
    _skinManager.addListener(_onSkinChanged);
    _inviteManager.addListener(_onInviteChanged);
    // 招待数を更新
    _inviteManager.refreshInviteCount();
  }

  @override
  void dispose() {
    _skinManager.removeListener(_onSkinChanged);
    _inviteManager.removeListener(_onInviteChanged);
    super.dispose();
  }

  void _onSkinChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onInviteChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCount = _inviteManager.inviteCount;
    final required = SkinManager.requiredShareCount;
    final progress = currentCount / required;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: const Color(0xFFFF00FF).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      title: Column(
        children: [
          // ネオンカラーのアイコン
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF00FF), Color(0xFF00D4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF00FF).withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            LanguageManager().translate('neon'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 説明テキスト
            Text(
              LanguageManager().translate('unlock_neon_description'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // 招待コード表示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF00FF).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    LanguageManager().translate('my_invite_code'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _inviteManager.myInviteCode ?? '------',
                    style: const TextStyle(
                      color: Color(0xFFFF00FF),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 進捗バー
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LanguageManager().translate('share_progress'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$currentCount / $required',
                      style: TextStyle(
                        color: currentCount >= required
                            ? const Color(0xFF00FF88)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 20,
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        currentCount >= required
                            ? const Color(0xFF00FF88)
                            : const Color(0xFFFF00FF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 解放条件
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.share,
                        color: const Color(0xFFFF00FF).withValues(alpha: 0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LanguageManager().translate('unlock_conditions'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCondition(
                    LanguageManager().translate('share_with_friends'),
                    currentCount >= required,
                  ),
                ],
              ),
            ),

            if (currentCount >= required) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00FF88).withValues(alpha: 0.2),
                      const Color(0xFF00D4FF).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00FF88),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF00FF88),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        LanguageManager().translate('neon_unlocked'),
                        style: const TextStyle(
                          color: Color(0xFF00FF88),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
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
    );
  }

  Widget _buildCondition(String text, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: isCompleted ? const Color(0xFF00FF88) : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isCompleted ? Colors.white : Colors.white60,
                fontSize: 13,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
