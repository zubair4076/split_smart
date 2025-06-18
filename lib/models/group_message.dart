class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String? type;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.type,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
  };

  factory GroupMessage.fromMap(Map<String, dynamic> map) => GroupMessage(
    id: map['id'] ?? '',
    groupId: map['groupId'] ?? '',
    senderId: map['senderId'] ?? '',
    senderName: map['senderName'] ?? '',
    text: map['text'] ?? '',
    timestamp: DateTime.parse(map['timestamp']),
    type: map['type'],
  );
} 