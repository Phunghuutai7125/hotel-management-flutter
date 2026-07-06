import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_theme.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<BookingProvider>().loadBookings();
    });
  }

  Color statusColor(String status) {
    switch (status) {
      case "confirmed":
        return const Color(0xFF22C55E);
      case "checked_in":
        return const Color(0xFF2563EB);
      case "checked_out":
        return const Color(0xFF64748B);
      case "rejected":
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String statusText(String status) {
    switch (status) {
      case "confirmed":
        return "Đã duyệt";
      case "checked_in":
        return "Đang ở";
      case "checked_out":
        return "Đã trả phòng";
      case "rejected":
        return "Đã từ chối";
      default:
        return "Chờ duyệt";
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case "confirmed":
        return Icons.check_circle_outline;
      case "checked_in":
        return Icons.login_rounded;
      case "checked_out":
        return Icons.task_alt_rounded;
      case "rejected":
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Future<void> deleteBooking(Booking booking) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xác nhận"),
        content: const Text("Huỷ booking này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Không"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Huỷ Booking"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await context.read<BookingProvider>().deleteBooking(booking.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context
        .watch<BookingProvider>()
        .bookings
        .where((e) => e.userId == FirebaseAuth.instance.currentUser!.uid)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // -------------------------------------------------------
            // Header gradient
            // -------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Lịch sử đặt phòng",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy_rounded,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            "Bạn chưa có booking nào",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final color = statusColor(booking.status);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.hotel_rounded,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Phòng ${booking.roomNumber}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          booking.customerName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon(booking.status),
                                            size: 13, color: color),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusText(booking.status),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 26),
                              Row(
                                children: [
                                  Icon(Icons.login,
                                      size: 16, color: Colors.grey.shade500),
                                  const SizedBox(width: 6),
                                  Text(booking.checkInDate),
                                  const SizedBox(width: 20),
                                  Icon(Icons.logout,
                                      size: 16, color: Colors.grey.shade500),
                                  const SizedBox(width: 6),
                                  Text(booking.checkOutDate),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "${NumberFormat("#,###", "vi").format(booking.totalPrice)}đ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              if (booking.status == "pending") ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    label: const Text(
                                      "Huỷ Booking",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => deleteBooking(booking),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}