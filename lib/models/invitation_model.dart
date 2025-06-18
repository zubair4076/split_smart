// Invitation model for group invitations
class InvitationModel {
  final String id;
  final String groupId;
  final String groupName;
  final String invitedUserId;
  final String invitedUserEmail;
  final String inviterUserId;
  final String inviterUserName;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  InvitationModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.invitedUserId,
    required this.invitedUserEmail,
    required this.inviterUserId,
    required this.inviterUserName,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'groupName': groupName,
      'invitedUserId': invitedUserId,
      'invitedUserEmail': invitedUserEmail,
      'inviterUserId': inviterUserId,
      'inviterUserName': inviterUserName,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InvitationModel.fromMap(Map<String, dynamic> map) {
    return InvitationModel(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      invitedUserId: map['invitedUserId'] ?? '',
      invitedUserEmail: map['invitedUserEmail'] ?? '',
      inviterUserId: map['inviterUserId'] ?? '',
      inviterUserName: map['inviterUserName'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
} 