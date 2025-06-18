import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = false;
  bool _isVerified = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        setState(() {
          _isVerified = true;
          _message = 'Your email is verified! You can now use the app.';
        });
        // Optionally, navigate to home or login
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        setState(() {
          _isVerified = false;
          _message = 'A verification link has been sent to your email. Please verify your email to continue.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error checking verification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      setState(() {
        _message = 'Verification email resent! Please check your inbox.';
      });
    } catch (e) {
      setState(() {
        _message = 'Error resending verification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isVerified ? Icons.verified : Icons.email,
                color: _isVerified ? Colors.green : Colors.blue,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                _isVerified
                    ? 'Email Verified!'
                    : 'Verify Your Email',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_message != null)
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 32),
              if (!_isVerified)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _checkVerification,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('I have verified my email'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading ? null : _resendVerification,
                      child: const Text('Resend Verification Email'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
} 