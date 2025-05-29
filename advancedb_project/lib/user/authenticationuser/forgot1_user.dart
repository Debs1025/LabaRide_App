import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../loginscreen.dart';
import 'forgot5_user.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isValidEmail = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _isValidEmail = value.isNotEmpty && 
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
    });
  }

  Future<void> _resetPassword() async {
  if (_passwordController.text != _confirmPasswordController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passwords do not match')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final response = await http.post(
      Uri.parse('https://backend-production-5974.up.railway.app/reset_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text,
        'new_password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      if (!mounted) return;

      // Navigate to password changed loading screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PasswordChangedComplete(),
        ),
      );
    } else {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${jsonDecode(response.body)['message']}')),
      );
    }
  } catch (e) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
                ),
                child: Image.asset('assets/blacklogo.png', height: 40),
              ),
              const SizedBox(height: 32),
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A0066),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email and new password',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Email',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                onChanged: _validateEmail,
                decoration: InputDecoration(
                  hintText: 'example@gmail.com',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Text(
                'New Password',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[400],
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm Password',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[400],
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isValidEmail && 
                           _passwordController.text.isNotEmpty && 
                           _confirmPasswordController.text.isNotEmpty && 
                           !_isLoading
                      ? _resetPassword
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValidEmail ? const Color(0xFF375DFB) : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Reset Password',
                          style: TextStyle(
                            color: _isValidEmail ? Colors.white : Colors.grey[500],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
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
}