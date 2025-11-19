import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

class LiveRequestsPage extends StatefulWidget {
  const LiveRequestsPage({super.key});

  @override
  State<LiveRequestsPage> createState() => _LiveRequestsPageState();
}

class _LiveRequestsPageState extends State<LiveRequestsPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<dynamic> bookings = [];
  RealtimeChannel? bookingsChannel;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _subscribeToBookingChanges();
  }

  @override
  void dispose() {
    bookingsChannel?.unsubscribe();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => loading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('bookings')
          .select(
              'id, waste_type, pickup_date, region, town, status, companies(company_name)')
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);

      setState(() => bookings = response);
      debugPrint('✅ Fetched ${response.length} bookings.');
    } catch (e) {
      debugPrint('❌ Error loading bookings: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _cancelBooking(String id) async {
    try {
      await supabase
          .from('bookings')
          .update({'status': 'cancelled'}).eq('id', id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚫 Request cancelled successfully.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _loadRequests();
    } catch (e) {
      debugPrint('❌ Error cancelling booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel request.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmPickup(String id) async {
    try {
      final booking = bookings.firstWhere((b) => b['id'] == id);
      String newStatus;

      if ((booking['status'] ?? '').toString().toLowerCase() ==
          'company_confirmed') {
        newStatus = 'completed';
      } else {
        newStatus = 'customer_confirmed';
      }

      await supabase
          .from('bookings')
          .update({'status': newStatus}).eq('id', id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'completed'
              ? '✅ Pickup confirmed completed!'
              : '✅ You have confirmed the pickup.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadRequests();
    } catch (e) {
      debugPrint('❌ Failed to confirm pickup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to confirm pickup.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _subscribeToBookingChanges() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    bookingsChannel = supabase
        .channel('realtime-bookings')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: user.id,
          ),
          callback: (payload) async {
            final updated = payload.newRecord;
            if (updated != null) {
              final status = updated['status'];
              final town = updated['town'] ?? 'your area';
              final waste = updated['waste_type'] ?? 'waste';

              await _playNotificationSound();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '📢 Your $waste booking in $town is now ${status.toString().toUpperCase()}!',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            }
            await _loadRequests();
          },
        )
        .subscribe();
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/ding.mp3'));
    } catch (e) {
      debugPrint('⚠️ Failed to play sound: $e');
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.greenAccent;
      case 'customer_confirmed':
      case 'company_confirmed':
        return Colors.lightGreenAccent;
      case 'in_progress':
        return Colors.blueAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  int _statusStep(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 4;
      case 'customer_confirmed':
      case 'company_confirmed':
        return 3;
      case 'in_progress':
        return 2;
      default:
        return 1;
    }
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'N/A';
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('EEE, MMM d, yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text('My Live Requests'),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        elevation: 4,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        color: Colors.redAccent,
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.redAccent))
            : bookings.isEmpty
                ? const Center(
                    child: Text('No pickup requests yet.',
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final r = bookings[i];
                      final company =
                          r['companies']?['company_name'] ?? 'Unassigned';
                      final waste = r['waste_type'] ?? 'Unknown';
                      final date = _formatDate(r['pickup_date']);
                      final region = r['region'] ?? '';
                      final town = r['town'] ?? '';
                      final status = (r['status'] ?? 'pending').toString();
                      final step = _statusStep(status);

                      final canPay =
                          status.toLowerCase() == 'pending_customer_payment';
                      final canConfirmPickup = status.toLowerCase() == 'paid' ||
                          status.toLowerCase() == 'company_confirmed';

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor(status).withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: _statusColor(status).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status + Company
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      company,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontStyle: FontStyle.italic),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(waste,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('📍 $region, $town',
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text('🗓️ Pickup: $date',
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 14),
                              _buildProgressTimeline(step),
                              const SizedBox(height: 12),

                              // Buttons
                              Row(
                                children: [
                                  if (status.toLowerCase() == 'pending')
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor:
                                                  const Color(0xFF1E1E1E),
                                              title: const Text(
                                                  'Cancel Request?',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                              content: const Text(
                                                  'Are you sure you want to cancel this pickup request?',
                                                  style: TextStyle(
                                                      color: Colors.white70)),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('No',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.white70)),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text(
                                                      'Yes, Cancel',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .redAccent)),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await _cancelBooking(r['id']);
                                          }
                                        },
                                        icon: const Icon(Icons.cancel,
                                            color: Colors.white),
                                        label: const Text('Cancel Request'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  if (canPay) const SizedBox(width: 8),
                                  if (canPay)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Payment button tapped! (Paystack disabled for testing)'),
                                              backgroundColor:
                                                  Colors.orangeAccent,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.payment,
                                            color: Colors.white),
                                        label: const Text('Make Payment'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orangeAccent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (canConfirmPickup)
                                    const SizedBox(width: 8),
                                  if (canConfirmPickup)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor:
                                                  const Color(0xFF1E1E1E),
                                              title: const Text(
                                                  'Confirm Pickup?',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                              content: const Text(
                                                  'Have you received your waste pickup today?',
                                                  style: TextStyle(
                                                      color: Colors.white70)),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('No',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.white70)),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text(
                                                      'Yes, Confirm',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .greenAccent)),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await _confirmPickup(r['id']);
                                          }
                                        },
                                        icon: const Icon(Icons.check_circle,
                                            color: Colors.white),
                                        label: const Text('Confirm Pickup'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.greenAccent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildProgressTimeline(int activeStep) {
    final steps = [
      {'label': 'Pending', 'icon': Icons.hourglass_empty},
      {'label': 'In Progress', 'icon': Icons.sync},
      {'label': 'Customer Confirmed', 'icon': Icons.person},
      {'label': 'Completed', 'icon': Icons.check_circle},
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isEven) {
          final stepIndex = index ~/ 2;
          final isActive = stepIndex < activeStep;

          return Expanded(
            child: Column(
              children: [
                Icon(
                  steps[stepIndex]['icon'] as IconData,
                  color: isActive ? Colors.redAccent : Colors.white24,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  steps[stepIndex]['label'] as String,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white38,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else {
          final lineIndex = (index - 1) ~/ 2;
          final isActive = lineIndex < activeStep - 1;

          return Container(
            width: 20,
            height: 2,
            color:
                isActive ? Colors.redAccent : Colors.white24.withOpacity(0.2),
          );
        }
      }),
    );
  }
}
