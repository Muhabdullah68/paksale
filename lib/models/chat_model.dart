import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String status; // 'sent' | 'delivered' | 'read'
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.status = 'sent',
    required this.createdAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      text: d['text'] as String? ?? '',
      imageUrl: d['imageUrl'] as String?,
      status: d['status'] as String? ?? 'sent',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      status: map['status'] ?? 'sent',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'text': text,
    'imageUrl': imageUrl,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'imageUrl': imageUrl,
    'status': status,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantAvatars;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastSenderId;
  final Map<String, int> unreadCount;
  final String productId;
  final String productTitle;
  final String productImageUrl;
  final bool isActive;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantAvatars,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderId,
    required this.unreadCount,
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    this.isActive = true,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(d['participants'] as List? ?? []),
      participantNames: Map<String, String>.from(d['participantNames'] as Map? ?? {}),
      participantAvatars: Map<String, String>.from(d['participantAvatars'] as Map? ?? {}),
      lastMessage: d['lastMessage'] as String? ?? '',
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSenderId: d['lastSenderId'] as String? ?? '',
      unreadCount: Map<String, int>.from(d['unreadCount'] as Map? ?? {}),
      productId: d['productId'] as String? ?? '',
      productTitle: d['productTitle'] as String? ?? '',
      productImageUrl: d['productImageUrl'] as String? ?? '',
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  factory ConversationModel.fromMap(String id, Map<String, dynamic> map) {
    List<String> participantsList = [];
    if (map['participants'] is List) {
      participantsList = List<String>.from(map['participants']);
    } else if (map['participants'] is Map) {
      participantsList = (map['participants'] as Map).keys.cast<String>().toList();
    }

    return ConversationModel(
      id: id,
      participants: participantsList,
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantAvatars: Map<String, String>.from(map['participantAvatars'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(map['lastMessageAt'] ?? 0),
      lastSenderId: map['lastSenderId'] ?? '',
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    Map<String, String>? participantNames,
    Map<String, String>? participantAvatars,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastSenderId,
    Map<String, int>? unreadCount,
    String? productId,
    String? productTitle,
    String? productImageUrl,
    bool? isActive,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'participants': participants,
    'participantNames': participantNames,
    'participantAvatars': participantAvatars,
    'lastMessage': lastMessage,
    'lastMessageAt': Timestamp.fromDate(lastMessageAt),
    'lastSenderId': lastSenderId,
    'unreadCount': unreadCount,
    'productId': productId,
    'productTitle': productTitle,
    'productImageUrl': productImageUrl,
    'isActive': isActive,
  };

  Map<String, dynamic> toMap() => {
    'participants': {for (var p in participants) p: true},
    'participantNames': participantNames,
    'participantAvatars': participantAvatars,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt.millisecondsSinceEpoch,
    'lastSenderId': lastSenderId,
    'unreadCount': unreadCount,
    'productId': productId,
    'productTitle': productTitle,
    'productImageUrl': productImageUrl,
    'isActive': isActive,
  };
}
