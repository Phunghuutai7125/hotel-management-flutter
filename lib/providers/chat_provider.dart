import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/room.dart';
import '../services/ai_chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final AiChatService _aiChatService = AiChatService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text, {List<Room> rooms = const []}) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    notifyListeners();

    final reply = await _aiChatService.sendMessage(text, rooms: rooms);

    _messages.add(ChatMessage(
      content: reply,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    _isLoading = false;
    notifyListeners();
  }
}