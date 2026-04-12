part of 'messages_screen.dart';

extension _MessagesScreenUi on MessagesScreen {
  Widget _buildMessagesContent(BuildContext context) {
    final conversations =
        role == UserRole.client ? _clientConversations : _merchantConversations;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.messages,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchConversation,
              prefixIcon: const Icon(Icons.search, color: YColors.muted),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
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
                          role == UserRole.client
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.network(
                                    conv.image ?? '',
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                      color: YColors.primary,
                                      shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Text(conv.name[0],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700)),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(conv.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    Text(conv.time,
                                        style: const TextStyle(
                                            color: YColors.muted,
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        conv.lastMessage,
                                        style: const TextStyle(
                                            color: YColors.muted),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (conv.unread > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: YColors.secondary,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text('${conv.unread}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700)),
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
    );
  }
}
