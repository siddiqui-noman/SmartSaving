import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../models/tracked_product.dart';
import '../providers/tracked_products_provider.dart';
import '../services/chat_service.dart';
import '../utils/constants.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ChatScreen({
    super.key,
    this.product, // optional — null means general assistant mode
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
        widget.product != null
            ? 'Hi! I am your Smart Assistant for ${widget.product!.name}. '
                'Ask me if you should buy now or wait!'
            : 'Hi! I am your SmartSaving AI Assistant 🤖\n'
                'Ask me anything — compare products, find deals, or get buying advice!',
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
    if (widget.product == null) return null;
    final trackedAsync = ref.read(trackedProductsProvider);
    return trackedAsync.maybeWhen(
      data: (items) {
        for (final item in items) {
          if (item.product.id == widget.product!.id) {
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
          if (widget.product != null)
            _ChatContextBanner(
              product: widget.product!,
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
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(AppColors.primary),
                      const Color(AppColors.primary).withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(AppColors.primary).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'SMART INSIGHTS ACTIVE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(AppColors.primary),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InsightItem(icon: Icons.compare_arrows_rounded, text: 'Real-time price comparison across top platforms'),
          const SizedBox(height: 8),
          _InsightItem(icon: Icons.query_stats_rounded, text: 'Historical trend analysis and "Buy/Wait" verdict'),
          const SizedBox(height: 8),
          _InsightItem(icon: Icons.notifications_active_rounded, text: 'Instant alerts for your target price drops'),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((chip) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: chip,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InsightItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(AppColors.primary).withOpacity(0.6)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.05) 
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.08)
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(AppColors.primary)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
