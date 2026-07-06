import 'package:flutter/material.dart';

import '../models/room.dart';
import '../services/room_service.dart';

class RoomProvider extends ChangeNotifier {
  final RoomService _service = RoomService();

  List<Room> rooms = [];
  bool isLoading = false;

  Future<void> loadRooms() async {
    isLoading = true;
    notifyListeners();

    try {
      rooms = await _service.getRooms();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRoom(Room room) async {
    await _service.addRoom(room);
    await loadRooms();
  }

  Future<void> updateRoom(Room room) async {
    await _service.updateRoom(room);
    await loadRooms();
  }

  Future<void> deleteRoom(String id) async {
    await _service.deleteRoom(id);
    await loadRooms();
  }

  Future<void> updateBookingStatus(String roomNumber, bool isBooked) async {
    await _service.updateBookingStatus(roomNumber, isBooked);
    await loadRooms();
  }
}