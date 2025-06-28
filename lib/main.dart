import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/group/group_list_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/chats/chats_screen.dart';
import 'services/auth_service.dart';
// import 'services/notification_service.dart';

class ThemeModeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeModeNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 5500), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Modern color scheme with gradients
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1), // Indigo primary
      brightness: Brightness.light,
      primary: const Color(0xFF6366F1),
      secondary: const Color(0xFF8B5CF6),
      tertiary: const Color(0xFF06B6D4),
      surface: const Color(0xFFFAFAFA),
    );
    
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.dark,
      primary: const Color(0xFF818CF8),
      secondary: const Color(0xFFA78BFA),
      tertiary: const Color(0xFF22D3EE),
      surface: const Color(0xFF1F2937),
    );
    
    final themeMode = Provider.of<ThemeModeNotifier>(context).themeMode;
    
    return MaterialApp(
      title: 'SplitSmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        fontFamily: GoogleFonts.inter().fontFamily,
        
        // Enhanced AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
          iconTheme: IconThemeData(color: colorScheme.onSurface),
          actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
        ),
        
        // Enhanced Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
        
        // Enhanced Button Themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
            elevation: 0,
          ),
        ),
        
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary, width: 2),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          ),
        ),
        
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
        
        // Enhanced FAB Theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
        ),
        
        // Enhanced Card Theme
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: colorScheme.surface,
        ),
        
        // Enhanced SnackBar Theme
        snackBarTheme: SnackBarThemeData(
          backgroundColor: colorScheme.primary,
          contentTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        
        // Enhanced Bottom Navigation Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: colorScheme.surface,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        
        // Enhanced Divider Theme
        dividerTheme: DividerThemeData(
          color: colorScheme.outline.withValues(alpha: 0.2),
          thickness: 1,
          space: 1,
        ),
      ),
      
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
        fontFamily: GoogleFonts.inter().fontFamily,
        
        // Enhanced AppBar Theme for Dark
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: darkColorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
          iconTheme: IconThemeData(color: darkColorScheme.onSurface),
          actionsIconTheme: IconThemeData(color: darkColorScheme.onSurface),
        ),
        
        // Enhanced Input Decoration Theme for Dark
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkColorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: darkColorScheme.outline.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: darkColorScheme.outline.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: darkColorScheme.error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(color: darkColorScheme.onSurface.withValues(alpha: 0.7)),
          hintStyle: TextStyle(color: darkColorScheme.onSurface.withValues(alpha: 0.5)),
        ),
        
        // Enhanced Button Themes for Dark
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkColorScheme.primary,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
            elevation: 0,
          ),
        ),
        
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkColorScheme.primary,
            side: BorderSide(color: darkColorScheme.primary, width: 2),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          ),
        ),
        
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: darkColorScheme.primary,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
        
        // Enhanced FAB Theme for Dark
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
        ),
        
        // Enhanced Card Theme for Dark
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: darkColorScheme.surface,
        ),
        
        // Enhanced SnackBar Theme for Dark
        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkColorScheme.primary,
          contentTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        
        // Enhanced Bottom Navigation Bar Theme for Dark
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: darkColorScheme.surface,
          selectedItemColor: darkColorScheme.primary,
          unselectedItemColor: darkColorScheme.onSurface.withValues(alpha: 0.6),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        
        // Enhanced Divider Theme for Dark
        dividerTheme: DividerThemeData(
          color: darkColorScheme.outline.withValues(alpha: 0.2),
          thickness: 1,
          space: 1,
        ),
      ),
      
      themeMode: themeMode,
      home: _showSplash
          ? const SplashScreen()
          : StreamBuilder<User?>(
              stream: AuthService().authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return const MainNavShell();
                } else {
                  return const LoginScreen();
                }
              },
            ),
    );
  }
}

class CrudScreen extends StatefulWidget {
  const CrudScreen({super.key});

  @override
  State<CrudScreen> createState() => _CrudScreenState();
}

class _CrudScreenState extends State<CrudScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _textController = TextEditingController();

  // Create
  void _addItem() {
    if (_textController.text.isNotEmpty) {
      _firestore.collection('items').add({
        'text': _textController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _textController.clear();
    }
  }

  // Update
  void _updateItem(String docId, String currentText) {
    _textController.text = currentText;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(controller: _textController),
        actions: [
          TextButton(
            onPressed: () {
              _firestore.collection('items').doc(docId).update({
                'text': _textController.text,
                'timestamp': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              _textController.clear();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Delete
  void _deleteItem(String docId) {
    _firestore.collection('items').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Firestore CRUD')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(controller: _textController),
              ),
              ElevatedButton(
                onPressed: _addItem,
                child: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('items')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No items yet'));
              }

                return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                    title: Text(data['text'] ?? ''),
                    subtitle: Text(
                      data['timestamp'] != null
                          ? 'Added: ${(data['timestamp'] as Timestamp).toDate()}'
                          : 'No timestamp',
                    ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _updateItem(doc.id, data['text'] ?? ''),
                          ),
                          IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteItem(doc.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
            },
          ),
        ),
      ],
    ),
    );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    GroupListScreen(),
    ChatsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_rounded),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
