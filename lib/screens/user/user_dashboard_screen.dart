import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/room.dart';

import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';

import '../../theme/app_theme.dart';

import '../auth/login_screen.dart';
import 'booking_history_screen.dart';
import 'payment_screen.dart';
import 'ai_chat_screen.dart';
import 'my_invoices_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  Room? selectedRoom;
  DateTime? checkIn;
  DateTime? checkOut;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<RoomProvider>().loadRooms();
      context.read<BookingProvider>().loadBookings();
    });
  }

  String formatDate(DateTime date) {
    return DateFormat("dd/MM/yyyy").format(date);
  }

  Future<void> pickCheckIn(void Function(void Function()) setDialog) async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (result != null) {
      setDialog(() {
        checkIn = result;
        if (checkOut != null && !checkOut!.isAfter(result)) {
          checkOut = null;
        }
      });
    }
  }

  Future<void> pickCheckOut(void Function(void Function()) setDialog) async {
    if (checkIn == null) return;

    final result = await showDatePicker(
      context: context,
      firstDate: checkIn!,
      lastDate: DateTime(2035),
      initialDate: checkIn!,
    );

    if (result != null) {
      setDialog(() {
        checkOut = result;
      });
    }
  }

  Future<void> createBooking(void Function(void Function()) setDialog) async {
    if (selectedRoom == null || checkIn == null || checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    if (!checkIn!.isBefore(checkOut!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ngày trả phòng phải sau ngày nhận phòng"),
        ),
      );
      return;
    }

    final nights = checkOut!.difference(checkIn!).inDays;
    final totalPrice = selectedRoom!.price * (nights > 0 ? nights : 1);

    final room = selectedRoom!;

    final booking = Booking(
      customerName: FirebaseAuth.instance.currentUser?.email ?? "User",
      roomNumber: room.roomNumber,
      checkInDate: formatDate(checkIn!),
      checkOutDate: formatDate(checkOut!),
      status: "pending",
      userId: FirebaseAuth.instance.currentUser!.uid,
      totalPrice: totalPrice,
    );

    final newId = await context.read<BookingProvider>().addBooking(booking);

    if (!mounted) return;

    Navigator.pop(context); // đóng bottom sheet chọn phòng

    setState(() {
      selectedRoom = null;
      checkIn = null;
      checkOut = null;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          booking: booking.copyWith(id: newId),
          room: room,
        ),
      ),
    );
  }

  void _showRoomInfoDialog(BuildContext context, Room room) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Phòng ${room.roomNumber} - ${room.type}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (room.description.isNotEmpty) ...[
                const Text(
                  "Giới thiệu",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(room.description),
                const SizedBox(height: 12),
              ],
              if (room.amenities.isNotEmpty) ...[
                const Text(
                  "Tiện ích",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: room.amenities
                      .map((a) => Chip(label: Text(a)))
                      .toList(),
                ),
              ],
              if (room.description.isEmpty && room.amenities.isEmpty)
                const Text("Chưa có thông tin chi tiết cho phòng này."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  void openBookingDialog() {
    selectedRoom = null;
    checkIn = null;
    checkOut = null;

    final rooms =
        context.read<RoomProvider>().rooms.where((e) => !e.isBooked).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 25,
                bottom: MediaQuery.of(context).viewInsets.bottom + 25,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "ĐẶT PHÒNG",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Chọn phòng",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (rooms.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            "Hiện không còn phòng trống",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 190,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: rooms.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            final isSelected =
                                selectedRoom?.id == room.id;

                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setDialog(() {
                                      selectedRoom = room;
                                    });
                                  },
                                  child: Container(
                                width: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 90,
                                      width: double.infinity,
                                      child: room.imageUrl.isNotEmpty
                                          ? Image.network(
                                              room.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stack) {
                                                return Container(
                                                  color:
                                                      Colors.grey.shade200,
                                                  alignment:
                                                      Alignment.center,
                                                  child: const Icon(
                                                    Icons
                                                        .broken_image_outlined,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey.shade200,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.hotel,
                                                color: Colors.grey,
                                              ),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Phòng ${room.roomNumber}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            room.type,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            "${room.price.toStringAsFixed(0)} VNĐ",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                          if (room.amenities.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              room.amenities.take(2).join(" • "),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _showRoomInfoDialog(context, room),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: Colors.grey.shade100,
                      leading: const Icon(Icons.login, color: Colors.green),
                      title: Text(
                        checkIn == null
                            ? "Chọn ngày nhận phòng"
                            : formatDate(checkIn!),
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () => pickCheckIn(setDialog),
                    ),
                    const SizedBox(height: 15),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: Colors.grey.shade100,
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        checkOut == null
                            ? "Chọn ngày trả phòng"
                            : formatDate(checkOut!),
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () => pickCheckOut(setDialog),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.book_online),
                          label: const Text("Đặt phòng"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => createBooking(setDialog),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildMenu({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc muốn đăng xuất?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Huỷ"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.email?.split('@').first ?? "bạn";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------
              // Header gradient chào mừng
              // ---------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Xin chào 👋",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user?.email ?? "",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // ---------------------------------------------------
              // Menu
              // ---------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dịch vụ của bạn",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    buildMenu(
                      icon: Icons.hotel_rounded,
                      title: "Đặt phòng",
                      subtitle: "Chọn phòng và đặt ngay",
                      color: const Color(0xFF2563EB),
                      onTap: openBookingDialog,
                    ),
                    buildMenu(
                      icon: Icons.history_rounded,
                      title: "Lịch sử đặt phòng",
                      subtitle: "Theo dõi các booking đã đặt",
                      color: const Color(0xFFF97316),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookingHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    buildMenu(
                      icon: Icons.receipt_long_rounded,
                      title: "Hóa đơn của tôi",
                      subtitle: "Xem lại các hóa đơn đã thanh toán",
                      color: const Color(0xFF14B8A6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyInvoicesScreen(),
                          ),
                        );
                      },
                    ),
                    buildMenu(
                      icon: Icons.smart_toy_rounded,
                      title: "Hỏi trợ lý AI",
                      subtitle: "Tư vấn nhanh mọi thắc mắc",
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiChatScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          "Đăng xuất",
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _logout,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}