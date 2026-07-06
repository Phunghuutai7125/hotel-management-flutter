import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  final String? id;
  final String bookingId;
  final String customerName;
  final String roomNumber;
  final String checkInDate;
  final String checkOutDate;
  final double totalPrice;
  final String userId;
  final DateTime createdAt;

  Invoice({
    this.id,
    required this.bookingId,
    required this.customerName,
    required this.roomNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalPrice,
    this.userId = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Invoice.fromMap(String id, Map<String, dynamic> map) {
    return Invoice(
      id: id,
      bookingId: map['bookingId']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      roomNumber: map['roomNumber']?.toString() ?? '',
      checkInDate: map['checkInDate']?.toString() ?? '',
      checkOutDate: map['checkOutDate']?.toString() ?? '',
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      userId: map['userId']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'customerName': customerName,
      'roomNumber': roomNumber,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'totalPrice': totalPrice,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}