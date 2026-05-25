import 'package:flutter/material.dart';
import 'dart:io';
import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepo = ChatRepository();
  final StorageService _storageService = StorageService();
  
  List<ConversationModel> _conversations = [];
  bool _isLoading = false;

  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void listenToConversations(String uid) {
    _isLoading = true;
    _error = null;
    notifyListeners();
    _chatRepo.getUserConversations(uid).listen((convs) {
      _conversations = convs;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Chat Provider Error: $error');
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _chatRepo.getMessages(conversationId);
  }

  Future<void> sendMessage(
    String conversationId,
    ChatMessage message, {
    String? recipientId,
    String? senderName,
  }) async {
    try {
      await _chatRepo.sendMessage(conversationId, message);
      // Fire a notification to the recipient (fire-and-forget)
      if (recipientId != null && senderName != null) {
        NotificationService.newMessage(
          recipientId: recipientId,
          senderName: senderName,
          conversationId: conversationId,
          messagePreview: message.imageUrl != null 
              ? 'Sent an image'
              : (message.text.length > 60
                  ? '${message.text.substring(0, 60)}…'
                  : message.text),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendImageMessage(
    String conversationId,
    File image,
    String senderId, {
    String? recipientId,
    String? senderName,
  }) async {
    try {
      final imageUrl = await _storageService.uploadProductImage(
          'chats/$conversationId', image); // Reuse product image upload logic or create specific one
      
      final message = ChatMessage(
        id: '',
        senderId: senderId,
        text: '',
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );
      
      await sendMessage(conversationId, message, recipientId: recipientId, senderName: senderName);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> startConversation(ConversationModel conversation) async {
    try {
      return await _chatRepo.createConversation(conversation);
    } catch (e) {
      rethrow;
    }
  }

  ConversationModel? findConversation(String currentUserId, String otherUserId, String productId) {
    try {
      return _conversations.firstWhere((c) => 
        c.participants.contains(currentUserId) && 
        c.participants.contains(otherUserId) && 
        c.productId == productId
      );
    } catch (_) {
      return null;
    }
  }
}
