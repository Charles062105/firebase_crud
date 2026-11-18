import 'package:firebase_crud/register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authService = AuthService();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool loading = false;

  // Added below the existing login state for the password reset dialog.
  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailCtrl.text);
    var resetLoading = false;
    var resetSent = false;
    String? message;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Reset password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              if (message != null) ...[
                SizedBox(height: 12),
                Text(
                  message!,
                  style: TextStyle(
                    color: resetSent
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  resetLoading ? null : () => Navigator.pop(dialogContext),
              child: Text(resetSent ? 'Done' : 'Cancel'),
            ),
            if (!resetSent)
              ElevatedButton(
                onPressed: resetLoading
                    ? null
                    : () async {
                        final email = emailController.text.trim();
                        if (email.isEmpty) {
                          setDialogState(() {
                            message = 'Please enter your email address.';
                          });
                          return;
                        }
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(email)) {
                          setDialogState(() {
                            message = 'Please enter a valid email address.';
                          });
                          return;
                        }

                        setDialogState(() {
                          resetLoading = true;
                          message = null;
                        });
                        try {
                          await authService.sendPasswordResetEmail(email);
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            resetLoading = false;
                            resetSent = true;
                            message = 'Check your email for a password reset link.';
                          });
                        } on FirebaseAuthException catch (error) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            resetLoading = false;
                            message = _passwordResetError(error.code);
                          });
                        } catch (_) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            resetLoading = false;
                            message =
                                'Unable to send the reset email. Please try again.';
                          });
                        }
                      },
                child: resetLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Send reset email'),
              ),
          ],
        ),
      ),
    );
    emailController.dispose();
  }

  // Added: Firebase reset errors shown in the reset dialog.
  String _passwordResetError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account was found for this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many requests. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Unable to send the reset email. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              // Added below the password field.
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: loading ? null : _showForgotPasswordDialog,
                  child: Text('Forgot your password?'),
                ),
              ),
              ElevatedButton(
                child: loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Login'),
                onPressed: () async {
                  if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;

                  setState(() => loading = true);

                  final user = await authService.signInWithEmail(
                    _emailCtrl.text,
                    _passwordCtrl.text,
                  );

                  if (!mounted) return;
                  setState(() => loading = false);

                  if (user != null && user.emailVerified) {
                    // Login successful
                    Navigator.pushReplacementNamed(context, '/home');
                  } else if (user != null) {
                    await authService.signOut();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please verify your email before logging in.')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed. Check your email and password.')),
                    );
                  }
                },
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Divider()
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR'),
                  ),
                  Expanded(
                    child: Divider()
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.login),
                label: Text('Sign in with Google'),
                onPressed: () async {
                  setState(() => loading = true);
                  final user = await authService.signInWithGoogle();
                  if (!mounted) return;
                  setState(() => loading = false);
                  if (user != null) {
                    // Login successful
                    Navigator.pushReplacementNamed(context, '/home');
                  } 
                },
              ),
              SizedBox(height: 12),
              TextButton(
                child: Text('Don\'t have an account? Register'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
