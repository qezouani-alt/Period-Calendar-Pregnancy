import 'package:flutter/material.dart';

import '../../../core/design_system/app_theme.dart';
import '../../shared/domain/health_mode_service.dart';
import '../domain/luna_message.dart';
import 'luna_chat_controller.dart';

class AiAgentPage extends StatefulWidget {
  const AiAgentPage({super.key, required this.healthContext});

  final ActiveHealthContext healthContext;

  @override
  State<AiAgentPage> createState() => _AiAgentPageState();
}

class _AiAgentPageState extends State<AiAgentPage> with WidgetsBindingObserver {
  final _message = TextEditingController();
  final _messageFocus = FocusNode();
  final _scrollController = ScrollController();
  late LunaChatController _chat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageFocus.addListener(_onMessageFocusChanged);
    _createChatController();
  }

  @override
  void didUpdateWidget(covariant AiAgentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.healthContext.isPregnancy !=
        widget.healthContext.isPregnancy) {
      _chat
        ..removeListener(_onChatChanged)
        ..dispose();
      _createChatController();
    }
  }

  void _createChatController() {
    _chat = LunaChatController(healthContext: widget.healthContext)
      ..addListener(_onChatChanged);
  }

  void _onChatChanged() {
    if (!mounted) return;
    setState(() {});
    _scrollToLatestMessage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageFocus.removeListener(_onMessageFocusChanged);
    _chat
      ..removeListener(_onChatChanged)
      ..dispose();
    _message.dispose();
    _messageFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLatestMessageAfterLayout();
    });
  }

  void _onMessageFocusChanged() {
    if (_messageFocus.hasFocus) {
      _scrollToLatestMessage();
      Future<void>.delayed(const Duration(milliseconds: 280), () {
        if (mounted && _messageFocus.hasFocus) _scrollToLatestMessage();
      });
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_messageFocus.hasFocus) _scrollToLatestMessage();
  }

  void _scrollToLatestMessageAfterLayout() {
    if (!mounted || !_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send([String? suggestedText]) async {
    final text = (suggestedText ?? _message.text).trim();
    if (text.isEmpty || _chat.isSending) return;
    _message.clear();
    await _chat.send(text);
  }

  Future<void> _retry() async {
    final text = _chat.lastFailedMessage;
    if (text == null) return;
    await _chat.send(text, retry: true);
  }

  @override
  Widget build(BuildContext context) {
    final messages = _chat.messages;
    final showStarters = messages.length == 1 && !_chat.isSending;
    final itemCount =
        messages.length + (showStarters ? 1 : 0) + (_chat.isSending ? 1 : 0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.lg,
            AppSpace.lg,
            AppSpace.md,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.lavender.withValues(alpha: .34),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.pregnancy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Luna',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (messages.length > 1)
                IconButton(
                  tooltip: 'Clear this chat',
                  onPressed: _chat.isSending ? null : _chat.clear,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.md,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index < messages.length) {
                final message = messages[index];
                final canRetry =
                    message.isError && _chat.lastFailedMessage != null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AgentBubble(
                    message: message,
                    onRetry: canRetry ? _retry : null,
                  ),
                );
              }
              if (showStarters && index == messages.length) {
                return _StarterPrompts(
                  prompts: _chat.starterPrompts,
                  onSelected: _send,
                );
              }
              return const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: _ThinkingBubble(),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.sm,
              AppSpace.lg,
              AppSpace.md,
            ),
            child: Column(
              children: [
                Text(
                  'Luna only uses the details you choose to share in this chat.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    height: 1.2,
                    letterSpacing: .35,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(
                  'General education only—not diagnosis, treatment, or emergency care.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    height: 1.2,
                    letterSpacing: .35,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 7),
                TextField(
                  controller: _message,
                  focusNode: _messageFocus,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _chat.isSending ? null : (_) => _send(),
                  decoration: InputDecoration(
                    labelText: 'Message Luna',
                    hintText: 'Write a message…',
                    suffixIcon: _chat.isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_upward_rounded),
                            tooltip: 'Send',
                            onPressed: _send,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StarterPrompts extends StatelessWidget {
  const _StarterPrompts({required this.prompts, required this.onSelected});

  final List<String> prompts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.md),
    child: LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final cardWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List<Widget>.generate(
            prompts.length,
            (index) => SizedBox(
              width: cardWidth,
              child: _SuggestionCard(
                prompt: prompts[index],
                onPressed: () => onSelected(prompts[index]),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.prompt, required this.onPressed});

  final String prompt;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.medium);
    return Semantics(
      button: true,
      label: prompt,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.rose.withValues(alpha: .23),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
              borderRadius: borderRadius,
              border: Border.all(
                color: AppColors.pregnancy.withValues(alpha: .32),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.plum.withValues(alpha: .06),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(left: 8, right: 5),
                  decoration: BoxDecoration(
                    color: AppColors.pregnancy.withValues(alpha: .16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppColors.berry,
                  ),
                ),
                Expanded(
                  child: Text(
                    prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.plum,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .08,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.lavender.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Luna is thinking…'),
        ],
      ),
    ),
  );
}

class _AgentBubble extends StatelessWidget {
  const _AgentBubble({required this.message, this.onRetry});

  final LunaMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final background = message.isUser
        ? AppColors.plum
        : message.isError
        ? AppColors.rose.withValues(alpha: .2)
        : AppColors.lavender.withValues(alpha: .14);
    final foreground = message.isUser
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!message.isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Luna',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.pregnancy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Text(
              message.text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: foreground, height: 1.4),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
