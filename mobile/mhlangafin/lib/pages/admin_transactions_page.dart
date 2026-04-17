import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/api_service.dart';
import '../utils/jwt_helper.dart';

class AdminTransactionsPage extends StatefulWidget {
  final String? token;

  const AdminTransactionsPage({super.key, this.token});

  @override
  State<AdminTransactionsPage> createState() => _AdminTransactionsPageState();
}

class _AdminTransactionsPageState extends State<AdminTransactionsPage> {
  List<dynamic> transactions = [];
  List<dynamic> pendingTransactions = [];
  bool isLoading = true;
  String? error;
  String selectedFilter = 'All';
  int currentPage = 1;
  int totalPages = 1;

  final ApiService apiService = ApiService();
  String? token;

  @override
  void initState() {
    super.initState();
    token = widget.token;
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    if (token == null) return;
    
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await apiService.getAdminTransactions(token!, 1, 100, selectedFilter);
      
      setState(() {
        transactions = (result as List).cast<dynamic>();
        totalPages = 1;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      setState(() {
        error = 'Failed to load transactions. Please check your connection.';
        isLoading = false;
      });
    }
  }

  Future<void> approveTransaction(dynamic transaction) async {
    if (token == null) return;
    
    final note = await _showNoteDialog('Approve Transaction', 'Optional approval note:');
    
    setState(() {
      error = null;
    });

    try {
      // Assuming apiService.approveTransaction now takes an optional note
      // I'll check api_service.dart and update it if needed.
      // Wait, let me check api_service.dart approveTransaction signature.
      await apiService.approveTransaction(token!, transaction['id'], note: note);
      
      // Update local state
      setState(() {
        transaction['status'] = 'Approved';
        transaction['reviewNote'] = note;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction approved successfully')),
        );
      }
    } catch (e) {
      setState(() {
        error = 'Failed to approve transaction.';
      });
    }
  }

  Future<void> rejectTransaction(dynamic transaction) async {
    if (token == null) return;
    
    final note = await _showNoteDialog('Reject Transaction', 'Reason for rejection:');
    
    setState(() {
      error = null;
    });

    try {
      await apiService.rejectTransaction(token!, transaction['id'], note: note);
      
      // Update local state
      setState(() {
        transaction['status'] = 'Rejected';
        transaction['reviewNote'] = note;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction rejected')),
        );
      }
    } catch (e) {
      setState(() {
        error = 'Failed to reject transaction.';
      });
    }
  }

  Future<String?> _showNoteDialog(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
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
                      child: const Icon(Icons.swap_horiz, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transaction Review', style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                        )),
                        Text('Approve or reject transfers', style: TextStyle(
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
                    onPressed: fetchTransactions,
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
                          onPressed: fetchTransactions,
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

                        const SizedBox(height: 32),

                        // Filter Section
                        _buildFilterChips(),

                        const SizedBox(height: 32),

                        // Transactions List Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Review Queue', style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black
                            )),
                            Text('Page $currentPage of $totalPages', style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500]
                            )),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Transactions List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) => _buildTransactionCard(transactions[index]),
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
    // These stats are usually for the whole system, but here we show current page stats
    // In a real app, the API would return total stats.
    final totalTx = transactions.length;
    final pendingTx = transactions.where((t) => t['status'] == 'PendingApproval').length;
    final approvedTx = transactions.where((t) => t['status'] == 'Completed').length;
    final rejectedTx = transactions.where((t) => t['status'] == 'Rejected').length;

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Transactions', totalTx.toString(), Colors.black, Icons.list),
            const SizedBox(width: 12),
            _buildStatCard('Pending', pendingTx.toString(), Colors.amber, Icons.pending_actions),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('Approved', approvedTx.toString(), Colors.green, Icons.check_circle),
            const SizedBox(width: 12),
            _buildStatCard('Rejected', rejectedTx.toString(), Colors.red, Icons.cancel),
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

  Widget _buildFilterChips() {
    final filters = ['All', 'PendingApproval', 'Completed', 'Rejected'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter == 'PendingApproval' ? 'Pending' : (filter == 'Completed' ? 'Approved' : filter)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    selectedFilter = filter;
                    currentPage = 1;
                  });
                  fetchTransactions();
                }
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? Colors.black : Colors.grey[200]!),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic transaction) {
    final status = transaction['status'];
    final isPending = status == 'PendingApproval';
    final isApproved = status == 'Completed';
    final amount = (transaction['amount'] ?? 0);
    final date = transaction['createdAt']?.split('T')[0] ?? 'No date';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TRANSACTION #${transaction['id']}', style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[400],
                    letterSpacing: 1
                  )),
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600]
                  )),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPending ? Colors.amber[50] : (isApproved ? Colors.green[50] : Colors.red[50]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isPending ? Colors.amber[700] : (isApproved ? Colors.green[700] : Colors.red[700]),
                    letterSpacing: 0.5
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('R ${amount.toStringAsFixed(2)}', style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black
          )),
          const SizedBox(height: 24),
          
          _buildTransactionInfoRow('FROM ACCOUNT', transaction['fromAccountNumber'] ?? 'N/A'),
          const SizedBox(height: 12),
          _buildTransactionInfoRow('TO ACCOUNT', transaction['toAccountNumber'] ?? 'N/A'),
          
          if (transaction['senderReference'] != null) ...[
            const SizedBox(height: 12),
            _buildTransactionInfoRow('SENDER REF', transaction['senderReference']),
          ],

          if (transaction['beneficiaryReference'] != null) ...[
            const SizedBox(height: 12),
            _buildTransactionInfoRow('BENEFICIARY REF', transaction['beneficiaryReference']),
          ],
          
          if (transaction['reviewNote'] != null && transaction['reviewNote'].isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REVIEW NOTE', style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[400],
                    letterSpacing: 1
                  )),
                  const SizedBox(height: 4),
                  Text(transaction['reviewNote'], style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black
                  )),
                ],
              ),
            ),
          ],

          if (isPending) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => approveTransaction(transaction),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => rejectTransaction(transaction),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 0.5
        )),
        Text(value, style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black
        )),
      ],
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: currentPage > 1 ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: IconButton(
            onPressed: currentPage > 1 ? () {
              setState(() {
                currentPage--;
              });
              fetchTransactions();
            } : null,
            icon: Icon(Icons.chevron_left, color: currentPage > 1 ? Colors.black : Colors.grey[400]),
          ),
        ),
        Text('Page $currentPage of $totalPages', style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black
        )),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: currentPage < totalPages ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: IconButton(
            onPressed: currentPage < totalPages ? () {
              setState(() {
                currentPage++;
              });
              fetchTransactions();
            } : null,
            icon: Icon(Icons.chevron_right, color: currentPage < totalPages ? Colors.black : Colors.grey[400]),
          ),
        ),
      ],
    );
  }
}
