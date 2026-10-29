import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController(text: '20');

  void _showTopUpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Top-Up PalPedal Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter recharge amount:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'monospace'),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [10, 20, 50, 100].map((amt) {
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: const BorderSide(color: Color(0xFF334155)),
                  ),
                  onPressed: () => _amountController.text = amt.toString(),
                  child: Text('+$amt'),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final wallet = Provider.of<WalletProvider>(context, listen: false);
              final val = double.tryParse(_amountController.text) ?? 0.0;
              if (val > 0) {
                Navigator.pop(ctx);
                final ok = await wallet.topUp(auth.token!, val);
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added \$$val to wallet successfully!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Digital Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'PALPEDAL BALANCE',
                        style: TextStyle(
                          color: Color(0xFFD1FAE5),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      Icon(Icons.shield, color: Color(0xFF34D399), size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${wallet.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _showTopUpDialog,
                    icon: const Icon(Icons.add_circle, color: Color(0xFF10B981)),
                    label: const Text('Top-Up Funds', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Transactions Log
            const Text(
              'Transaction History',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            if (wallet.transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No transactions yet.', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wallet.transactions.length,
                itemBuilder: (context, idx) {
                  final tx = wallet.transactions[idx];
                  final isCredit = tx.transactionType == 'CREDIT';

                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCredit
                            ? const Color(0xFF10B981).withOpacity(0.15)
                            : const Color(0xFFEF4444).withOpacity(0.15),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        tx.description,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        tx.createdAt.toLocal().toString().split('.')[0],
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                      trailing: Text(
                        '${isCredit ? "+" : "-"}\$${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isCredit ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
