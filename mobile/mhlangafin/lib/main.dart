import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'pages/register_page.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MhlangaFin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/transfer': (context) => const TransferPage(),
        '/digital-card': (context) => const DigitalCardPage(),
      },
    );
  }
}

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
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Successful'),
            content: const Text('Welcome back to MhlangaFin!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DashboardPage(token: token),
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                  Text('MhlangaFin', style: TextStyle(
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
                    Text('Welcome Back', style: TextStyle(
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
                          style: TextStyle(color: Colors.red, fontSize: 12),
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
                          style: TextStyle(color: Colors.red, fontSize: 12),
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
                              )),
                            ),
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
                          : Text('Sign In', style: TextStyle(
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
                          )),
                        ),
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
    );
  }
}

class DashboardPage extends StatefulWidget {
  final String? token;

  const DashboardPage({super.key, this.token});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Account> accounts = [];
  bool isLoading = true;
  String? error;
  bool isCreatingAccount = false;
  bool isTransferring = false;
  String? transferError;

  final TextEditingController accountNameController = TextEditingController();
  final TextEditingController initialBalanceController = TextEditingController();
  final TextEditingController transferAmountController = TextEditingController();
  
  final ApiService apiService = ApiService();
  String? token; // In real app, this would be stored securely

  @override
  void initState() {
    super.initState();
    // In real app, get token from secure storage
    token = widget.token ?? 'sample-token'; // Use passed token or placeholder
    fetchAccounts();
  }

  Future<void> fetchAccounts() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await apiService.getAccounts(token!);
      
      setState(() {
        accounts = (result as List).map((item) => Account(
          id: item['id'],
          accountName: item['accountName'],
          accountNumber: item['accountNumber'],
          balance: item['balance'].toDouble(),
          isMain: item['isMain'],
        )).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load accounts. Please check your connection.';
        isLoading = false;
      });
    }
  }

  Future<void> createAccount() async {
    if (accountNameController.text.isEmpty || 
        double.tryParse(initialBalanceController.text) == null) {
      setState(() {
        error = 'Please fill in all fields correctly';
      });
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Savings Pocket'),
        content: Text('Are you sure you want to create a new savings pocket with R ${initialBalanceController.text}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isCreatingAccount = true;
      error = null;
    });

    try {
      final result = await apiService.createAccount(
        token!,
        accountNameController.text,
        double.parse(initialBalanceController.text),
      );
      
      setState(() {
        accounts.add(Account(
          id: result['id'],
          accountName: result['accountName'],
          accountNumber: result['accountNumber'],
          balance: result['balance'].toDouble(),
          isMain: result['isMain'],
        ));
        accountNameController.clear();
        initialBalanceController.clear();
        isCreatingAccount = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Savings Pocket Created'),
          content: Text('Your new savings pocket "${result['accountName']}" has been created successfully!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        error = 'Failed to create account. Please try again.';
        isCreatingAccount = false;
      });
    }
  }

  Future<void> executeTransfer(int fromId, int toId, double amount) async {
    setState(() {
      isTransferring = true;
      transferError = null;
    });

    try {
      final result = await apiService.internalTransfer(
        token!,
        fromId,
        toId,
        amount,
      );
      
      setState(() {
        // Update account balances from API response
        final fromAccount = accounts.firstWhere((acc) => acc.id == fromId);
        final toAccount = accounts.firstWhere((acc) => acc.id == toId);
        
        fromAccount.balance = result['fromAccountBalance'].toDouble();
        toAccount.balance = result['toAccountBalance'].toDouble();
        isTransferring = false;
      });
    } catch (e) {
      setState(() {
        transferError = 'Transfer failed. Please try again.';
        isTransferring = false;
      });
    }
  }

  double getTotalBalance() {
    return accounts.fold(0.0, (sum, acc) => sum + acc.balance);
  }

  Account? get mainAccount => accounts.firstWhereOrNull((acc) => acc.isMain);
  List<Account> get subAccounts => accounts.where((acc) => !acc.isMain).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
            pinned: true,
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.account_balance, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MhlangaFin', style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                    )),
                    Text('Elite Private Banking', style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 1.5
                    )),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.grey),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Error Message
                  if (error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[100]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[700], size: 24),
                          const SizedBox(width: 12),
                          Text(error!, style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                            fontWeight: FontWeight.bold
                          )),
                        ],
                      ),
                    ),

                  // Total Balance Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text('Total Optimized Balance', style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2
                        )),
                        const SizedBox(height: 16),
                        Text('R ${getTotalBalance().toStringAsFixed(2)}', style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        )),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const TransferPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.send, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Pay Beneficiary', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DigitalCardPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.credit_card, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Manage Card', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Main Account
                  _buildAccountSection('Access Account', 'Primary Hub', mainAccount),

                  const SizedBox(height: 32),

                  // Savings Pockets
                  _buildSavingsSection(),

                  const SizedBox(height: 32),

                  // Create New Account Section
                  _buildCreateAccountSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(String title, String subtitle, Account? account) {
    if (account == null) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(subtitle, style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5
              )),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.accountName, style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                      )),
                      Text(account.accountNumber, style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 1.5
                      )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Available for Payments', style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 1.5
              )),
              const SizedBox(height: 8),
              Text('R ${account.balance.toStringAsFixed(2)}', style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black
              )),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text('View Activity', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _showTransferDialog(account),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text('Move Money', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey[200]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text('Statements', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Savings Pockets', style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black
                )),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Growth Enabled', style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                    letterSpacing: 1.5
                  )),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // Scroll to create account section
              },
              child: Row(
                children: [
                  Text('Open New Pocket', style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.bold
                  )),
                  Icon(Icons.add, size: 16, color: Colors.blue[600]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: subAccounts.length + 1,
          itemBuilder: (context, index) {
            if (index < subAccounts.length) {
              return _buildPocketCard(subAccounts[index]);
            } else {
              return _buildAddPocketCard();
            }
          },
        ),
      ],
    );
  }

  Widget _buildPocketCard(Account account) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(account.accountName.toUpperCase(), style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black
          )),
          const SizedBox(height: 8),
          Text('Savings Objective', style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1.5
          )),
          const Spacer(),
          Text('Balance', style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1.5
          )),
          const SizedBox(height: 4),
          Text('R ${account.balance.toStringAsFixed(2)}', style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showTransferDialog(account),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text('Move Funds', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.access_time, size: 20, color: Colors.grey[400]),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.picture_as_pdf, size: 20, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPocketCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(24),
        color: Colors.grey[50],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add, size: 32, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text('Add New Pocket', style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black
          )),
          Text('Goal-based savings', style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600]
          )),
        ],
      ),
    );
  }

  Widget _buildCreateAccountSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text('Open Savings Pocket', style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black
          )),
          const SizedBox(height: 8),
          Text('Grow your wealth with goal-based savings pockets.', style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold
          )),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account Name', style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 1.5
              )),
              const SizedBox(height: 8),
              TextField(
                controller: accountNameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Dream House Fund',
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
              const SizedBox(height: 16),
              Text('Initial Deposit', style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 1.5
              )),
              const SizedBox(height: 8),
              TextField(
                controller: initialBalanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: 'R ',
                  prefixStyle: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                  ),
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
              const SizedBox(height: 8),
              Text('Minimum deposit of R100.00 recommended', style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 1.5
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCreatingAccount ? null : createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isCreatingAccount 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Authorize Pocket', style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                      )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(Account fromAccount) {
    int? selectedToAccountId;
    double transferAmount = 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Internal Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Move Money Between Pockets'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: selectedToAccountId,
              onChanged: (value) => selectedToAccountId = value,
              items: accounts
                .where((acc) => acc.id != fromAccount.id)
                .map((acc) => DropdownMenuItem(
                  value: acc.id,
                  child: Text('${acc.accountName} (R ${acc.balance.toStringAsFixed(2)})'),
                ))
                .toList(),
              hint: Text('Select Destination'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: transferAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount to Move',
                prefixText: 'R ',
                border: OutlineInputBorder(),
              ),
            ),
            if (transferError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(transferError!, style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isTransferring ? null : () async {
              if (selectedToAccountId == null || transferAmountController.text.isEmpty) {
                setState(() {
                  transferError = 'Please fill in all fields';
                });
                return;
              }

              final amount = double.tryParse(transferAmountController.text) ?? 0.0;
              if (amount <= 0) {
                setState(() {
                  transferError = 'Amount must be greater than 0';
                });
                return;
              }

              await executeTransfer(fromAccount.id, selectedToAccountId!, amount);
              if (transferError == null) {
                Navigator.pop(context);
                transferAmountController.clear();
              }
            },
            child: isTransferring ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ) : Text('Authorize'),
          ),
        ],
      ),
    );
  }
}

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Pay Beneficiary', style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold
        )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transfer Money', style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black
            )),
            const SizedBox(height: 8),
            Text('Send money to any beneficiary', style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold
            )),

            const SizedBox(height: 32),

            // Transfer Form
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount', style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1.5
                  )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: 'R ',
                      prefixStyle: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text('Beneficiary Reference', style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1.5
                  )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: referenceController,
                    decoration: InputDecoration(
                      hintText: 'Optional reference',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () {},
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
                        : Text('Transfer Now', style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DigitalCardPage extends StatefulWidget {
  const DigitalCardPage({super.key});

  @override
  State<DigitalCardPage> createState() => _DigitalCardPageState();
}

class _DigitalCardPageState extends State<DigitalCardPage> {
  bool isCardActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Digital Card', style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold
        )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Card', style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black
            )),
            const SizedBox(height: 8),
            Text('Control your digital card settings', style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold
            )),

            const SizedBox(height: 32),

            // Digital Card
            Container(
              height: 200,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[800]!, Colors.blue[600]!],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MHLANGAFIN', style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2
                      )),
                      Icon(Icons.contactless, color: Colors.white, size: 32),
                    ],
                  ),
                  const Spacer(),
                  Text('• • • •   • • • •   • • • •   1234', style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4
                  )),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VALID THRU', style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1
                          )),
                          Text('12/25', style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          )),
                        ],
                      ),
                      Icon(Icons.credit_card, color: Colors.white.withOpacity(0.8), size: 32),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card Controls
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Card Controls', style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black
                  )),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Card Status', style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600]
                          )),
                          Text(isCardActive ? 'Active' : 'Inactive', style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCardActive ? Colors.green[600] : Colors.red[600]
                          )),
                        ],
                      ),
                      Switch(
                        value: isCardActive,
                        onChanged: (value) {
                          setState(() {
                            isCardActive = value;
                          });
                        },
                        activeColor: Colors.green[600],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Block Card', style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                      )),
                      IconButton(
                        icon: Icon(Icons.block, color: Colors.red[600]),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Account {
  final int id;
  final String accountName;
  final String accountNumber;
  double balance;
  final bool isMain;

  Account({
    required this.id,
    required this.accountName,
    required this.accountNumber,
    required this.balance,
    required this.isMain,
  });
}

extension IterableFirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}