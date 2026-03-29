import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/account.dart';
import '../utils/jwt_helper.dart';

class TransferPage extends StatefulWidget {
  final String? token;
  const TransferPage({super.key, this.token});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final ApiService apiService = ApiService();
  
  // Controllers
  final TextEditingController toAccountController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController beneficiaryRefController = TextEditingController();
  final TextEditingController senderRefController = TextEditingController();
  
  // Add Beneficiary Controllers
  final TextEditingController newBenNameController = TextEditingController();
  final TextEditingController newBenAccountController = TextEditingController();

  List<Account> accounts = [];
  List<dynamic> beneficiaries = [];
  bool isLoading = true;
  bool isProcessing = false;
  String? errorMessage;
  Account? selectedFromAccount;
  bool showAddBeneficiary = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    toAccountController.dispose();
    amountController.dispose();
    beneficiaryRefController.dispose();
    senderRefController.dispose();
    newBenNameController.dispose();
    newBenAccountController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    if (widget.token == null) return;
    setState(() => isLoading = true);
    try {
      final accs = await apiService.getAccounts(widget.token!);
      final bens = await apiService.getBeneficiaries(widget.token!);
      setState(() {
        accounts = (accs as List).map((i) => Account.fromJson(i)).toList();
        beneficiaries = bens;
        if (accounts.isNotEmpty) {
          selectedFromAccount = accounts.firstWhere((a) => a.isMain, orElse: () => accounts.first);
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load banking data. Please try again.';
        isLoading = false;
      });
    }
  }

  void selectBeneficiary(dynamic ben) {
    setState(() {
      toAccountController.text = ben['accountNumber'];
      senderRefController.text = ben['name'];
      beneficiaryRefController.text = JwtHelper.getUserName(widget.token!);
    });
    // Scroll to top
  }

  Future<void> saveBeneficiary() async {
    if (newBenNameController.text.isEmpty || newBenAccountController.text.isEmpty) return;
    setState(() => isProcessing = true);
    try {
      await apiService.addBeneficiary(
        widget.token!,
        newBenNameController.text,
        newBenAccountController.text,
        null
      );
      final bens = await apiService.getBeneficiaries(widget.token!);
      setState(() {
        beneficiaries = bens;
        showAddBeneficiary = false;
        newBenNameController.clear();
        newBenAccountController.clear();
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to save beneficiary.';
        isProcessing = false;
      });
    }
  }

  Future<void> performTransfer() async {
    if (selectedFromAccount == null || toAccountController.text.isEmpty || amountController.text.isEmpty) {
      setState(() => errorMessage = 'Please provide all transfer details.');
      return;
    }

    if (selectedFromAccount!.accountNumber == toAccountController.text) {
       setState(() => errorMessage = 'Source and destination accounts cannot be identical.');
       return;
    }

    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    try {
      await apiService.makeTransfer(
        widget.token!,
        selectedFromAccount!.accountNumber,
        toAccountController.text,
        double.parse(amountController.text),
        beneficiaryRefController.text,
        senderRefController.text
      );
      
      setState(() => isProcessing = false);
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isProcessing = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text('Payment Successful', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Your transfer of R ${double.parse(amountController.text).toStringAsFixed(2)} has been authorized and processed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Back to dashboard
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text('Return to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pay Beneficiary'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)),
                        child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),

                    // Progress Stepper (Visual only)
                    Row(
                      children: [
                        _buildStep(1, 'Details', true),
                        Expanded(child: Container(height: 2, color: Colors.black26)),
                        _buildStep(2, 'Amount', false),
                        Expanded(child: Container(height: 2, color: Colors.black26)),
                        _buildStep(3, 'Auth', false),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text('SOURCE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Account>(
                          value: selectedFromAccount,
                          isExpanded: true,
                          items: accounts.map((a) => DropdownMenuItem(
                            value: a,
                            child: Row(
                              children: [
                                Icon(a.isMain ? Icons.star : Icons.account_balance_wallet, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text('${a.accountName} (R ${a.balance.toStringAsFixed(2)})'),
                              ],
                            ),
                          )).toList(),
                          onChanged: (v) => setState(() => selectedFromAccount = v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Text('RECIPIENT & REFERENCES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5, color: Colors.grey)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: toAccountController,
                      decoration: const InputDecoration(hintText: 'Acc Number / Public Key'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixText: 'R ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: beneficiaryRefController,
                            decoration: const InputDecoration(hintText: 'Their Reference', labelText: 'Ben Ref'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: senderRefController,
                            decoration: const InputDecoration(hintText: 'My Reference', labelText: 'My Ref'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isProcessing ? null : performTransfer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                        child: isProcessing 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('Authorize Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),

                    const SizedBox(height: 48),
                    const Divider(),
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Saved Beneficiaries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        IconButton(
                          onPressed: () => setState(() => showAddBeneficiary = !showAddBeneficiary),
                          icon: Icon(showAddBeneficiary ? Icons.close : Icons.person_add, color: Colors.black),
                        ),
                      ],
                    ),
                    
                    if (showAddBeneficiary) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[200]!)),
                        child: Column(
                          children: [
                            TextField(controller: newBenNameController, decoration: const InputDecoration(labelText: 'Beneficiary Name')),
                            const SizedBox(height: 12),
                            TextField(controller: newBenAccountController, decoration: const InputDecoration(labelText: 'Account Number')),
                            const SizedBox(height: 24),
                            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: isProcessing ? null : saveBeneficiary, child: const Text('Add to Directory'))),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    if (beneficiaries.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text('Directory Empty', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: beneficiaries.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ben = beneficiaries[index];
                          return ListTile(
                            onTap: () => selectBeneficiary(ben),
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
                            leading: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text(ben['name'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
                            ),
                            title: Text(ben['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(ben['accountNumber'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            trailing: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                              child: const Icon(Icons.chevron_right, size: 16),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              if (isProcessing)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator(color: Colors.black)),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildStep(int number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: isActive ? Colors.black : Colors.grey[200], shape: BoxShape.circle),
          child: Center(child: Text(number.toString(), style: TextStyle(color: isActive ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
      ],
    );
  }
}
