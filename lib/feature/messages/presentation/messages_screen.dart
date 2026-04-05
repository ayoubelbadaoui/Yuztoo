import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../../types.dart';
import '../../../l10n/app_localizations.dart';

part 'messages_screen.part.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen(
      {super.key,
      required this.role,
      required this.onBack,
      required this.onConversationSelect});

  static String get path => '/messages';

  final UserRole role;
  final VoidCallback onBack;
  final VoidCallback onConversationSelect;

  @override
  Widget build(BuildContext context) => _buildMessagesContent(context);
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
