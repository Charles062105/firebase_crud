import 'package:firebase_crud/login_page.dart';
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
                  if (_emailController.text.isEmpty ||
                      _passwordController.text.isEmpty) {
                    return;
                  }

                  setState(() => _isLoading = true);

                  final user = await _authService.registerWithEmail(
                    _emailController.text,
                    _passwordController.text,
                  );

                  if (!context.mounted) return;
                  setState(() => _isLoading = false);

                  if (user != null) {
                    // Registration successful
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
                  } else {
                    await _showAuthMessage('Registration failed.');
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
