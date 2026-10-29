import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ride_provider.dart';
import '../providers/fleet_provider.dart';
import '../providers/wallet_provider.dart';
import 'home_map_screen.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;
  String? _selectedStationId;

  @override
  void initState() {
    super.initState();
    _startTimer();
    final fleet = Provider.of<FleetProvider>(context, listen: false);
    if (fleet.stations.isNotEmpty) {
      _selectedStationId = fleet.stations.first.id;
    }
  }

  void _startTimer() {
    final ride = Provider.of<RideProvider>(context, listen: false);
    if (ride.activeRide != null) {
      final diff = DateTime.now().difference(ride.activeRide!.startTime).inSeconds;
      _secondsElapsed = diff > 0 ? diff : 0;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _calculateProjectedFare(int totalSeconds) {
    int minutes = (totalSeconds / 60).ceil();
    if (minutes < 1) minutes = 1;
    return 1.50 + (minutes * 0.15);
  }

  void _concludeRide() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ride = Provider.of<RideProvider>(context, listen: false);
    final wallet = Provider.of<WalletProvider>(context, listen: false);

    if (_selectedStationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination docking station.')),
      );
      return;
    }

    final success = await ride.endRide(auth.token!, _selectedStationId!);
    if (success && mounted) {
      await wallet.fetchWallet(auth.token!);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Ride Completed!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Duration: ${_formatTimer(_secondsElapsed)}', style: const TextStyle(color: Color(0xFF94A3B8))),
              const SizedBox(height: 6),
              Text('Fare Deducted: \$${_calculateProjectedFare(_secondsElapsed).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Remaining Balance: \$${wallet.balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeMapScreen()),
                  (route) => false,
                );
              },
              child: const Text('Done', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = Provider.of<RideProvider>(context);
    final fleet = Provider.of<FleetProvider>(context);

    if (ride.activeRide == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No active ride found.', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Map'),
              ),
            ],
          ),
        ),
      );
    }

    final currentCycle = ride.activeRide!.cycleNumber;
    final projectedFare = _calculateProjectedFare(_secondsElapsed);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Live Trip In Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.directions_bike, size: 56, color: Color(0xFF10B981)),
                  const SizedBox(height: 12),
                  Text(
                    'Cycle $currentCycle',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Origin: ${ride.activeRide!.startStationName ?? "Smart Dock"}',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                  const Divider(color: Color(0xFF334155), height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('TIME ELAPSED', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimer(_secondsElapsed),
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('PROJECTED FARE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            '\$${projectedFare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Destination Docking Station:',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedStationId ?? (fleet.stations.isNotEmpty ? fleet.stations.first.id : null),
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    items: fleet.stations.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text('${s.name} (${s.availableCycles}/${s.capacity} docks)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedStationId = val;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: ride.isLoading ? null : _concludeRide,
                      child: ride.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Lock Bike & Conclude Trip',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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
