import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/group_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/private_message.dart';
import '../../models/group_model.dart';
import '../../models/group_message.dart';
import 'private_chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    final firestore = FirebaseFirestore.instance;
    List<UserModel> results = [];
    // Search by email
    final emailSnap = await firestore.collection('users').where('email', isEqualTo: query).get();
    results.addAll(emailSnap.docs.map((d) => UserModel.fromMap(d.data())));
    // Search by username
    final usernameSnap = await firestore.collection('users').where('username', isEqualTo: query).get();
    for (var d in usernameSnap.docs) {
      final user = UserModel.fromMap(d.data());
      if (!results.any((u) => u.id == user.id)) {
        results.add(user);
      }
    }
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Future<void> _startChat(UserModel otherUser) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;
    final chatId = await GroupService().getOrCreatePrivateChatId(currentUser.uid, otherUser.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateChatScreen(chatId: chatId, otherUser: otherUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Private'),
            Tab(icon: Icon(Icons.groups), text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- Private Chats Tab ---
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by username or email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (_) => _searchUsers(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSearching ? null : _searchUsers,
                      child: _isSearching ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Search'),
                    ),
                  ],
                ),
              ),
              if (_searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      if (user.id == currentUser?.uid) return const SizedBox.shrink();
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(user.username),
                          subtitle: Text(user.email),
                          trailing: ElevatedButton(
                            onPressed: () => _startChat(user),
                            child: const Text('Start Chat'),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Recent Chats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: currentUser != null ? GroupService().getRecentPrivateChats(currentUser.uid) : null,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final chats = snapshot.data ?? [];
                      if (chats.isEmpty) {
                        return const Center(child: Text('No recent chats.'));
                      }
                      return ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final lastMsg = chat['lastMessage'] as PrivateMessage?;
                          final otherUserId = (chat['userIds'] as List).firstWhere((id) => id != currentUser?.uid, orElse: () => null);
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                            builder: (context, userSnap) {
                              if (!userSnap.hasData || !userSnap.data!.exists) {
                                return const SizedBox.shrink();
                              }
                              final user = UserModel.fromMap(userSnap.data!.data() as Map<String, dynamic>);
                              return ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.person)),
                                title: Text(user.username),
                                subtitle: lastMsg != null ? Text(lastMsg.text) : null,
                                onTap: () => _startChat(user),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          // --- Group Chats Tab ---
          _GroupChatsTab(),
        ],
      ),
    );
  }
}

class _GroupChatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Not logged in'));
    }
    return StreamBuilder<List<GroupModel>>(
      stream: GroupService().getUserGroups(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return const Center(child: Text('No groups found.'));
        }
        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.groups)),
                title: Text(group.name),
                subtitle: Text('Admin: ${group.adminId}'),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupChatScreen(group: group),
                      ),
                    );
                  },
                  child: const Text('Group Chat'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;
  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<GroupMessage>>(
              stream: GroupService().streamGroupMessages(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser?.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
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
                      final text = _msgController.text.trim();
                      if (text.isNotEmpty && currentUser != null) {
                        // Get user data to access username
                        final userData = await AuthService().getUserData(currentUser.uid);
                        if (userData != null) {
                          await GroupService().sendGroupMessage(
                            groupId: widget.group.id,
                            senderId: currentUser.uid,
                            senderName: userData.username,
                            text: text,
                          );
                          _msgController.clear();
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (_scrollController.hasClients) {
                              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                            }
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 