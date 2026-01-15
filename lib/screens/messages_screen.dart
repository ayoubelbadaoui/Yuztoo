import 'package:flutter/material.dart';
import '../theme.dart';
import '../types.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen(
      {super.key,
      required this.role,
      required this.onBack,
      required this.onConversationSelect});

  final UserRole role;
  final VoidCallback onBack;
  final VoidCallback onConversationSelect;

  @override
  Widget build(BuildContext context) {
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
              Text('Messages', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher une conversation...',
              prefixIcon: Icon(Icons.search, color: YColors.muted),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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

class _Conversation {
  const _Conversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    this.image,
  });

  final int id;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final String? image;
}

const _clientConversations = [
  _Conversation(
    id: 1,
    name: 'Café Central',
    lastMessage: 'Merci pour votre visite !',
    time: '10:30',
    unread: 2,
    image: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=100',
  ),
  _Conversation(
    id: 2,
    name: 'Pharmacie El Amane',
    lastMessage: 'Votre commande est prête',
    time: 'Hier',
    unread: 0,
    image: 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=100',
  ),
  _Conversation(
    id: 3,
    name: 'Pâtisserie Délice',
    lastMessage: 'Nouvelle promotion disponible',
    time: '2 Jan',
    unread: 1,
    image: 'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=100',
  ),
];

const _merchantConversations = [
  _Conversation(
    id: 1,
    name: 'Mohammed A.',
    lastMessage: 'Quelle heure fermez-vous ?',
    time: '14:23',
    unread: 1,
  ),
  _Conversation(
    id: 2,
    name: 'Fatima Z.',
    lastMessage: 'Merci beaucoup !',
    time: '12:45',
    unread: 0,
  ),
  _Conversation(
    id: 3,
    name: 'Ahmed K.',
    lastMessage: 'Est-ce que vous livrez ?',
    time: 'Hier',
    unread: 2,
  ),
];
