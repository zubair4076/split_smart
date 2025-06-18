import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/group_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/private_message.dart';
import 'private_chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

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
      appBar: AppBar(title: const Text('Chats')),
      body: Column(
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
    );
  }
} 