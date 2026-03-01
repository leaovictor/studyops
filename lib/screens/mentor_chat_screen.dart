import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system/design_tokens.dart';
import '../core/design_system/typography_scale.dart';
import '../core/design_system/spacing_system.dart';
import '../controllers/auth_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/goal_controller.dart';
import '../services/user_service.dart';
import '../core/theme/app_theme.dart';
import '../models/user_model.dart';

// ─── Chat message model ───────────────────────────────────────────────────────

enum _Role { user, assistant }

class _ChatMessage {
  final _Role role;
  final String text;
  final DateTime timestamp;

  _ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class MentorChatScreen extends ConsumerStatefulWidget {
  const MentorChatScreen({super.key});

  @override
  ConsumerState<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends ConsumerState<MentorChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _hasIntroduced = false;

  static const _quickPrompts = [
    'Como devo começar a estudar hoje?',
    'Me ajude a revisar os tópicos mais urgentes',
    'Qual técnica de memorização é mais eficiente?',
    'Como superar a procrastinação nos estudos?',
    'Me explique sobre revisão espaçada',
    'Qual a diferença entre estudo ativo e passivo?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendIntro());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendIntro() async {
    if (_hasIntroduced) return;
    _hasIntroduced = true;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    // Fetch user profile for displayName
    final userModel = await UserService().getUser(user.uid);
    final name = userModel?.displayName?.split(' ').first ?? 'Estudante';

    setState(() {
      _messages.add(_ChatMessage(
        role: _Role.assistant,
        text:
            'Olá, $name! 👋 Sou o **StudyMentor**, seu coach de estudos pessoal.\n\n'
            'Posso te ajudar com:\n'
            '• Dúvidas sobre qualquer matéria\n'
            '• Estratégias de estudo e memorização\n'
            '• Análise do seu desempenho\n'
            '• Motivação e planejamento\n\n'
            'Como posso te ajudar hoje?',
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _send(String text) async {
    final input = text.trim();
    if (input.isEmpty) return;

    _controller.clear();
    _focusNode.requestFocus();

    setState(() {
      _messages.add(_ChatMessage(
        role: _Role.user,
        text: input,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) throw Exception('Usuário não autenticado');

      final aiService = await ref.read(aiServiceProvider.future);
      if (aiService == null) throw Exception('IA não configurada');

      // Build goal context
      final goals = ref.read(goalsProvider).valueOrNull ?? [];
      final activeGoalId = ref.read(activeGoalIdProvider);
      final goal = goals.firstWhereOrNull((g) => g.id == activeGoalId);
      final objective = goal?.name ?? 'Concurso Público';

      // Fetch user profile for personalContext
      final userModel = await UserService().getUser(user.uid);

      // Build message history (skip intro message)
      final history = _messages
          .skip(1)
          .map((m) => {
                'role': m.role == _Role.user ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      final reply = await aiService.mentorChat(
        userId: user.uid,
        history: history,
        objective: objective,
        personalContext: userModel?.personalContext,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(
            role: _Role.assistant,
            text: reply,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(
            role: _Role.assistant,
            text:
                '❌ Erro ao conectar com o mentor: ${e.toString().replaceAll('Exception: ', '')}',
            timestamp: DateTime.now(),
          ));
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? DesignTokens.darkBg1 : DesignTokens.lightBg1,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DesignTokens.primary, DesignTokens.secondary],
                    ),
                    borderRadius: DesignTokens.brSm,
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: Spacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'StudyMentor',
                      style: AppTypography.headingSm.copyWith(
                        color: isDark
                            ? DesignTokens.darkTextPrimary
                            : DesignTokens.lightTextPrimary,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'IA · Llama 3.3 70B',
                      style: AppTypography.overline.copyWith(
                        color: DesignTokens.primary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: 'Limpar conversa',
                onPressed: () {
                  setState(() {
                    _messages.clear();
                    _hasIntroduced = false;
                  });
                  _sendIntro();
                },
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                // Message list
                Expanded(
                  child: _messages.isEmpty
                      ? _EmptyState(isDark: isDark)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.md, vertical: Spacing.sm),
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i == _messages.length && _isTyping) {
                              return _TypingIndicator(isDark: isDark);
                            }
                            final msg = _messages[i];
                            return _MessageBubble(
                              message: msg,
                              isDark: isDark,
                            );
                          },
                        ),
                ),

                // Quick prompts (show only when few messages)
                if (_messages.length <= 1 && !_isTyping)
                  _QuickPrompts(
                    prompts: _quickPrompts,
                    onTap: _send,
                    isDark: isDark,
                  ),

                // Input bar
                _InputBar(
                  controller: _controller,
                  focusNode: _focusNode,
                  isDark: isDark,
                  isLoading: _isTyping,
                  onSend: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isDark});
  final _ChatMessage message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _Role.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Avatar
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [DesignTokens.primary, DesignTokens.secondary]),
                borderRadius: DesignTokens.brSm,
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: Spacing.xs),
          ],

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md, vertical: Spacing.sm),
              decoration: BoxDecoration(
                color: isUser
                    ? DesignTokens.primary
                    : (isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg2),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: DesignTokens.elevationLow,
              ),
              child: _SimpleMarkdown(
                text: message.text,
                isUser: isUser,
                isDark: isDark,
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: Spacing.xs),
            // User Avatar Placeholder
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.2),
                borderRadius: DesignTokens.brSm,
              ),
              child: Icon(
                Icons.person_rounded,
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.lightTextSecondary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Simple Markdown renderer ─────────────────────────────────────────────────

class _SimpleMarkdown extends StatelessWidget {
  const _SimpleMarkdown(
      {required this.text, required this.isUser, required this.isDark});
  final String text;
  final bool isUser;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Parse basic markdown: **bold**, *italic*, bullet lists
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final isBullet = line.startsWith('• ') || line.startsWith('- ');
        final cleaned = isBullet ? line.substring(2) : line;

        return Padding(
          padding: EdgeInsets.only(top: isBullet ? 2 : 0),
          child: isBullet
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ',
                        style: _baseStyle(isUser, isDark)
                            .copyWith(fontWeight: FontWeight.w700)),
                    Expanded(
                        child:
                            Text(cleaned, style: _baseStyle(isUser, isDark))),
                  ],
                )
              : _parseInlineMarkdown(cleaned, isUser, isDark),
        );
      }).toList(),
    );
  }

  Widget _parseInlineMarkdown(String raw, bool isUser, bool isDark) {
    if (!raw.contains('**')) {
      return Text(raw, style: _baseStyle(isUser, isDark));
    }
    final spans = <TextSpan>[];
    final parts = raw.split('**');
    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        spans.add(TextSpan(
          text: parts[i],
          style:
              _baseStyle(isUser, isDark).copyWith(fontWeight: FontWeight.w700),
        ));
      } else {
        spans.add(TextSpan(
          text: parts[i],
          style: _baseStyle(isUser, isDark),
        ));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }

  TextStyle _baseStyle(bool isUser, bool isDark) =>
      AppTypography.bodySm.copyWith(
        color: isUser
            ? Colors.white
            : (isDark
                ? DesignTokens.darkTextPrimary
                : DesignTokens.lightTextPrimary),
        height: 1.5,
        fontSize: 14,
      );
}

// ─── Typing Indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.isDark});
  final bool isDark;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [DesignTokens.primary, DesignTokens.secondary]),
              borderRadius: DesignTokens.brSm,
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: Spacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  widget.isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg2,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i / 3.0;
                    final value = ((_ctrl.value + delay) % 1.0);
                    final opacity =
                        (value < 0.5) ? value * 2 : (1.0 - value) * 2;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: DesignTokens.primary
                            .withValues(alpha: 0.3 + opacity * 0.7),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Prompts ────────────────────────────────────────────────────────────

class _QuickPrompts extends StatelessWidget {
  const _QuickPrompts({
    required this.prompts,
    required this.onTap,
    required this.isDark,
  });
  final List<String> prompts;
  final void Function(String) onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 80),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.xs),
        child: Row(
          children: prompts.map((p) {
            return Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: InkWell(
                onTap: () => onTap(p),
                borderRadius: DesignTokens.brXl,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md, vertical: Spacing.sm),
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.08),
                    borderRadius: DesignTokens.brXl,
                    border: Border.all(
                        color: DesignTokens.primary.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    p,
                    style: AppTypography.bodySm.copyWith(
                      color: DesignTokens.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.isLoading,
    required this.onSend,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final bool isLoading;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: Spacing.md,
        right: Spacing.md,
        top: Spacing.sm,
        bottom: Spacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg2,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isLoading,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: isLoading ? null : onSend,
              style: AppTypography.bodySm.copyWith(
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: isLoading
                    ? 'StudyMentor está digitando...'
                    : 'Pergunte qualquer coisa...',
                hintStyle: AppTypography.bodySm.copyWith(
                  color: isDark
                      ? DesignTokens.darkTextMuted
                      : DesignTokens.lightTextMuted,
                  fontSize: 13,
                ),
                border: const OutlineInputBorder(
                  borderRadius: DesignTokens.brXl,
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    isDark ? DesignTokens.darkBg3 : DesignTokens.lightBg1,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md, vertical: Spacing.sm),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isLoading
                  ? null
                  : const LinearGradient(
                      colors: [DesignTokens.primary, DesignTokens.secondary],
                    ),
              color: isLoading ? Colors.grey.withValues(alpha: 0.2) : null,
              borderRadius: DesignTokens.brMd,
              boxShadow: isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: DesignTokens.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      )
                    ],
            ),
            child: IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
              onPressed: isLoading ? null : () => onSend(controller.text),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.primary.withValues(alpha: 0.1),
                  DesignTokens.secondary.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded,
                color: DesignTokens.primary, size: 48),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'StudyMentor',
            style: AppTypography.headingMd.copyWith(
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Seu mentor de estudos com IA',
            style: AppTypography.bodySm.copyWith(
              color: isDark
                  ? DesignTokens.darkTextMuted
                  : DesignTokens.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── List extension ──────────────────────────────────────────────────────────

extension _ListExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
