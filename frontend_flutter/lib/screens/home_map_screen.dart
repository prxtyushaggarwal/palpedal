import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/fleet_provider.dart';
import '../providers/ride_provider.dart';
import 'wallet_screen.dart';
import 'qr_scanner_screen.dart';
import 'active_ride_screen.dart';
import 'ride_history_screen.dart';
import 'login_screen.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token != null) {
      Provider.of<WalletProvider>(context, listen: false).fetchWallet(auth.token!);
      Provider.of<FleetProvider>(context, listen: false).fetchStations();
      Provider.of<RideProvider>(context, listen: false).checkActiveRide(auth.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final wallet = Provider.of<WalletProvider>(context);
    final fleet = Provider.of<FleetProvider>(context);
    final ride = Provider.of<RideProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pedal_bike, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'PalPedal',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Wallet Pill
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Color(0xFF34D399), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '\$${wallet.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF94A3B8)),
            onPressed: () async {
              await auth.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadInitialData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Ride Banner if present
              if (ride.hasActiveRide) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF065F46), Color(0xFF0E7490)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bike, color: Colors.white, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RIDE IN PROGRESS',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cycle ${ride.activeRide!.cycleNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveRideScreen()));
                        },
                        child: const Text('View Ride', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nearby Smart Stations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8)),
                    onPressed: () => fleet.fetchStations(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Fleet List
              if (fleet.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: fleet.stations.length,
                  itemBuilder: (context, index) {
                    final station = fleet.stations[index];
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    station.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${station.availableCycles}/${station.capacity} Free',
                                    style: const TextStyle(
                                      color: Color(0xFF34D399),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    station.address,
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Available Cycles:',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: station.cycles.where((c) => c.status == 'AVAILABLE').map((cycle) {
                                return ActionChip(
                                  backgroundColor: const Color(0xFF0F172A),
                                  avatar: const Icon(Icons.pedal_bike, size: 14, color: Color(0xFF10B981)),
                                  label: Text(
                                    '${cycle.cycleNumber} (${cycle.batteryPercentage}%)',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => QRScannerScreen(prefilledCode: cycle.qrCode),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF1E293B),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.map, color: Color(0xFF10B981)),
              onPressed: () {},
            ),
            FloatingActionButton(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: const Color(0xFF0F172A),
              elevation: 4,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
              },
              child: const Icon(Icons.qr_code_scanner, size: 28),
            ),
            IconButton(
              icon: const Icon(Icons.history, color: Color(0xFF94A3B8)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RideHistoryScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.account_balance_wallet, color: Color(0xFF94A3B8)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
