class Booking {
  final String? id;
  final String customerName;
  final String roomNumber;
  final String checkInDate;
  final String checkOutDate;
  final String status;
  final String userId;

  /// Tổng tiền của booking (tính cho toàn bộ số đêm ở).
  /// Mặc định 0 để tương thích với dữ liệu cũ chưa có field này.
  final double totalPrice;

  /// Ảnh sao kê chuyển khoản do user tải lên (lưu dạng base64 data URL).
  /// Rỗng nếu user không tải lên (không bắt buộc).
  final String receiptUrl;

  Booking({
    this.id,
    required this.customerName,
    required this.roomNumber,
    required this.checkInDate,
    required this.checkOutDate,
    this.status = 'pending',
    this.userId = '',
    this.totalPrice = 0,
    this.receiptUrl = '',
  });

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      customerName: map['customerName']?.toString() ?? '',
      roomNumber: map['roomNumber']?.toString() ?? '',
      checkInDate: map['checkInDate']?.toString() ?? '',
      checkOutDate: map['checkOutDate']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      userId: map['userId']?.toString() ?? '',
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      receiptUrl: map['receiptUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'roomNumber': roomNumber,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'status': status,
      'userId': userId,
      'totalPrice': totalPrice,
      'receiptUrl': receiptUrl,
    };
  }

  Booking copyWith({
    String? id,
    String? customerName,
    String? roomNumber,
    String? checkInDate,
    String? checkOutDate,
    String? status,
    String? userId,
    double? totalPrice,
    String? receiptUrl,
  }) {
    return Booking(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      roomNumber: roomNumber ?? this.roomNumber,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      totalPrice: totalPrice ?? this.totalPrice,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }
}