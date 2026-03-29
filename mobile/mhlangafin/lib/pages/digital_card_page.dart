import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/account.dart';
import '../utils/jwt_helper.dart';

class DigitalCardPage extends StatefulWidget {
  final String? token;
  const DigitalCardPage({super.key, this.token});

  @override
  State<DigitalCardPage> createState() => _DigitalCardPageState();
}

class _DigitalCardPageState extends State<DigitalCardPage> {
  bool showCardDetails = false;
  bool isCardActive = true;
  bool isLoading = true;
  Account? mainAccount;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    fetchMainAccount();
  }

  Future<void> fetchMainAccount() async {
    if (widget.token == null) return;
    try {
      final result = await apiService.getAccounts(widget.token!);
      final accountList = (result as List).map((item) => Account.fromJson(item)).toList();
      setState(() {
        try {
          mainAccount = accountList.firstWhere((acc) => acc.isMain);
        } catch (_) {
          mainAccount = accountList.isNotEmpty ? accountList.first : null;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String getInitialAndSurname() {
    if (widget.token == null) return 'MEMBER';
    final fullName = JwtHelper.getUserName(widget.token!);
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final initial = parts[0][0].toUpperCase();
      final surname = parts.last;
      return '$initial. $surname'.toUpperCase();
    }
    return fullName.toUpperCase();
  }

  String getUserInitials() {
     if (widget.token == null) return 'M';
    final fullName = JwtHelper.getUserName(widget.token!);
    return fullName.split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).join('').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Virtual Payment Suite', style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold
        )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Elite Portfolio', style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -1
                )),
                const SizedBox(height: 8),
                Text('Secure. Virtual. Instant.', style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic
                )),

                const SizedBox(height: 32),

                // Premium Card UI
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showCardDetails = !showCardDetails;
                    });
                  },
                  child: Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A), Colors.black],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Texture pattern (simplified carbon fibre effect)
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.05,
                            child: Image.network(
                              'https://www.transparenttextures.com/patterns/carbon-fibre.png',
                              repeat: ImageRepeat.repeat,
                            ),
                          ),
                        ),
                        // Glow effects
                        Positioned(
                          top: -50,
                          right: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue[600]!.withOpacity(0.1),
                            ),
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('PRIVATE RESERVE', style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2
                                          )),
                                        ],
                                      ),
                                      const Text('MhlangaFin', style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -1
                                      )),
                                    ],
                                  ),
                                  // EMV Chip
                                  Container(
                                    width: 48,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFCD34D), Color(0xFFF59E0B), Color(0xFFB45309)],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                  ),
                                ],
                              ),

                              // Account Number
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Text('ACCOUNT LINKED VIRTUAL NUMBER', style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2
                                  )),
                                  const SizedBox(height: 8),
                                  Text(
                                    showCardDetails 
                                      ? (mainAccount?.accountNumber ?? 'FN-PENDING')
                                      : '••••  ••••  ••••  ${mainAccount?.accountNumber.split('-').last.padLeft(4, '0').substring(mainAccount!.accountNumber.split('-').last.length - 4)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                      fontFamily: 'Courier'
                                    ),
                                  ),
                                ],
                              ),

                              // Holder and Expiry
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('CARD HOLDER', style: TextStyle(
                                        color: Colors.white.withOpacity(0.3),
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2
                                      )),
                                      const SizedBox(height: 4),
                                      Text(
                                        showCardDetails ? getInitialAndSurname() : '${getUserInitials()} ••••••',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('EXPIRY', style: TextStyle(
                                            color: Colors.white.withOpacity(0.3),
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2
                                          )),
                                          Text(mainAccount?.expiryDate ?? '12/28', style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold
                                          )),
                                        ],
                                      ),
                                      if (showCardDetails) ...[
                                        const SizedBox(width: 24),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('CVV', style: TextStyle(
                                              color: Colors.white.withOpacity(0.3),
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2
                                            )),
                                            Text(mainAccount?.cvv ?? '***', style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold
                                            )),
                                          ],
                                        ),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Tap to reveal overlay
                        if (!showCardDetails)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.1),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: const Text('TAP TO REVEAL', style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2
                                  )),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Tap the card to reveal secure credentials. Never share your card number.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5),
                  ),
                ),

                const SizedBox(height: 48),

                // Card Controls
                const Text('Card Controls', style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black
                )),
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
                      _buildControlRow(
                        title: 'Card Status',
                        subtitle: isCardActive ? 'Active' : 'Locked',
                        trailing: Switch(
                          value: isCardActive,
                          onChanged: (v) => setState(() => isCardActive = v),
                          activeColor: Colors.black,
                        ),
                      ),
                      const Divider(height: 32),
                      _buildControlRow(
                        title: 'International Payments',
                        subtitle: 'Enabled for global transactions',
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                      const Divider(height: 32),
                      _buildControlRow(
                        title: 'Spending Limits',
                        subtitle: 'R 50,000.00 daily limit',
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                // Perks
                 _buildPerkCard(
                  icon: Icons.security,
                  title: 'Elite Fraud Shield',
                  description: '24/7 AI-monitored protection with zero liability guarantee.',
                  color: Colors.green[50]!,
                  iconColor: Colors.green[600]!,
                ),
                const SizedBox(height: 16),
                _buildPerkCard(
                  icon: Icons.bolt,
                  title: 'Instant Virtualization',
                  description: 'Deploy new digital cards for secure online shopping in one click.',
                  color: Colors.blue[50]!,
                  iconColor: Colors.blue[600]!,
                ),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
    );
  }

  Widget _buildControlRow({required String title, required String subtitle, required Widget trailing}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildPerkCard({required IconData icon, required String title, required String description, required Color color, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
