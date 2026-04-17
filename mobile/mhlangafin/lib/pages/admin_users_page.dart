import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/api_service.dart';
import '../utils/jwt_helper.dart';

class AdminUsersPage extends StatefulWidget {
  final String? token;

  const AdminUsersPage({super.key, this.token});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<dynamic> users = [];
  bool isLoading = true;
  String? error;
  bool showUserModal = false;
  dynamic selectedUser;

  final ApiService apiService = ApiService();
  String? token;

  @override
  void initState() {
    super.initState();
    token = widget.token;
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    if (token == null) return;
    
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await apiService.getAdminUsers(token!);
      
      setState(() {
        users = (result as List).cast<dynamic>();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching users: $e');
      setState(() {
        error = 'Failed to load users. Please check your connection.';
        isLoading = false;
      });
    }
  }

  Future<void> toggleUserStatus(dynamic user) async {
    if (token == null) return;
    
    final newStatus = user['status'] == 'Active' ? 'Blocked' : 'Active';
    
    setState(() {
      error = null;
    });

    try {
      await apiService.updateUserStatus(token!, user['id'], newStatus);
      
      // Update local state
      final index = users.indexWhere((u) => u['id'] == user['id']);
      if (index != -1) {
        users[index]['status'] = newStatus;
        setState(() {});
      }
    } catch (e) {
      setState(() {
        error = 'Failed to update user status.';
      });
    }
  }

  Future<void> resetUserPassword(dynamic user) async {
    if (token == null) return;
    
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new password'),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (newPassword != null && newPassword.isNotEmpty) {
      try {
        await apiService.resetUserPassword(token!, user['id'], newPassword);
      } catch (e) {
        setState(() {
          error = 'Failed to reset password.';
        });
      }
    }
  }

  Future<void> toggleAccountStatus(dynamic user, dynamic account) async {
    if (token == null) return;
    
    final newStatus = account['status'] == 'Active' ? 'Frozen' : 'Active';
    
    setState(() {
      error = null;
    });

    try {
      await apiService.updateAccountStatus(token!, account['id'], newStatus);
      
      // Update local state
      setState(() {
        account['status'] = newStatus;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account ${account['accountNumber']} is now $newStatus')),
        );
      }
    } catch (e) {
      setState(() {
        error = 'Failed to update account status.';
      });
    }
  }

  void logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                floating: true,
                pinned: true,
                centerTitle: false,
                title: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.people, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('User Management', style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                        )),
                        Text('Manage customers & security', style: TextStyle(
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
                    onPressed: fetchUsers,
                    icon: const Icon(Icons.refresh, color: Colors.black),
                  ),
                  IconButton(
                    onPressed: logout,
                    icon: const Icon(Icons.logout, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              if (isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.black)),
                )
              else if (error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: fetchUsers,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Overview
                        _buildStatsCards(),

                        const SizedBox(height: 40),

                        // Users List Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Customer Directory', style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black
                            )),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${users.length} Users', style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600]
                              )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Users List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: users.length,
                          itemBuilder: (context, index) => _buildUserCard(users[index]),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
  }

  Widget _buildStatsCards() {
    final totalUsers = users.length;
    final activeUsers = users.where((u) => u['status'] == 'Active').length;
    final blockedUsers = users.where((u) => u['status'] == 'Blocked').length;
    final totalAccounts = users.fold<int>(0, (sum, u) => sum + (u['accounts']?.length as int? ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatCard('Total Users', totalUsers.toString(), Colors.black, Icons.people),
            const SizedBox(width: 12),
            _buildStatCard('Active', activeUsers.toString(), Colors.green, Icons.check_circle),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('Blocked', blockedUsers.toString(), Colors.red, Icons.block),
            const SizedBox(width: 12),
            _buildStatCard('Accounts', totalAccounts.toString(), Colors.blue, Icons.account_balance_wallet),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black
                )),
                Text(title, style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final initials = '${user['firstName'][0]}${user['lastName'][0]}';
    final isActive = user['status'] == 'Active';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${user['firstName']} ${user['lastName']}', style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                      )),
                      Text(user['email'], style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600]
                      )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user['status'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isActive ? Colors.green[700] : Colors.red[700],
                      letterSpacing: 1
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Accounts Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BANK ACCOUNTS', style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[400],
                      letterSpacing: 1.5
                    )),
                    Text('${user['accounts']?.length ?? 0} total', style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400]
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                ...((user['accounts'] as List?)?.map((account) => _buildAccountListTile(user, account)) ?? []),
                
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => toggleUserStatus(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? Colors.red[50]! : Colors.green[50]!,
                          foregroundColor: isActive ? Colors.red[700]! : Colors.green[700]!,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(isActive ? 'Block Access' : 'Restore Access', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => resetUserPassword(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Reset Pass', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountListTile(dynamic user, dynamic account) {
    final bool isFrozen = account['status'] == 'Frozen';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isFrozen ? Colors.red[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isFrozen ? Icons.ac_unit : Icons.account_balance_wallet,
              color: isFrozen ? Colors.red[700] : Colors.blue[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account['accountName'], style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black
                )),
                Text(account['accountNumber'], style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500]
                )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => toggleAccountStatus(user, account),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isFrozen ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isFrozen ? Colors.black : Colors.grey[300]!),
              ),
              child: Text(
                isFrozen ? 'UNFREEZE' : 'FREEZE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: isFrozen ? Colors.white : Colors.black,
                  letterSpacing: 0.5
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
