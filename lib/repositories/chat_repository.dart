import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/chat_model.dart';

class ChatRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://qatar-sale-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  DatabaseReference get _conversationsRef => _database.ref().child('conversations');
  DatabaseReference get _messagesRef => _database.ref().child('messages');

  // Get conversations for a specific user
  Stream<List<ConversationModel>> getUserConversations(String uid) {
    // In RTDB, we might need to structure this differently for efficient querying
    // For now, we'll fetch all and filter client-side, or use a separate index
    return _conversationsRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      List<ConversationModel> conversations = [];
      data.forEach((key, value) {
        final conv = ConversationModel.fromMap(key, Map<String, dynamic>.from(value));
        if (conv.participants.contains(uid)) {
          conversations.add(conv);
        }
      });
      
      // Sort by last message time
      conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return conversations;
    });
  }

  // Get messages for a specific conversation
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _messagesRef.child(conversationId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      List<ChatMessage> messages = [];
      data.forEach((key, value) {
        messages.add(ChatMessage.fromMap(key, Map<String, dynamic>.from(value)));
      });

      // Sort by time
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  Future<void> sendMessage(String conversationId, ChatMessage message) async {
    final newMsgRef = _messagesRef.child(conversationId).push();
    await newMsgRef.set(message.toMap());

    // Update conversation last message
    await _conversationsRef.child(conversationId).update({
      'lastMessage': message.text,
      'lastMessageAt': message.createdAt.millisecondsSinceEpoch,
      'lastSenderId': message.senderId,
    });
  }

  Future<String> createConversation(ConversationModel conversation) async {
    final newConvRef = _conversationsRef.push();
    await newConvRef.set(conversation.toMap());
    return newConvRef.key!;
  }
}
