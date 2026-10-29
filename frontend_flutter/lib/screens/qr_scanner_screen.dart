import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ride_provider.dart';
import 'active_ride_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String? prefilledCode;
  const QRScannerScreen({super.key, this.prefilledCode});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late TextEditingController _qrCodeController;

  @override
  void initState() {
    super.initState();
    _qrCodeController = TextEditingController(text: widget.prefilledCode ?? 'QR-PAL-101');
  }

  void _unlockCycle() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ride = Provider.of<RideProvider>(context, listen: false);
    final code = _qrCodeController.text.trim();

    if (code.isEmpty) return;

    final success = await ride.startRide(auth.token!, code);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cycle unlocked! Ride started.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ActiveRideScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ride.errorMessage ?? 'Could not unlock cycle.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = Provider.of<RideProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Scan & Unlock Cycle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF10B981), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF10B981)),
                  SizedBox(height: 12),
                  Text(
                    'Point Camera at Bike QR',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cycle QR Code',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _qrCodeController,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF10B981)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: ride.isLoading ? null : _unlockCycle,
                      child: ride.isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Unlock & Start Ride',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
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
