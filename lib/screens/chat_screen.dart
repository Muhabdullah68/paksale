// screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../models/chat_model.dart';
import '../services/language_provider.dart';
import '../web/web_shell.dart';

class ChatScreen extends StatefulWidget {
  final bool webEmbedded;
  const ChatScreen({super.key, this.webEmbedded = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<ChatProvider>().listenToConversations(auth.firebaseUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatProvider = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final t = context.watch<LanguageProvider>().t;

    final isDark = theme.brightness == Brightness.dark;

    if (!auth.isAuthenticated) {
      final prompt = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(t['login_prompt'] ?? 'Please sign in to see your chats',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        ),
      );
      if (kIsWeb) {
        return widget.webEmbedded
            ? prompt
            : WebPage(
                breadcrumbs: const [WebCrumb('Chat')],
                content: prompt,
              );
      }
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const AppLogo(),
        ),
        body: prompt,
      );
    }

    final listBody = chatProvider.isLoading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          )
        : chatProvider.error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        t['chat_error'] ?? 'Unable to load chats',
                        style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        chatProvider.error!.contains('suspended')
                            ? 'Firebase service is currently suspended. Please check your project settings.'
                            : chatProvider.error!,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          final auth = context.read<AuthProvider>();
                          if (auth.isAuthenticated) {
                            context.read<ChatProvider>().listenToConversations(
                                auth.firebaseUser!.uid);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold),
                        child: Text(t['retry'] ?? 'Retry',
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
            : chatProvider.conversations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            t['no_conversations'] ?? 'No conversations yet',
                            style: TextStyle(
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textSecondaryLightMode,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t['start_chat_prompt'] ??
                                'Find a product you like and start a conversation with the seller!',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: widget.webEmbedded,
                    physics: widget.webEmbedded
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    itemCount: chatProvider.conversations.length,
                    itemBuilder: (ctx, i) => _ChatListItem(
                      conversation: chatProvider.conversations[i],
                      currentUserId: auth.firebaseUser!.uid,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConversationScreen(
                              conversation: chatProvider.conversations[i]),
                        ),
                      ),
                    ),
                  );

    final body = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: isDark ? AppColors.primaryDark : AppColors.primary,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t['search_conversations'] ?? 'Search conversations...',
                          style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  onPressed: () => _showNewMessageDialog(context),
                ),
              ),
            ],
          ),
        ),
        widget.webEmbedded
            ? Flexible(child: listBody)
            : Expanded(child: listBody),
      ],
    );

    if (kIsWeb) {
      return widget.webEmbedded
          ? body
          : WebPage(
              breadcrumbs: const [WebCrumb('Chat')],
              content: body,
            );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const AppLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: body,
    );
  }

  void _showNewMessageDialog(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<LanguageProvider>().t;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.brightness == Brightness.dark ? AppColors.primaryDark : theme.cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t['new_message'] ?? 'New Message',
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color ?? Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: t['search_users'] ?? 'Search users...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: theme.brightness == Brightness.dark ? theme.cardTheme.color : Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  _UserListItem(name: 'Ahmed Al-Mansoori', avatar: '👤'),
                  _UserListItem(name: 'Fatima Hassan', avatar: '👩'),
                  _UserListItem(name: 'Mohammed Khalid', avatar: '👨'),
                  _UserListItem(name: 'Noor Al-Sabah', avatar: '👩'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherUserId = conversation.participants.firstWhere((id) => id != currentUserId);
    final otherUserName = conversation.participantNames[otherUserId] ?? 'User';
    final unread = conversation.unreadCount[currentUserId] ?? 0;

    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.2))),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Center(
                    child: Text(
                      otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.primaryDark : Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(conversation.lastMessageAt),
                        style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unread > 0 ? theme.textTheme.bodyLarge?.color : (isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
}

class _UserListItem extends StatelessWidget {
  final String name;
  final String avatar;

  const _UserListItem({required this.name, required this.avatar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Starting new chat from list coming soon!')),
        );
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Text(avatar, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15),
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, size: 18),
          ],
        ),
      ),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  final ConversationModel conversation;

  const ConversationScreen({super.key, required this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  void _pickImage() async {
    // Show bottom sheet to choose source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    final auth = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    final myId = auth.firebaseUser!.uid;
    final myName = auth.userModel?.name ?? 'User';
    final recipientId = widget.conversation.participants
        .firstWhere((id) => id != myId, orElse: () => '');

    try {
      await chatProvider.sendImageMessage(
        widget.conversation.id,
        image,
        myId,
        recipientId: recipientId.isNotEmpty ? recipientId : null,
        senderName: myName,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending image: $e')),
        );
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    final sensitivePatterns = [
      RegExp(r'03\d{2}[-\s]?\d{7}'),           // Pakistan mobile
      RegExp(r'\+92[-\s]?\d{3}[-\s]?\d{7}'),   // +92 format
      RegExp(r'\d{5}[-\s]?\d{7}[-\s]?\d'),     // CNIC
      RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'), // bank card
      RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'),             // bank account
      RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'), // email
    ];
    final hasSensitive = sensitivePatterns.any((r) => r.hasMatch(text));

    if (hasSensitive) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Privacy Warning', style: TextStyle(fontSize: 18)),
          ]),
          content: const Text(
            'For your safety, avoid sharing:\n'
            '• Phone numbers\n'
            '• CNIC numbers\n'
            '• Bank account details\n'
            '• Home addresses\n'
            '• Passwords\n\n'
            'Are you sure you want to send this message?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Edit Message')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
              child: const Text('Send Anyway', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final auth = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    final myId = auth.firebaseUser!.uid;
    final myName = auth.userModel?.name ?? 'User';

    final recipientId = widget.conversation.participants
        .firstWhere((id) => id != myId, orElse: () => '');

    final message = ChatMessage(
      id: '',
      senderId: myId,
      text: text,
      createdAt: DateTime.now(),
    );

    _messageController.clear();
    await chatProvider.sendMessage(
      widget.conversation.id,
      message,
      recipientId: recipientId.isNotEmpty ? recipientId : null,
      senderName: myName,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final t = context.watch<LanguageProvider>().t;
    final myId = auth.firebaseUser?.uid ?? '';
    final otherUserId = widget.conversation.participants.firstWhere((id) => id != myId, orElse: () => '');
    final otherUserName = widget.conversation.participantNames[otherUserId] ?? 'User';

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    t['online'] ?? 'Online',
                    style: const TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Product Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.primaryDark : AppColors.primary,
              border: Border(bottom: BorderSide(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? theme.cardTheme.color : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      widget.conversation.productImageUrl.isNotEmpty ? '' : '📱',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.conversation.productTitle,
                        style: TextStyle(
                            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLightMode,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        t['negotiable_price'] ?? 'Negotiable price',
                        style: const TextStyle(color: AppColors.gold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(t['view_ad'] ?? 'View Ad', style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatProvider.getMessages(widget.conversation.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) => _MessageBubble(
                    message: messages[i],
                    isMe: messages[i].senderId == auth.firebaseUser!.uid,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildMessageInput(context),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDark : theme.cardTheme.color,
        border: Border(top: BorderSide(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: AppColors.textMuted),
            onPressed: _pickImage,
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 100),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: t['type_message'] ?? 'Type a message...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('👤', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageMenu(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.isMe ? AppColors.gold : theme.cardTheme.color,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                    bottomRight: Radius.circular(widget.isMe ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (widget.message.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.message.imageUrl!,
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, error, stackTrace) => Container(
                            width: 200,
                            height: 150,
                            color: AppColors.surface,
                            child: const Center(
                                child: Icon(Icons.broken_image_outlined,
                                    color: AppColors.textMuted, size: 32)),
                          ),
                          loadingBuilder: (ctx, child, lp) {
                            if (lp == null) return child;
                            return const SizedBox(
                              width: 200,
                              height: 150,
                              child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.message.text.isNotEmpty)
                      Text(
                        widget.message.text,
                        style: TextStyle(
                          color: widget.isMe ? Colors.white : theme.textTheme.bodyLarge?.color ?? Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.message.createdAt.hour}:${widget.message.createdAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: widget.isMe ? Colors.white70 : AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        if (widget.isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            widget.message.status == 'read' ? Icons.done_all : Icons.done,
                            size: 14,
                            color: widget.message.status == 'read' ? Colors.white : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: AppColors.primary),
              title: const Text('Report Message'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message reported!')),
                );
              },
            ),
            if (widget.isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Implement delete message functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delete functionality coming soon!')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

