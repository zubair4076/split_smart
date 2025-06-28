import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../group/group_create_screen.dart';
import '../group/group_detail_screen.dart';
import '../invitations/invitations_screen.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final _authService = AuthService();
  bool _isLoading = true;
  UserModel? _user;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isEditing = false;
  List<GroupModel> _groups = [];
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _newPhotoUrl;
  XFile? _pickedImage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle any errors that occurred during initialization
    if (_errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      _errorMessage = null;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
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
        setState(() {
          _errorMessage = e.toString();
        });
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_images').child('${_user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(await image.readAsBytes());
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String? photoUrl = _user?.photoUrl;
        if (_pickedImage != null) {
          final uploaded = await _uploadImage(_pickedImage!);
          if (uploaded != null) photoUrl = uploaded;
        }
        await _authService.updateUserProfile(
          _authService.currentUser!.uid,
          {
            'username': _usernameController.text.trim(),
            'photoUrl': photoUrl,
          },
        );
        await _loadUserData();
        if (mounted) {
          setState(() {
            _isEditing = false;
            _pickedImage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: GoogleFonts.inter(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient AppBar
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                      colorScheme.tertiary,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Row(
                            children: [
                              if (!_isEditing)
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  onPressed: () => setState(() => _isEditing = true),
                                ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                onPressed: _signOut,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Profile Avatar
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: _pickedImage != null
                                ? FileImage(File(_pickedImage!.path))
                                : (_user?.photoUrl != null && _user!.photoUrl!.isNotEmpty)
                                    ? NetworkImage(_user!.photoUrl!) as ImageProvider
                                    : null,
                            child: (_pickedImage == null && (_user?.photoUrl == null || _user!.photoUrl!.isEmpty))
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: colorScheme.primary,
                                  )
                                : null,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showImageSourceActionSheet,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.edit, size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _user?.username ?? 'Not set',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.email ?? 'Not set',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Animated Content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Member Since Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withOpacity(0.1),
                                colorScheme.secondary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  color: colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Member Since',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: colorScheme.onSurface.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _user?.createdAt != null
                                          ? '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}'
                                          : 'Not available',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Edit Profile Section
                        if (_isEditing) ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Profile',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      labelText: 'Username',
                                      hintText: 'Enter your username',
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.person_outline,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
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
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _updateProfile,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Text(
                                                  'Save',
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
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
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          child: Text(
                                            'Cancel',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
                        // Theme Settings
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.palette_rounded,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Theme Mode',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Builder(
                                builder: (context) {
                                  final themeNotifier = context.watch<ThemeModeNotifier>();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: colorScheme.outline.withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<ThemeMode>(
                                        value: themeNotifier.themeMode,
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(
                                            value: ThemeMode.system,
                                            child: Text('System Default'),
                                          ),
                                          DropdownMenuItem(
                                            value: ThemeMode.light,
                                            child: Text('Light'),
                                          ),
                                          DropdownMenuItem(
                                            value: ThemeMode.dark,
                                            child: Text('Dark'),
                                          ),
                                        ],
                                        onChanged: (mode) {
                                          if (mode != null) {
                                            themeNotifier.setThemeMode(mode);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Groups Section
                        Text(
                          'Your Groups',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Groups List
                        if (_groups.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.group_outlined,
                                    color: colorScheme.primary,
                                    size: 48,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Groups Yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You are not a member of any groups yet.',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ...List.generate(_groups.length, (index) {
                            final group = _groups[index];
                            return _buildGroupCard(group, colorScheme, index);
                          }),
                        SizedBox(height: mediaQuery.viewPadding.bottom + 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group, ColorScheme colorScheme, int index) {
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primary.withOpacity(0.8),
    ];
    final color = colors[index % colors.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToGroupDetail(group),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.group_rounded,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Admin: ${group.adminId}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 