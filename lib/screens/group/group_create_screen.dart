import 'package:flutter/material.dart';
import '../../services/group_service.dart';
import '../../services/auth_service.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _memberController = TextEditingController();
  final _initialAmountController = TextEditingController();
  final List<String> _members = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberController.dispose();
    _initialAmountController.dispose();
    super.dispose();
  }

  void _addMember() {
    final value = _memberController.text.trim();
    if (value.isNotEmpty && !_members.contains(value)) {
      setState(() {
        _members.add(value);
        _memberController.clear();
      });
    }
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        final authService = AuthService();
        final groupService = GroupService();
        final currentUser = authService.currentUser;
        if (currentUser == null) throw 'User not logged in';
        final initialAmount = double.tryParse(_initialAmountController.text.trim()) ?? 0.0;
        final group = await groupService.createGroup(
          name: _groupNameController.text.trim(),
          adminId: currentUser.uid,
          initialAmount: initialAmount,
        );
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          Navigator.pop(context, group);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialAmountController,
                decoration: const InputDecoration(
                  labelText: 'Initial Amount (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _memberController,
                decoration: InputDecoration(
                  labelText: 'Add Member (username or email)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addMember,
                  ),
                ),
                onFieldSubmitted: (_) => _addMember(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _members
                    .map((m) => Chip(
                          label: Text(m),
                          onDeleted: () {
                            setState(() {
                              _members.remove(m);
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 