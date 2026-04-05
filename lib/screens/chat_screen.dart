import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../models/tracked_product.dart';
import '../providers/tracked_products_provider.dart';
import '../services/chat_service.dart';
import '../utils/constants.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Product product;

  const ChatScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage.bot(
        'Hi! I am your Smart Assistant for ${widget.product.name}. '
        'Ask me if you should buy now or wait!',
        includeInContext: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  TrackedProduct? _trackedProductForCurrentItem() {
    final trackedAsync = ref.read(trackedProductsProvider);
    return trackedAsync.maybeWhen(
      data: (items) {
        for (final item in items) {
          if (item.product.id == widget.product.id) {
            return item;
          }
        }
        return null;
      },
      orElse: () => null,
    );
  }

  List<ChatHistoryEntry> _historyEntries() {
    final contextMessages = _messages.where((message) => message.includeInContext);
    return contextMessages
        .skip(contextMessages.length > 6 ? contextMessages.length - 6 : 0)
        .map(
          (message) => ChatHistoryEntry(
            role: message.isUser ? 'user' : 'assistant',
            message: message.text,
          ),
        )
        .toList();
  }

  Future<void> _sendMessage() async {
    final userText = _messageController.text.trim();
    if (userText.isEmpty) {
      _showSnackBar('Please enter a message.');
      return;
    }
    if (_isLoading) return;

    setState(() {
      _messages.add(_ChatMessage.user(userText));
      _messageController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await chatService.sendMessage(
        message: userText,
        product: widget.product,
        trackedProduct: _trackedProductForCurrentItem(),
        history: _historyEntries(),
      );

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage.bot(reply));
      });
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(error.toString());
      setState(() {
        _messages.add(
          _ChatMessage.bot(
            'Sorry, I could not reach the assistant. Check your network or backend server.',
          ),
        );
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _messages.length + (_isLoading ? 1 : 0);
    final trackedProduct = _trackedProductForCurrentItem();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Assistant'),
        backgroundColor: const Color(AppColors.primary),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _ChatContextBanner(
            product: widget.product,
            trackedProduct: trackedProduct,
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: totalItems,
              itemBuilder: (context, index) {
                if (_isLoading && index == totalItems - 1) {
                  return const _TypingBubble();
                }

                final message = _messages[index];
                return _MessageBubble(
                  text: message.text,
                  isUser: message.isUser,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask about best time to buy...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool includeInContext;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.includeInContext = true,
  });

  factory _ChatMessage.user(String text) =>
      _ChatMessage(text: text, isUser: true);

  factory _ChatMessage.bot(String text, {bool includeInContext = true}) =>
      _ChatMessage(
        text: text,
        isUser: false,
        includeInContext: includeInContext,
      );
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

class _ChatContextBanner extends StatelessWidget {
  const _ChatContextBanner({
    required this.product,
    required this.trackedProduct,
  });

  final Product product;
  final TrackedProduct? trackedProduct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[
      _InfoChip(
        icon: Icons.storefront_outlined,
        label: '${product.bestPlatform} best',
      ),
      _InfoChip(
        icon: Icons.currency_rupee,
        label: product.bestPrice.round().toString(),
      ),
      _InfoChip(
        icon: Icons.trending_down,
        label: 'Save ${product.priceDifference.round()}',
      ),
    ];

    if (trackedProduct != null) {
      chips.add(
        _InfoChip(
          icon: Icons.favorite,
          label: 'Tracked',
        ),
      );
      if (trackedProduct?.targetPrice != null) {
        chips.add(
          _InfoChip(
            icon: Icons.notifications_active_outlined,
            label: 'Target ${trackedProduct!.targetPrice!.round()}',
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: const Color(AppColors.primary).withOpacity(0.08),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask about timing, platform choice, savings, or whether this is near a recent low.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.black.withOpacity(0.68),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(AppColors.primary)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Thinking...', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
