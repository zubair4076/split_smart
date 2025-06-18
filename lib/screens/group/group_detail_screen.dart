import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../services/group_service.dart';
import '../../services/auth_service.dart';
import 'group_expense_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late GroupModel _group;
  List<UserModel> _members = [];
  bool _isLoading = true;
  String? _error;
  final _inviteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadMembers();
  }

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final groupService = GroupService();
      final members = await groupService.getGroupMembers(_group.id);
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _inviteMember() async {
    final value = _inviteController.text.trim();
    if (value.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final groupService = GroupService();
      final authService = AuthService();
      // Find user by username or email in current members
      UserModel? userToAdd;
      for (final member in _members) {
        if (member.email == value || member.username == value) {
          userToAdd = member;
          break;
        }
      }
      if (userToAdd == null) {
        // Try to find user in Firestore by email or username
        final firestore = FirebaseFirestore.instance;
        QuerySnapshot userQuery = await firestore
            .collection('users')
            .where('email', isEqualTo: value)
            .get();
        if (userQuery.docs.isEmpty) {
          userQuery = await firestore
              .collection('users')
              .where('username', isEqualTo: value)
              .get();
        }
        if (userQuery.docs.isNotEmpty) {
          userToAdd = UserModel.fromMap(userQuery.docs.first.data() as Map<String, dynamic>);
        } else {
          setState(() {
            _error = 'User not found or not registered.';
            _isLoading = false;
          });
          return;
        }
      }
      if (_group.memberIds.contains(userToAdd.id)) {
        setState(() {
          _error = 'User is already a member.';
          _isLoading = false;
        });
        return;
      }
      // Send invitation instead of adding directly
      final currentUser = authService.currentUser;
      await groupService.sendGroupInvitation(
        groupId: _group.id,
        groupName: _group.name,
        invitedUserId: userToAdd.id,
        invitedUserEmail: userToAdd.email,
        inviterUserId: currentUser!.uid,
        inviterUserName: currentUser.email ?? '',
      );
      _inviteController.clear();
      setState(() {
        _error = 'Invitation sent!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToExpenses() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupExpenseScreen(group: _group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_group.name)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        child: const Icon(Icons.verified_user, color: Colors.blue),
                      ),
                      title: const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_group.adminId),
                    ),
                  ),
                  const Text('Members:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._members.map((m) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          title: Text(m.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(m.email),
                        ),
                      )),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Invite Member',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _inviteController,
                                  decoration: const InputDecoration(
                                    labelText: 'Username or Email',
                                    prefixIcon: Icon(Icons.person_add_alt_1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _inviteMember,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Icon(Icons.send),
                              ),
                            ],
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(_error!, style: const TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _navigateToExpenses,
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('View Expenses'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 