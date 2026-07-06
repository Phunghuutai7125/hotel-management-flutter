/// Các trạng thái hiển thị của phòng (khác với [Room.isBooked] dùng cho
/// logic chặn trùng lịch đặt phòng).
class RoomStatus {
  static const trong = 'trong'; // Trống
  static const dangThue = 'dang_thue'; // Đang thuê
  static const choDon = 'cho_don'; // Chờ dọn
  static const baoTri = 'bao_tri'; // Bảo trì
}

class Room {
  final String? id;
  final String roomNumber;
  final String type;
  final double price;
  final bool isBooked;
  final String imageUrl;

  /// Tầng của phòng. Nếu dữ liệu cũ chưa có field này, sẽ được suy ra
  /// tự động từ số phòng khi đọc (xem [Room.fromMap]).
  final int floor;

  /// Trạng thái do admin đặt thủ công: trống / chờ dọn / bảo trì.
  /// Xem [effectiveStatus] để lấy trạng thái hiển thị thực tế (có ưu
  /// tiên đồng bộ với [isBooked]).
  final String status;

  /// Giới thiệu ngắn về phòng, admin nhập, user xem được.
  final String description;

  /// Danh sách tiện ích được chọn từ [RoomAmenities.all] (hoặc tương tự).
  final List<String> amenities;

  Room({
    this.id,
    required this.roomNumber,
    required this.type,
    required this.price,
    this.isBooked = false,
    this.imageUrl = '',
    this.floor = 1,
    this.status = RoomStatus.trong,
    this.description = '',
    this.amenities = const [],
  });

  /// Trạng thái hiển thị thực tế: nếu admin đã đánh dấu "chờ dọn" hoặc
  /// "bảo trì" thì ưu tiên hiển thị trạng thái đó; ngược lại suy ra từ
  /// [isBooked] (nguồn dữ liệu đáng tin cậy nhất cho biết phòng có đang
  /// được thuê hay không, do hệ thống đặt phòng tự cập nhật).
  String get effectiveStatus {
    if (status == RoomStatus.baoTri || status == RoomStatus.choDon) {
      return status;
    }
    return isBooked ? RoomStatus.dangThue : RoomStatus.trong;
  }

  static int _guessFloorFromRoomNumber(String roomNumber) {
    // Quy ước phổ biến: số phòng "302" -> tầng 3, "1201" -> tầng 12.
    final digitsOnly = roomNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length <= 2) return 1;
    final floorPart = digitsOnly.substring(0, digitsOnly.length - 2);
    return int.tryParse(floorPart) ?? 1;
  }

  factory Room.fromMap(String id, Map<String, dynamic> map) {
    final roomNumber = map['roomNumber']?.toString() ?? '';
    final isBooked = map['isBooked'] as bool? ?? false;

    return Room(
      id: id,
      roomNumber: roomNumber,
      type: map['type']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      isBooked: isBooked,
      imageUrl: map['imageUrl']?.toString() ?? '',
      floor: (map['floor'] as num?)?.toInt() ??
          _guessFloorFromRoomNumber(roomNumber),
      status: map['status']?.toString() ??
          (isBooked ? RoomStatus.dangThue : RoomStatus.trong),
      description: map['description']?.toString() ?? '',
      amenities: (map['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomNumber': roomNumber,
      'type': type,
      'price': price,
      'isBooked': isBooked,
      'imageUrl': imageUrl,
      'floor': floor,
      'status': status,
      'description': description,
      'amenities': amenities,
    };
  }

  Room copyWith({
    String? id,
    String? roomNumber,
    String? type,
    double? price,
    bool? isBooked,
    String? imageUrl,
    int? floor,
    String? status,
    String? description,
    List<String>? amenities,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      type: type ?? this.type,
      price: price ?? this.price,
      isBooked: isBooked ?? this.isBooked,
      imageUrl: imageUrl ?? this.imageUrl,
      floor: floor ?? this.floor,
      status: status ?? this.status,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
    );
  }
}

/// Danh sách tiện ích có sẵn để admin chọn khi tạo/sửa phòng.
class RoomAmenities {
  static const List<String> all = [
    "Giường đơn",
    "Giường đôi",
    "Bồn tắm",
    "Vòi sen",
    "Điều hòa",
    "Wifi miễn phí",
    "Tivi",
    "Tủ lạnh mini",
    "Ban công",
    "View biển",
    "Bàn làm việc",
    "Máy sấy tóc",
  ];
}