import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';

class BookingService {
  final CollectionReference _ref =
      FirebaseFirestore.instance.collection('bookings');

  Future<List<Booking>> getBookings() async {
    final snapshot = await _ref.get();

    return snapshot.docs
        .map(
          (doc) => Booking.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Trả về id của document vừa tạo, để có thể điều hướng sang màn hình
  /// thanh toán ngay sau khi đặt phòng.
  Future<String> addBooking(Booking booking) async {
    final docRef = await _ref.add(booking.toMap());
    return docRef.id;
  }

  Future<void> updateBooking(Booking booking) async {
    if (booking.id == null) return;
    await _ref.doc(booking.id).update(booking.toMap());
  }

  Future<void> deleteBooking(String id) async {
    await _ref.doc(id).delete();
  }
}