// lib/services/booking_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class BookingService {

  // ================================================================
  // ✅ Create a new booking (customer auto-resolved)
  // ================================================================
  static Future<void> createBooking({
    required String wasteType,
    required String region,
    required String town,
    String? companyId, // optional
    required DateTime pickupDate,
    required String wasteDetail,
    required double amountDue,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      print("AUTH USER ID: ${user.id}");

      // 1️⃣ Fetch the customer row using auth_user_id
      final customerResponse = await supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', user.id)
          .single();

      if (customerResponse.isEmpty) {
        throw Exception("No customer profile found for this user.");
      }

      final String customerId = customerResponse['id'];
      print("Resolved CUSTOMER ID (UUID): $customerId");

      // 2️⃣ Insert booking with correct UUID
      final insertResponse = await supabase
          .from('bookings')
          .insert({
            'customer_id': customerId,
            'waste_type': wasteType,
            'region': region,
            'town': town,
            'company_id': companyId,
            'pickup_date': pickupDate.toIso8601String(),
            'waste_detail': wasteDetail,
            'amount_due': amountDue,
            'status': 'pending_company_accept',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select();

      print('Booking created successfully: $insertResponse');

    } catch (e) {
      print('❌ Error creating booking: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  // ================================================================
  // ✅ Fetch bookings for the logged-in customer
  // ================================================================
  static Future<List<Map<String, dynamic>>> getBookingsByCustomer() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      print('LOGGED IN CUSTOMER auth_user_id: ${user.id}');

      // 1️⃣ Fetch customer.id from customers table
      final customerResponse = await supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', user.id)
          .single();

      if (customerResponse.isEmpty) {
        throw Exception("Customer profile not found.");
      }

      final String customerId = customerResponse['id'];
      print('Resolved customerId: $customerId');

      // 2️⃣ Fetch bookings for this customer
      final bookingsResponse = await supabase
          .from('bookings')
          .select()
          .eq('customer_id', customerId)
          .order('pickup_date', ascending: true);

      final bookings = List<Map<String, dynamic>>.from(bookingsResponse);

      print('Fetched ${bookings.length} bookings:');
      for (var b in bookings) {
        print(b);
      }

      return bookings;

    } catch (e) {
      print('❌ Error fetching bookings: $e');
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  // ================================================================
  // ✅ Update booking status
  // ================================================================
  static Future<void> updateBookingStatus(
      String bookingId, String status) async {
    try {
      final response = await supabase
          .from('bookings')
          .update({'status': status})
          .eq('id', bookingId);

      print('Booking $bookingId updated to status: $status');
      print('Response: $response');

    } catch (e) {
      print('❌ Error updating booking status: $e');
      throw Exception('Failed to update booking status: $e');
    }
  }

  // ================================================================
  // ✅ Delete booking
  // ================================================================
  static Future<void> deleteBooking(String bookingId) async {
    try {
      final response =
          await supabase.from('bookings').delete().eq('id', bookingId);

      print('Booking $bookingId deleted');
      print('Response: $response');

    } catch (e) {
      print('❌ Error deleting booking: $e');
      throw Exception('Failed to delete booking: $e');
    }
  }
}
