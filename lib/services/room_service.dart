import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room.dart';

class RoomService {
  final CollectionReference _ref =
      FirebaseFirestore.instance.collection('rooms');

  Future<List<Room>> getRooms() async {
    final snapshot = await _ref.get();

    return snapshot.docs
        .map(
          (doc) => Room.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> addRoom(Room room) async {
    await _ref.add(room.toMap());
  }

  Future<void> updateRoom(Room room) async {
    if (room.id == null) return;
    await _ref.doc(room.id).update(room.toMap());
  }

  Future<void> deleteRoom(String id) async {
    await _ref.doc(id).delete();
  }

  /// Cập nhật trạng thái đã đặt / còn trống cho phòng dựa theo [roomNumber].
  Future<void> updateBookingStatus(
    String roomNumber,
    bool isBooked,
  ) async {
    final snapshot = await _ref
        .where('roomNumber', isEqualTo: roomNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'isBooked': isBooked,
      });
    }
  }
}