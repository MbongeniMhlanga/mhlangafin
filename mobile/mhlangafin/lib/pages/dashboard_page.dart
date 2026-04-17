import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../services/api_service.dart';
import '../models/account.dart';
import '../utils/jwt_helper.dart';
import 'digital_card_page.dart';
import 'transfer_page.dart';

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

  // Transaction History State
  bool isHistoryLoading = false;
  String? historyError;
  bool showHistoryModal = false;
  Account? selectedAccountForHistory;
  dynamic transactionHistory;
  
  // Statement State
  bool isStatementLoading = false;
  String? statementError;
  bool showStatementModal = false;
  Account? selectedAccountForStatement;
  DateTime? startDate;
  DateTime? endDate;
  
  // Internal Transfer State
  bool showInternalTransferModal = false;
  int? selectedFromAccountId;
  int? selectedToAccountId;
  double? transferAmount;
  String? internalTransferError;

  final TextEditingController accountNameController = TextEditingController();
  final TextEditingController initialBalanceController = TextEditingController();
  final TextEditingController transferAmountController = TextEditingController();
  
  final ApiService apiService = ApiService();
  String? token;

  @override
  void initState() {
    super.initState();
    token = widget.token;
    fetchAccounts();
  }

  Future<void> fetchAccounts() async {
    if (token == null) return;
    
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await apiService.getAccounts(token!);
      
      setState(() {
        accounts = (result as List).map((item) => Account.fromJson(item)).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
      setState(() {
        error = 'Failed to load accounts. Please check your connection.';
        isLoading = false;
      });
    }
  }

  Future<void> createAccount() async {
    if (token == null) return;
    
    if (accountNameController.text.isEmpty || 
        double.tryParse(initialBalanceController.text) == null) {
      setState(() {
        error = 'Please fill in all fields correctly';
      });
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
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
      final userId = JwtHelper.getUserId(token!);
      final result = await apiService.createAccount(
        token!,
        userId,
        accountNameController.text,
        double.parse(initialBalanceController.text),
      );
      
      setState(() {
        accounts.add(Account.fromJson(result));
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

  Future<void> executeInternalTransfer() async {
    if (token == null) return;
    
    if (selectedFromAccountId == null || selectedToAccountId == null || transferAmountController.text.isEmpty) {
      setState(() {
        internalTransferError = 'Please fill in all fields.';
      });
      return;
    }

    final amount = double.tryParse(transferAmountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        internalTransferError = 'Invalid amount.';
      });
      return;
    }

    if (selectedFromAccountId == selectedToAccountId) {
      setState(() {
        internalTransferError = 'Cannot transfer to the same account.';
      });
      return;
    }

    setState(() {
      isTransferring = true;
      internalTransferError = null;
    });

    try {
      final result = await apiService.internalTransfer(
        token!,
        selectedFromAccountId!,
        selectedToAccountId!,
        amount,
      );
      
      setState(() {
        // Update account balances from API response
        final fromAccount = accounts.firstWhere((acc) => acc.id == selectedFromAccountId!);
        final toAccount = accounts.firstWhere((acc) => acc.id == selectedToAccountId!);
        
        fromAccount.balance = (result['fromAccountBalance'] ?? 0).toDouble();
        toAccount.balance = (result['toAccountBalance'] ?? 0).toDouble();
        isTransferring = false;
      });
      
      closeInternalTransferModal();
    } catch (e) {
      setState(() {
        internalTransferError = 'Transfer failed. Please try again.';
        isTransferring = false;
      });
    }
  }

  double getTotalBalance() {
    return accounts.fold(0.0, (sum, acc) => sum + acc.balance);
  }

  Account? get mainAccount {
    try {
      return accounts.firstWhere((acc) => acc.isMain);
    } catch (_) {
      return accounts.isNotEmpty ? accounts.first : null;
    }
  }
  
  List<Account> get subAccounts => accounts.where((acc) => !acc.isMain).toList();

  // Transaction History Methods
  Future<void> viewTransactionHistory(Account account) async {
    if (token == null) return;
    
    setState(() {
      selectedAccountForHistory = account;
      transactionHistory = null;
      historyError = null;
      isHistoryLoading = true;
      showHistoryModal = true;
    });

    try {
      final result = await apiService.getTransactionHistory(
        token!,
        account.id.toString(),
        1,
        20
      );
      
      setState(() {
        transactionHistory = result;
        isHistoryLoading = false;
      });
    } catch (e) {
      setState(() {
        historyError = 'Failed to load transaction history.';
        isHistoryLoading = false;
      });
    }
  }

  void closeTransactionHistory() {
    setState(() {
      selectedAccountForHistory = null;
      showHistoryModal = false;
      transactionHistory = null;
      historyError = null;
    });
  }

  // Statement Methods
  Future<void> downloadStatement() async {
    if (token == null) return;
    
    if (selectedAccountForStatement == null || startDate == null || endDate == null) {
      setState(() {
        statementError = 'Please select all required fields.';
      });
      return;
    }

    if (startDate!.isAfter(endDate!)) {
      setState(() {
        statementError = 'Start date must be before end date.';
      });
      return;
    }

    setState(() {
      isStatementLoading = true;
      statementError = null;
    });

    try {
      final result = await apiService.downloadStatement(
        token!,
        selectedAccountForStatement!.id.toString(),
        startDate!,
        endDate!,
        'PDF'
      );
      
      setState(() {
        isStatementLoading = false;
      });
      
      if (mounted) {
        // Save and Open PDF
        try {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'Statement_${selectedAccountForStatement!.accountNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(result as List<int>);
          
          await OpenFilex.open(filePath);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Statement saved to $filePath')),
            );
          }
        } catch (e) {
           showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to save or open the statement: $e'),
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
    } catch (e) {
      setState(() {
        statementError = 'Failed to download statement.';
        isStatementLoading = false;
      });
    }
  }

  void openStatementModal(Account account) {
    setState(() {
      selectedAccountForStatement = account;
      showStatementModal = true;
      startDate = null;
      endDate = null;
      statementError = null;
    });
  }

  void closeStatementModal() {
    setState(() {
      selectedAccountForStatement = null;
      showStatementModal = false;
      startDate = null;
      endDate = null;
      statementError = null;
    });
  }

  void openInternalTransferModal(Account? fromAccount) {
    setState(() {
      showInternalTransferModal = true;
      internalTransferError = null;
      selectedFromAccountId = fromAccount?.id;
      selectedToAccountId = null;
      transferAmountController.clear();
    });
  }

  void closeInternalTransferModal() {
    setState(() {
      showInternalTransferModal = false;
      selectedFromAccountId = null;
      selectedToAccountId = null;
      transferAmountController.clear();
      internalTransferError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
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
                        const Text('MhlangaFin', style: TextStyle(
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
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DigitalCardPage(token: token),
                        ),
                      );
                    },
                    icon: const Icon(Icons.credit_card, color: Colors.black),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
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
                        Text(error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: fetchAccounts,
                          child: const Text('Retry'),
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
                        // Portfolio Balance
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Portfolio Total', style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500],
                                letterSpacing: 2
                              )),
                              const SizedBox(height: 8),
                              Text('R ${getTotalBalance().toStringAsFixed(2)}', style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                              )),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  _buildActionButton(Icons.add, 'Add Money', () {}),
                                  const SizedBox(width: 12),
                                  _buildActionButton(Icons.arrow_upward, 'Pay', () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TransferPage(token: token),
                                      ),
                                    );
                                  }),
                                  const SizedBox(width: 12),
                                  _buildActionButton(Icons.credit_card, 'Cards', () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DigitalCardPage(token: token),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Main Account
                        if (mainAccount != null) _buildMainAccountCard(mainAccount!),

                        const SizedBox(height: 48),

                        // Savings Pockets
                        _buildSavingsSection(),

                        const SizedBox(height: 48),

                        // Create Account Section
                        _buildCreateAccountSection(),
                        
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          if (showHistoryModal) _buildHistoryModal(),
          if (showStatementModal) _buildStatementModal(),
          if (showInternalTransferModal) _buildInternalTransferModal(),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMainAccountCard(Account account) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Transactional Account', style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Primary', style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
                letterSpacing: 1.5
              )),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
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
                      Text(account.accountName, style: const TextStyle(
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
              Text('R ${account.balance.toStringAsFixed(2)}', style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black
              )),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => viewTransactionHistory(account),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Activity', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => openInternalTransferModal(account),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Move', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                   const SizedBox(width: 12),
                   IconButton(
                    onPressed: () => openStatementModal(account),
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.grey),
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
                const Text('Savings Pockets', style: TextStyle(
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
                  child: Text('Growth', style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                    letterSpacing: 1.5
                  )),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (subAccounts.isEmpty)
           Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text('No savings pockets yet.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 2.2,
              mainAxisSpacing: 16,
            ),
            itemCount: subAccounts.length,
            itemBuilder: (context, index) => _buildPocketCard(subAccounts[index]),
          ),
      ],
    );
  }

  Widget _buildPocketCard(Account account) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(account.accountName, style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black
              )),
              Text(account.accountNumber, style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 1
              )),
              const Spacer(),
              Text('R ${account.balance.toStringAsFixed(2)}', style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black
              )),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => openInternalTransferModal(account),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Move'),
              ),
              IconButton(onPressed: () => viewTransactionHistory(account), icon: const Icon(Icons.history, size: 20))
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCreateAccountSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Open Savings Pocket', style: TextStyle(
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
                : const Text('Authorize Pocket', style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                  )),
            ),
          ),
        ],
      ),
    );
  }

  // Modal Builders
  Widget _buildHistoryModal() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Activity Details', style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black
                            )),
                            Text('${selectedAccountForHistory?.accountName} • ${selectedAccountForHistory?.accountNumber}', style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600]
                            )),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: closeTransactionHistory,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (isHistoryLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.black)))
                  else if (historyError != null)
                    Expanded(child: Center(child: Text(historyError!)))
                  else if (transactionHistory != null)
                    Expanded(
                      child: ListView.builder(
                        itemCount: transactionHistory['transactions']?.length ?? 0,
                        itemBuilder: (context, index) {
                          final tx = transactionHistory['transactions'][index];
                           final amount = (tx['amount'] ?? 0.0);
                           final isCredit = amount > 0;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(tx['description'] ?? 'No description', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(tx['timestamp']?.split('T')[0] ?? ''),
                            trailing: Text(
                              '${isCredit ? "+" : ""}R ${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCredit ? Colors.green[700] : Colors.red[700],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatementModal() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Account Statements', style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black
                  )),
                  Text('${selectedAccountForStatement?.accountName}', style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600]
                  )),
                  
                  const SizedBox(height: 24),
                  
                  if (statementError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(statementError!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Date', style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600]
                      )),
                      const SizedBox(height: 8),
                      TextField(
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              startDate = date;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: startDate?.toLocal().toString().split(' ')[0] ?? 'Select date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text('End Date', style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600]
                      )),
                      const SizedBox(height: 8),
                      TextField(
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              endDate = date;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: endDate?.toLocal().toString().split(' ')[0] ?? 'Select date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => closeStatementModal(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Dismiss'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isStatementLoading ? null : downloadStatement,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                          ),
                          child: isStatementLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Generate PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInternalTransferModal() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Internal Transfer', style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black
                  )),
                  Text('Move Money Between Pockets', style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600]
                  )),
                  
                  const SizedBox(height: 24),
                  
                  if (internalTransferError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(internalTransferError!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From Account', style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600]
                      )),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedFromAccountId,
                        onChanged: (value) {
                          setState(() {
                            selectedFromAccountId = value;
                          });
                        },
                        items: accounts.map((acc) => DropdownMenuItem(
                          value: acc.id,
                          child: Text('${acc.accountName.substring(0, acc.accountName.length > 10 ? 10 : acc.accountName.length)}... (R ${acc.balance.toStringAsFixed(2)})'),
                        )).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text('To Account', style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600]
                      )),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedToAccountId,
                        onChanged: (value) {
                          setState(() {
                            selectedToAccountId = value;
                          });
                        },
                        items: accounts.map((acc) => DropdownMenuItem(
                          value: acc.id,
                          child: Text('${acc.accountName.substring(0, acc.accountName.length > 10 ? 10 : acc.accountName.length)}... (R ${acc.balance.toStringAsFixed(2)})'),
                        )).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text('Amount to Move', style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600]
                      )),
                      const SizedBox(height: 8),
                      TextField(
                        controller: transferAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: 'R ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => closeInternalTransferModal(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isTransferring ? null : executeInternalTransfer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: isTransferring 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Authorize'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
