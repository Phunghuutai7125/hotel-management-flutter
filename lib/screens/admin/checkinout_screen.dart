import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/invoice.dart';

import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/invoice_provider.dart';

enum _CheckFilter { waitingCheckIn, staying }

class CheckInOutScreen extends StatefulWidget {
  const CheckInOutScreen({super.key});

  @override
  State<CheckInOutScreen> createState() => _CheckInOutScreenState();
}

class _CheckInOutScreenState extends State<CheckInOutScreen> {
  _CheckFilter _filter = _CheckFilter.waitingCheckIn;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<BookingProvider>().loadBookings();
    });
  }

  Future<void> _checkIn(Booking booking) async {
    await context.read<BookingProvider>().updateBooking(
          booking.copyWith(status: 'checked_in'),
        );

    if (!mounted) return;
    _showSnack('Đã nhận phòng cho ${booking.customerName}');
  }

  Future<void> _checkOut(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận trả phòng'),
        content: Text(
          'Trả phòng ${booking.roomNumber} cho ${booking.customerName}?\n'
          'Hệ thống sẽ tự động lập hóa đơn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 1. Lập hóa đơn dựa trên booking
    final invoice = Invoice(
      bookingId: booking.id!,
      customerName: booking.customerName,
      roomNumber: booking.roomNumber,
      checkInDate: booking.checkInDate,
      checkOutDate: booking.checkOutDate,
      totalPrice: booking.totalPrice,
      userId: booking.userId,
    );
    await context.read<InvoiceProvider>().addInvoice(invoice);

    // 2. Cập nhật trạng thái booking
    await context.read<BookingProvider>().updateBooking(
          booking.copyWith(status: 'checked_out'),
        );

    // 3. Giải phóng phòng (phòng trống trở lại)
    await context.read<RoomProvider>().updateBookingStatus(
          booking.roomNumber,
          false,
        );

    if (!mounted) return;
    _showSnack('Đã trả phòng và lập hóa đơn cho ${booking.customerName}');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>().bookings;

    final waitingCheckIn =
        bookings.where((b) => b.status == 'confirmed').toList();
    final staying = bookings.where((b) => b.status == 'checked_in').toList();

    final list =
        _filter == _CheckFilter.waitingCheckIn ? waitingCheckIn : staying;

    return Scaffold(
      appBar: AppBar(title: const Text('Nhận / Trả phòng')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('Chờ nhận phòng (${waitingCheckIn.length})'),
                    selected: _filter == _CheckFilter.waitingCheckIn,
                    onSelected: (_) {
                      setState(() => _filter = _CheckFilter.waitingCheckIn);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Đang ở (${staying.length})'),
                    selected: _filter == _CheckFilter.staying,
                    onSelected: (_) {
                      setState(() => _filter = _CheckFilter.staying);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      _filter == _CheckFilter.waitingCheckIn
                          ? 'Không có booking nào chờ nhận phòng'
                          : 'Không có khách nào đang ở',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final booking = list[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.shade50,
                                    child: const Icon(Icons.hotel,
                                        color: Colors.blue),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking.customerName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text('Phòng ${booking.roomNumber}'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.login,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('Nhận: ${booking.checkInDate}'),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.logout,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('Trả: ${booking.checkOutDate}'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tổng tiền: ${NumberFormat("#,###", "vi").format(booking.totalPrice)}đ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: _filter == _CheckFilter.waitingCheckIn
                                    ? FilledButton.icon(
                                        icon: const Icon(Icons.login),
                                        label: const Text('Nhận phòng'),
                                        onPressed: () => _checkIn(booking),
                                      )
                                    : FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        icon: const Icon(Icons.logout),
                                        label: const Text('Trả phòng'),
                                        onPressed: () => _checkOut(booking),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}