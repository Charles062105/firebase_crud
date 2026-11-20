import 'package:firebase_crud/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _showAuthMessage(String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _registrationErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'The password does not meet Firebase password requirements.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase Console.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Registration failed ($code). Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Register'),
                onPressed: () async {
                  if (_emailController.text.trim().isEmpty ||
                      _passwordController.text.isEmpty) {
                    await _showAuthMessage('Enter your email and password.');
                    return;
                  }

                  setState(() => _isLoading = true);
                  var accountCreated = false;
                  try {
                    final user = await _authService.registerWithEmail(
                      _emailController.text,
                      _passwordController.text,
                    );

                    if (user == null) {
                      await _showAuthMessage('Registration could not be completed.');
                      return;
                    }

                    accountCreated = true;
                    if (!user.emailVerified) {
                      await user.sendEmailVerification();
                      if (!context.mounted) return;
                      await _showAuthMessage(
                        'Verification email sent. Please check your inbox.',
                      );
                    }

                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginPage()),
                    );
                  } on FirebaseAuthException catch (error) {
                    if (context.mounted) {
                      final message = _registrationErrorMessage(error.code);
                      await _showAuthMessage(
                        accountCreated
                            ? 'Your account was created, but its verification email could not be sent. $message'
                            : message,
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      await _showAuthMessage(
                        accountCreated
                            ? 'Your account was created, but its verification email could not be sent.'
                            : 'Registration failed. Please try again.',
                      );
                    }
                  } finally {
                    if (context.mounted) setState(() => _isLoading = false);
                  }
                },
              ),
              SizedBox(height: 12),
              TextButton(
                child: Text('Already have an account? Login'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
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
