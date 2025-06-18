import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../group/group_create_screen.dart';
import '../group/group_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  UserModel? _user;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isEditing = false;
  List<GroupModel> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getUserData(_authService.currentUser!.uid);
      if (mounted) {
        setState(() {
          _user = user;
          _usernameController.text = user?.username ?? '';
        });
      }
      await _loadGroups();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _loadGroups() async {
    if (_user == null) return;
    final groupService = GroupService();
    final groups = await groupService.getUserGroups(_user!.id).first;
    setState(() {
      _groups = groups;
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.updateUserProfile(
          _authService.currentUser!.uid,
          {'username': _usernameController.text.trim()},
        );
        await _loadUserData();
        if (mounted) {
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _navigateToCreateGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GroupCreateScreen()),
    );
    if (result != null) {
      await _loadGroups();
    }
  }

  void _navigateToGroupDetail(GroupModel group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupDetailScreen(group: group)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.person, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _user?.username ?? 'Not set',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _user?.email ?? 'Not set',
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _user?.createdAt != null
                              ? 'Member since: ${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}'
                              : 'Not available',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isEditing) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _updateProfile,
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text('Save'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _usernameController.text = _user?.username ?? '';
                                  });
                                },
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Groups',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _navigateToCreateGroup,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Group'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_groups.isEmpty)
                const Text('You are not a member of any groups yet.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          child: const Icon(Icons.group, color: Colors.blue),
                        ),
                        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Admin: ${group.adminId}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () => _navigateToGroupDetail(group),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
} 