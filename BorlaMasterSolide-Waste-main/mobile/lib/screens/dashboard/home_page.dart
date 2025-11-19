import 'package:flutter/material.dart';
import 'request_pickup_screen.dart'; // if you have navigation to request pickup

class HomePage extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final bool loading;

  const HomePage({super.key, required this.profile, required this.loading});

  @override
  Widget build(BuildContext context) {
    final userName =
        profile != null ? (profile!['full_name'] ?? 'User') : 'User';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back, $userName 👋',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Here is a quick summary of your activity:',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _StatCard(title: 'Upcoming Pickups', value: '2'),
                    _StatCard(title: 'Completed', value: '15'),
                    _StatCard(title: 'Wallet Balance', value: 'GHS 120.00'),
                    _StatCard(title: 'Active Companies', value: '4'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Quick actions',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RequestPickupScreen()),
                          );
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Request Pickup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.history, color: Colors.white70),
                        label: const Text('History',
                            style: TextStyle(color: Colors.white70)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white12),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/* ---------------------------
   STAT CARD WIDGET (kept here)
   --------------------------- */
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
