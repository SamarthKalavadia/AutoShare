import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a single chat message in Firestore.
class ChatMessage extends Equatable {
  final String messageId;
  final String rideId;
  final String senderId;
  final String senderName;
  final String receiverUid;
  final String text;
  final DateTime sentAt;
  final bool isDeleted;
  final Map<String, bool> readBy; // uid → true

  const ChatMessage({
    required this.messageId,
    required this.rideId,
    required this.senderId,
    required this.senderName,
    this.receiverUid = '',
    required this.text,
    required this.sentAt,
    this.isDeleted = false,
    this.readBy = const {},
  });

  bool isReadBy(String uid) => readBy[uid] == true;

  factory ChatMessage.create({
    required String rideId,
    required String senderId,
    required String senderName,
    required String receiverUid,
    required String text,
  }) {
    return ChatMessage(
      messageId: '',
      rideId: rideId,
      senderId: senderId,
      senderName: senderName,
      receiverUid: receiverUid,
      text: text,
      sentAt: DateTime.now(),
    );
  }

  ChatMessage copyWith({
    String? messageId,
    String? rideId,
    String? senderId,
    String? senderName,
    String? receiverUid,
    String? text,
    DateTime? sentAt,
    bool? isDeleted,
    Map<String, bool>? readBy,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      rideId: rideId ?? this.rideId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverUid: receiverUid ?? this.receiverUid,
      text: text ?? this.text,
      sentAt: sentAt ?? this.sentAt,
      isDeleted: isDeleted ?? this.isDeleted,
      readBy: readBy ?? this.readBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'rideId': rideId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverUid': receiverUid,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
      'isDeleted': isDeleted,
      'readBy': readBy,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    final readByRaw = map['readBy'];
    final readBy = readByRaw is Map<String, dynamic>
        ? readByRaw.map((k, v) => MapEntry(k, v == true))
        : <String, bool>{};

    return ChatMessage(
      messageId: docId,
      rideId: map['rideId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      receiverUid: map['receiverUid'] as String? ?? '',
      text: map['text'] as String? ?? '',
      sentAt: map['sentAt'] is Timestamp
          ? (map['sentAt'] as Timestamp).toDate()
          : DateTime.now(),
      isDeleted: map['isDeleted'] as bool? ?? false,
      readBy: readBy,
    );
  }

  factory ChatMessage.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessage.fromMap(data, doc.id);
  }

  @override
  List<Object?> get props => [
    messageId,
    senderId,
    text,
    sentAt,
    isDeleted,
    readBy,
  ];
}

/// Represents the top-level chat room document (per ride).
class ChatRoom extends Equatable {
  final String chatId; // == rideId
  final String rideId;
  final List<String> participants;
  final Map<String, bool> typing; // uid → isTyping
  final DateTime? lastMessageAt;
  final String lastMessageText;

  const ChatRoom({
    required this.chatId,
    required this.rideId,
    this.participants = const [],
    this.typing = const {},
    this.lastMessageAt,
    this.lastMessageText = '',
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String docId) {
    final typingRaw = map['typing'];
    final typing = typingRaw is Map<String, dynamic>
        ? typingRaw.map((k, v) => MapEntry(k, v == true))
        : <String, bool>{};

    return ChatRoom(
      chatId: docId,
      rideId: map['rideId'] as String? ?? docId,
      participants: List<String>.from(map['participants'] ?? []),
      typing: typing,
      lastMessageAt: map['lastMessageAt'] is Timestamp
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastMessageText: map['lastMessageText'] as String? ?? '',
    );
  }

  factory ChatRoom.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatRoom.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'rideId': rideId,
      'participants': participants,
      'typing': typing,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'lastMessageText': lastMessageText,
    };
  }

  @override
  List<Object?> get props => [
    chatId,
    rideId,
    participants,
    typing,
    lastMessageAt,
  ];
}
