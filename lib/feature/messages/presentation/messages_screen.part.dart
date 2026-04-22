part of 'messages_screen.dart';

extension _MessagesScreenUi on MessagesScreen {
  Widget _buildMessagesContent(BuildContext context) {
    final conversations =
        role == UserRole.client ? _clientConversations : _merchantConversations;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    color: YColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.messages,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: YColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchConversation,
                  prefixIcon: const Icon(Icons.search, color: YColors.muted),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Conversation list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conv = conversations[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: onConversationSelect,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              _ConversationAvatar(
                                role: role,
                                name: conv.name,
                                imageUrl: conv.image,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            conv.name,
                                            style: GoogleFonts.outfit(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: YColors.primary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          conv.time,
                                          style: const TextStyle(
                                            color: YColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            conv.lastMessage,
                                            style: const TextStyle(
                                              color: YColors.muted,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (conv.unread > 0)
                                          Container(
                                            margin: const EdgeInsets.only(
                                                left: 6),
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4),
                                            decoration: BoxDecoration(
                                              color: YColors.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${conv.unread}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
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
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar widget — shows network image with fallback initial letter.
class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.role,
    required this.name,
    this.imageUrl,
  });

  final UserRole role;
  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final fallback = Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: YColors.secondary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );

    if (role == UserRole.merchant || imageUrl == null || imageUrl!.isEmpty) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Image.network(
        imageUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: YColors.border,
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
