import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }
    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        _showSnack('Account created! Please sign in.');
        if (mounted) Navigator.pop(context);
      } else {
        final error = jsonDecode(res.body);
        _showSnack(error['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      _showSnack('Cannot reach server');
    }
    setState(() => _loading = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              const Text('Create account', style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black,
              )),
              const SizedBox(height: 8),
              Text('Start managing your life with AILA', style: TextStyle(
                color: Colors.black.withOpacity(0.4), fontSize: 16,
              )),
              const SizedBox(height: 48),

              _Label('Full Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration('Enter your name', Icons.badge_outlined),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),

              _Label('Username'),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration('Choose a username', Icons.person_outline),
              ),
              const SizedBox(height: 20),

              _Label('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration('Min 6 characters', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.black38, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account', style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
      prefixIcon: Icon(icon, color: Colors.black38, size: 20),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black38),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(
      color: Colors.black.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600,
    ));
  }
}