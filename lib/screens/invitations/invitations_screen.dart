import 'package:flutter/material.dart';
import '../../models/invitation_model.dart';
import '../../services/group_service.dart';
import '../../services/auth_service.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: StreamBuilder<List<InvitationModel>>(
        stream: _groupService.getUserInvitations(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading invitations'));
          }
          final invitations = snapshot.data ?? [];
          if (invitations.isEmpty) {
            return const Center(child: Text('No pending invitations.'));
          }
          return ListView.builder(
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.mail_outline, color: Colors.blue),
                  title: Text('Group: ${invitation.groupName}'),
                  subtitle: Text('Invited by: ${invitation.inviterUserName}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Accept',
                        onPressed: () async {
                          await _groupService.addMemberToGroup(invitation.groupId, user.uid);
                          await _groupService.updateInvitationStatus(invitation.id, 'accepted');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () async {
                          await _groupService.updateInvitationStatus(invitation.id, 'rejected');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 