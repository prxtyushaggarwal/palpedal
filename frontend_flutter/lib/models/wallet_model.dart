class WalletTransactionModel {
  final String id;
  final String transactionType;
  final double amount;
  final String description;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] ?? '',
      transactionType: json['transaction_type'] ?? 'CREDIT',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      description: json['description'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class WalletModel {
  final String id;
  final String username;
  final double balance;
  final List<WalletTransactionModel> transactions;

  WalletModel({
    required this.id,
    required this.username,
    required this.balance,
    required this.transactions,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    var rawTx = json['transactions'] as List? ?? [];
    List<WalletTransactionModel> txList =
        rawTx.map((item) => WalletTransactionModel.fromJson(item)).toList();

    return WalletModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      transactions: txList,
    );
  }
}
