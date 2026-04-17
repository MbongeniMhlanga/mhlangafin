import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/api_service.dart';
import '../utils/jwt_helper.dart';
import 'admin_users_page.dart';
import 'admin_transactions_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final String? token;
  final Function(int)? onTabChange;

  const AdminDashboardPage({super.key, this.token, this.onTabChange});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? stats;
  bool isLoading = true;
  String? error;

  final ApiService apiService = ApiService();
  String? token;

  @override
  void initState() {
    super.initState();
    token = widget.token;
    fetchStats();
  }

  Future<void> fetchStats() async {
    if (token == null) return;
    
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await apiService.getAdminStats(token!);
      
      setState(() {
        stats = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      setState(() {
        error = 'Failed to load statistics. Please check your connection.';
        isLoading = false;
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
                      child: const Icon(Icons.account_balance, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MhlangaFin Admin', style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                        )),
                        Text('System Overview', style: TextStyle(
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
                    onPressed: fetchStats,
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
                          onPressed: fetchStats,
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
                        Text('Bank-wide Statistics', style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                        )),
                        const SizedBox(height: 8),
                        Text('Real-time system health and user metrics', style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500
                        )),
                        
                        const SizedBox(height: 32),

                        // Stats Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          children: [
                            _buildStatCard('Total Users', stats?['totalUsers']?.toString() ?? '0', Colors.black, Icons.people),
                            _buildStatCard('Active Users', stats?['activeUsers']?.toString() ?? '0', Colors.green, Icons.check_circle),
                            _buildStatCard('Total Accounts', stats?['totalAccounts']?.toString() ?? '0', Colors.blue, Icons.account_balance_wallet),
                            _buildStatCard('Pending Tx', stats?['pendingTransactions']?.toString() ?? '0', Colors.amber, Icons.pending_actions),
                            _buildStatCard('Frozen Accounts', stats?['frozenAccounts']?.toString() ?? '0', Colors.red, Icons.block),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Admin Actions
                        Text('Management Tools', style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                        )),
                        const SizedBox(height: 24),
                        _buildAdminActionCard(
                          Icons.group, 
                          'User Management', 
                          'Update banking permissions',
                          Colors.black,
                          () {
                            if (widget.onTabChange != null) {
                              widget.onTabChange!(1);
                            }
                          }
                        ),
                        const SizedBox(height: 16),
                        _buildAdminActionCard(
                          Icons.swap_horiz, 
                          'Transaction Review', 
                          'Approve or reject pending transfers',
                          Colors.amber,
                          () {
                            if (widget.onTabChange != null) {
                              widget.onTabChange!(2);
                            }
                          }
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

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black
              )),
              Text(title, style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 0.5
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black
                  )),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500]
                  )),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
