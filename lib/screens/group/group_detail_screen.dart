import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../services/group_service.dart';
import '../../services/auth_service.dart';
import 'group_expense_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/group_message.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late GroupModel _group;
  List<UserModel> _members = [];
  bool _isLoading = true;
  String? _error;
  final _inviteController = TextEditingController();
  final _chatController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _tabController = TabController(length: 2, vsync: this);
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inviteController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    if (mounted) setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final groupService = GroupService();
      final members = await groupService.getGroupMembers(_group.id);
      if (mounted) setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
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
      appBar: AppBar(
        title: Text(_group.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.receipt_long),
              child: Text(
                'Expenses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            Tab(
              icon: Icon(Icons.chat_bubble_outline),
              child: Text(
                'Chat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          indicatorWeight: 4,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              initialIndex: _tabController.index,
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Expenses Tab
                        SingleChildScrollView(
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
                        // Chat Tab
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(top: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 16.0, left: 16.0),
                                    child: Text('Group Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: StreamBuilder<List<GroupMessage>>(
                                      stream: GroupService().streamGroupMessages(_group.id),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        if (snapshot.hasError) {
                                          return const Center(child: Text('Error loading chat'));
                                        }
                                        final messages = snapshot.data ?? [];
                                        if (messages.isEmpty) {
                                          return const Center(child: Text('No messages yet.'));
                                        }
                                        return ListView.builder(
                                          itemCount: messages.length,
                                          itemBuilder: (context, index) {
                                            final msg = messages[index];
                                            final isMe = AuthService().currentUser?.uid == msg.senderId;
                                            // Find sender's username from _members
                                            final sender = _members.firstWhere(
                                              (m) => m.id == msg.senderId,
                                              orElse: () => UserModel(
                                                id: '',
                                                email: '',
                                                username: msg.senderName,
                                                groupIds: [],
                                                createdAt: DateTime.now(),
                                                lastLogin: DateTime.now(),
                                              ),
                                            );
                                            return Align(
                                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                              child: Container(
                                                margin: const EdgeInsets.symmetric(vertical: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: isMe ? Colors.blue[100] : Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      sender.username,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(msg.text),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _chatController,
                                            decoration: const InputDecoration(
                                              hintText: 'Type a message...',
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.send, color: Colors.blue),
                                          onPressed: () async {
                                            final text = _chatController.text.trim();
                                            if (text.isNotEmpty) {
                                              final user = AuthService().currentUser;
                                              if (user != null) {
                                                // Find username from _members
                                                final sender = _members.firstWhere(
                                                  (m) => m.id == user.uid,
                                                  orElse: () => UserModel(
                                                    id: '',
                                                    email: '',
                                                    username: user.email ?? 'User',
                                                    groupIds: [],
                                                    createdAt: DateTime.now(),
                                                    lastLogin: DateTime.now(),
                                                  ),
                                                );
                                                await GroupService().sendGroupMessage(
                                                  groupId: _group.id,
                                                  senderId: user.uid,
                                                  senderName: sender.username,
                                                  text: text,
                                                );
                                                _chatController.clear();
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 