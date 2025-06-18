class PrivateMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final String? type;

  PrivateMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.type,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'chatId': chatId,
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
  };

  factory PrivateMessage.fromMap(Map<String, dynamic> map) => PrivateMessage(
    id: map['id'] ?? '',
    chatId: map['chatId'] ?? '',
    senderId: map['senderId'] ?? '',
    receiverId: map['receiverId'] ?? '',
    text: map['text'] ?? '',
    timestamp: DateTime.parse(map['timestamp']),
    type: map['type'],
  );
} 