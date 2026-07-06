import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/customer.dart';
import '../../models/room.dart';

import '../../providers/booking_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/room_provider.dart';

enum BookingStatusFilter { all, pending, confirmed, rejected }

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";
  BookingStatusFilter _statusFilter = BookingStatusFilter.all;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<CustomerProvider>().loadCustomers();
      context.read<RoomProvider>().loadRooms();
      context.read<BookingProvider>().loadBookings();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  String formatDate(DateTime? date) {
    if (date == null) return "";
    return DateFormat("dd/MM/yyyy").format(date);
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    try {
      return DateFormat("dd/MM/yyyy").parse(value);
    } catch (_) {
      return null;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "confirmed":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case "confirmed":
        return "Đã duyệt";
      case "rejected":
        return "Đã từ chối";
      default:
        return "Chờ duyệt";
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case "confirmed":
        return Icons.check_circle;
      case "rejected":
        return Icons.cancel;
      default:
        return Icons.hourglass_top;
    }
  }

  List<Booking> _applyFilters(List<Booking> bookings) {
    return bookings.where((booking) {
      final matchesSearch = _searchQuery.isEmpty ||
          booking.customerName.toLowerCase().contains(_searchQuery) ||
          booking.roomNumber.toLowerCase().contains(_searchQuery);

      final matchesFilter = switch (_statusFilter) {
        BookingStatusFilter.all => true,
        BookingStatusFilter.pending => booking.status == "pending",
        BookingStatusFilter.confirmed => booking.status == "confirmed",
        BookingStatusFilter.rejected => booking.status == "rejected",
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  /// Trả về true nếu khoảng [checkIn, checkOut) của phòng [roomNumber]
  /// bị trùng với một booking khác (không tính booking đã bị từ chối).
  bool _hasRoomConflict({
    required String roomNumber,
    required DateTime checkIn,
    required DateTime checkOut,
    String? excludeBookingId,
  }) {
    final bookings = context.read<BookingProvider>().bookings;

    for (final existing in bookings) {
      if (existing.roomNumber != roomNumber) continue;
      if (existing.status == "rejected") continue;
      if (excludeBookingId != null && existing.id == excludeBookingId) {
        continue;
      }

      final existingCheckIn = _parseDate(existing.checkInDate);
      final existingCheckOut = _parseDate(existing.checkOutDate);

      if (existingCheckIn == null || existingCheckOut == null) continue;

      final overlap = checkIn.isBefore(existingCheckOut) &&
          existingCheckIn.isBefore(checkOut);

      if (overlap) return true;
    }

    return false;
  }

  // ---------------------------------------------------------------------
  // Actions (giữ nguyên toàn bộ logic Firebase / Provider)
  // ---------------------------------------------------------------------

  Future<void> _saveBooking({
    Booking? booking,
    required Customer? customer,
    required Room? room,
    required DateTime? checkInDate,
    required DateTime? checkOutDate,
  }) async {
    if (customer == null ||
        room == null ||
        checkInDate == null ||
        checkOutDate == null) {
      _showSnack("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (!checkInDate.isBefore(checkOutDate)) {
      _showSnack("Ngày trả phòng phải sau ngày nhận phòng");
      return;
    }

    if (_hasRoomConflict(
      roomNumber: room.roomNumber,
      checkIn: checkInDate,
      checkOut: checkOutDate,
      excludeBookingId: booking?.id,
    )) {
      _showSnack("Phòng đã được đặt trong khoảng thời gian này");
      return;
    }

    final bookingProvider = context.read<BookingProvider>();

    final nights = checkOutDate.difference(checkInDate).inDays;
    final totalPrice = room.price * (nights > 0 ? nights : 1);

    final data = Booking(
      id: booking?.id,
      customerName: customer.name,
      roomNumber: room.roomNumber,
      checkInDate: formatDate(checkInDate),
      checkOutDate: formatDate(checkOutDate),
      status: booking?.status ?? "pending",
      userId: booking?.userId ?? "",
      totalPrice: totalPrice,
    );

    if (booking == null) {
      await bookingProvider.addBooking(data);
    } else {
      await bookingProvider.updateBooking(data);
    }

    if (!mounted) return;

    Navigator.pop(context);
  }

  Future<void> approveBooking(Booking booking) async {
    final bookingProvider = context.read<BookingProvider>();
    final roomProvider = context.read<RoomProvider>();

    await bookingProvider.updateBooking(
      booking.copyWith(status: "confirmed"),
    );

    await roomProvider.updateBookingStatus(booking.roomNumber, true);

    if (!mounted) return;
    _showSnack("Đã duyệt booking của ${booking.customerName}");
  }

  Future<void> rejectBooking(Booking booking) async {
    final bookingProvider = context.read<BookingProvider>();
    final roomProvider = context.read<RoomProvider>();

    await bookingProvider.updateBooking(
      booking.copyWith(status: "rejected"),
    );

    await roomProvider.updateBookingStatus(booking.roomNumber, false);

    if (!mounted) return;
    _showSnack("Đã từ chối booking của ${booking.customerName}");
  }

  Future<void> deleteBooking(Booking booking) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Xác nhận"),
        content: Text("Xóa booking của ${booking.customerName} ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await context.read<BookingProvider>().deleteBooking(booking.id!);

      await context.read<RoomProvider>().updateBookingStatus(
            booking.roomNumber,
            false,
          );

      if (!mounted) return;
      _showSnack("Đã xóa booking");
    }
  }

  void _showReceiptDialog(Booking booking) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(booking.receiptUrl);
    } catch (_) {
      bytes = null;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Sao kê - ${booking.customerName}"),
        content: bytes == null
            ? const Text("Không đọc được ảnh sao kê")
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(bytes, fit: BoxFit.contain),
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------
  // Dialog tạo / sửa booking
  // ---------------------------------------------------------------------

  void openBookingDialog({Booking? booking}) {
    final customerProvider = context.read<CustomerProvider>();
    final roomProvider = context.read<RoomProvider>();

    Customer? dialogCustomer;
    Room? dialogRoom;
    DateTime? dialogCheckIn;
    DateTime? dialogCheckOut;

    if (booking != null) {
      dialogCustomer = customerProvider.customers
          .where((e) => e.name == booking.customerName)
          .cast<Customer?>()
          .firstWhere((e) => true, orElse: () => null);

      dialogRoom = roomProvider.rooms
          .where((e) => e.roomNumber == booking.roomNumber)
          .cast<Room?>()
          .firstWhere((e) => true, orElse: () => null);

      dialogCheckIn = _parseDate(booking.checkInDate);
      dialogCheckOut = _parseDate(booking.checkOutDate);
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            final rooms = roomProvider.rooms
                .where(
                  (e) => !e.isBooked || e.roomNumber == booking?.roomNumber,
                )
                .toList();

            Future<void> pickCheckIn() async {
              final result = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime(2035),
                initialDate: dialogCheckIn ?? DateTime.now(),
              );

              if (result != null) {
                setDialog(() {
                  dialogCheckIn = result;
                  if (dialogCheckOut != null &&
                      !dialogCheckOut!.isAfter(result)) {
                    dialogCheckOut = null;
                  }
                });
              }
            }

            Future<void> pickCheckOut() async {
              final result = await showDatePicker(
                context: context,
                firstDate: dialogCheckIn ?? DateTime.now(),
                lastDate: DateTime(2035),
                initialDate: dialogCheckOut ??
                    dialogCheckIn ??
                    DateTime.now(),
              );

              if (result != null) {
                setDialog(() {
                  dialogCheckOut = result;
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                booking == null ? "Tạo Booking" : "Cập nhật Booking",
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<Customer>(
                      value: dialogCustomer,
                      decoration: InputDecoration(
                        labelText: "Khách hàng",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: customerProvider.customers
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialog(() {
                          dialogCustomer = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<Room>(
                      value: dialogRoom,
                      decoration: InputDecoration(
                        labelText: "Phòng",
                        prefixIcon: const Icon(Icons.meeting_room_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: rooms
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.roomNumber),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialog(() {
                          dialogRoom = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.login),
                            title: const Text("Ngày nhận phòng"),
                            subtitle: Text(
                              dialogCheckIn == null
                                  ? "Chưa chọn"
                                  : formatDate(dialogCheckIn),
                            ),
                            trailing: const Icon(Icons.calendar_month),
                            onTap: pickCheckIn,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text("Ngày trả phòng"),
                            subtitle: Text(
                              dialogCheckOut == null
                                  ? "Chưa chọn"
                                  : formatDate(dialogCheckOut),
                            ),
                            trailing: const Icon(Icons.calendar_month),
                            onTap: pickCheckOut,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Huỷ"),
                ),
                FilledButton(
                  onPressed: () {
                    _saveBooking(
                      booking: booking,
                      customer: dialogCustomer,
                      room: dialogRoom,
                      checkInDate: dialogCheckIn,
                      checkOutDate: dialogCheckOut,
                    );
                  },
                  child: Text(booking == null ? "Thêm" : "Lưu"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final filteredBookings = _applyFilters(bookingProvider.bookings);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Booking"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openBookingDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Tạo booking"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Tìm theo tên khách hoặc số phòng",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchController.clear,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("Tất cả", BookingStatusFilter.all),
                  const SizedBox(width: 8),
                  _buildFilterChip("Chờ duyệt", BookingStatusFilter.pending),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "Đã duyệt",
                    BookingStatusFilter.confirmed,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "Đã từ chối",
                    BookingStatusFilter.rejected,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredBookings.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(filteredBookings[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, BookingStatusFilter filter) {
    final selected = _statusFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _statusFilter = filter;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            "Không có booking nào",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final statusColor = getStatusColor(booking.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Icon(Icons.hotel, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Phòng ${booking.roomNumber}",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(booking.status),
                        color: statusColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getStatusText(booking.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.login,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text("Nhận: ${booking.checkInDate}"),
                const SizedBox(width: 16),
                Icon(
                  Icons.logout,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text("Trả: ${booking.checkOutDate}"),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Tổng tiền: ${NumberFormat("#,###", "vi").format(booking.totalPrice)}đ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (booking.receiptUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showReceiptDialog(booking),
                    icon: const Icon(Icons.receipt_long_outlined,
                        color: Colors.blueGrey),
                    label: const Text(
                      "Xem sao kê",
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                if (booking.status == "pending") ...[
                  TextButton.icon(
                    onPressed: () => approveBooking(booking),
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text(
                      "Duyệt",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => rejectBooking(booking),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      "Từ chối",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => openBookingDialog(booking: booking),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteBooking(booking),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}