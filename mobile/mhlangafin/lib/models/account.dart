class Account {
  final int id;
  final String accountName;
  final String accountNumber;
  double balance;
  final bool isMain;
  final String status;
  final String? expiryDate;
  final String? cvv;

  Account({
    required this.id,
    required this.accountName,
    required this.accountNumber,
    required this.balance,
    required this.isMain,
    required this.status,
    this.expiryDate,
    this.cvv,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      accountName: json['accountName'],
      accountNumber: json['accountNumber'],
      balance: (json['balance'] ?? 0.0).toDouble(),
      isMain: json['isMain'] ?? false,
      status: json['status'] ?? 'Active',
      expiryDate: json['expiryDate'],
      cvv: json['cvv'],
    );
  }
}
