import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _service = BookingService();

  List<Booking> bookings = [];
  bool isLoading = false;

  Future<void> loadBookings() async {
    isLoading = true;
    notifyListeners();

    try {
      bookings = await _service.getBookings();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Trả về id của booking vừa tạo (dùng để mở màn hình thanh toán ngay
  /// sau khi đặt phòng).
  Future<String> addBooking(Booking booking) async {
    final id = await _service.addBooking(booking);
    await loadBookings();
    return id;
  }

  Future<void> updateBooking(Booking booking) async {
    await _service.updateBooking(booking);
    await loadBookings();
  }

  Future<void> deleteBooking(String id) async {
    await _service.deleteBooking(id);
    await loadBookings();
  }
}