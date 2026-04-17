import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../utils/jwt_helper.dart';
import 'dashboard_page.dart';
import 'admin_main_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? error;
  final ApiService apiService = ApiService();

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  Future<void> login() async {
    // Validate fields
    if (validateEmail(emailController.text) != null ||
        validatePassword(passwordController.text) != null) {
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await apiService.login(
        emailController.text,
        passwordController.text,
      );

      // Extract token from response
      final token = result['token'] ?? result['accessToken'];
      
      if (token != null) {
        // Check if user is admin by checking the response role OR decoding JWT
        bool isAdmin = (result['role']?.toString().toLowerCase() == 'admin' || 
                        result['Role']?.toString().toLowerCase() == 'admin');
        
        if (!isAdmin) {
          try {
            final decodedToken = JwtHelper.decode(token);
            final role = (decodedToken['role'] ?? 
                        decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
                        decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/role'])?.toString().toLowerCase();
            isAdmin = (role == 'admin');
          } catch (e) {
            debugPrint('Error decoding token for role check: $e');
          }
        }
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Successful'),
            content: Text(isAdmin ? 'Welcome back, Admin!' : 'Welcome back to MhlangaFin!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => isAdmin 
                        ? AdminMainPage(token: token) 
                        : DashboardPage(token: token),
                    ),
                  );
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Invalid login response');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Failed'),
          content: Text(e.toString().contains('Login failed')
              ? 'Login failed. Please check your credentials.'
              : 'An error occurred. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Brand
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.account_balance, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text('MhlangaFin', style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                    )),
                    Text('Elite Private Banking', style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 2
                    )),
                  ],
                ),

                const SizedBox(height: 48),

                // Login Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome Back', style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                      )),
                      const SizedBox(height: 8),
                      Text('Please sign in to your account', style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold
                      )),

                      const SizedBox(height: 24),

                      // Email Field
                      Text('Email Address', style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 1.5
                      )),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                      ),
                      if (validateEmail(emailController.text) != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            validateEmail(emailController.text)!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Password Field
                      Text('Password', style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 1.5
                      )),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                      ),
                      if (validatePassword(passwordController.text) != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            validatePassword(passwordController.text)!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Error Message
                      if (error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[100]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red[700], size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(error!, style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold
                                ))),
                            ],
                          ),
                        ),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Sign In', style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold
                              )),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Don\'t have an account?', style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold
                          )),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: Text('Sign Up', style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.bold
                            ))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Footer
                Text('By signing in, you agree to our Terms of Service', style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                  letterSpacing: 1.5
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
