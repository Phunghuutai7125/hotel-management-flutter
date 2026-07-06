import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/room.dart';
import '../../providers/room_provider.dart';

import '../../widgets/admin_nav.dart';
import '../../theme/admin_colors.dart';

enum _RoomFilter { all, trong, dangThue, choDon, baoTri }

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  _RoomFilter _filter = _RoomFilter.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<RoomProvider>().loadRooms();
    });
  }

  final roomController = TextEditingController();
  final typeController = TextEditingController();
  final priceController = TextEditingController();
  final imageUrlController = TextEditingController();
  final descriptionController = TextEditingController();
  final floorController = TextEditingController();

  @override
  void dispose() {
    roomController.dispose();
    typeController.dispose();
    priceController.dispose();
    imageUrlController.dispose();
    descriptionController.dispose();
    floorController.dispose();
    super.dispose();
  }

  String _formatMoney(double value) {
    return "${NumberFormat("#,###", "vi").format(value)}đ";
  }

  Color _statusColor(String status) {
    switch (status) {
      case RoomStatus.dangThue:
        return AdminColors.red;
      case RoomStatus.choDon:
        return AdminColors.orange;
      case RoomStatus.baoTri:
        return AdminColors.grey;
      default:
        return AdminColors.green;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case RoomStatus.dangThue:
        return "Đang thuê";
      case RoomStatus.choDon:
        return "Chờ dọn";
      case RoomStatus.baoTri:
        return "Bảo trì";
      default:
        return "Trống";
    }
  }

  bool _matchesFilter(Room room) {
    switch (_filter) {
      case _RoomFilter.all:
        return true;
      case _RoomFilter.trong:
        return room.effectiveStatus == RoomStatus.trong;
      case _RoomFilter.dangThue:
        return room.effectiveStatus == RoomStatus.dangThue;
      case _RoomFilter.choDon:
        return room.effectiveStatus == RoomStatus.choDon;
      case _RoomFilter.baoTri:
        return room.effectiveStatus == RoomStatus.baoTri;
    }
  }

  // ---------------------------------------------------------------------
  // Dialog thêm / sửa phòng
  // ---------------------------------------------------------------------

  void showRoomDialog({Room? room}) {
    if (room != null) {
      roomController.text = room.roomNumber;
      typeController.text = room.type;
      priceController.text = room.price.toString();
      imageUrlController.text = room.imageUrl;
      descriptionController.text = room.description;
      floorController.text = room.floor.toString();
    } else {
      roomController.clear();
      typeController.clear();
      priceController.clear();
      imageUrlController.clear();
      descriptionController.clear();
      floorController.text = "1";
    }

    String previewUrl = room?.imageUrl ?? '';
    String manualStatus = (room?.status == RoomStatus.choDon ||
            room?.status == RoomStatus.baoTri)
        ? room!.status
        : RoomStatus.trong;
    final selectedAmenities = <String>{...(room?.amenities ?? const [])};

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              backgroundColor: AdminColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AdminColors.border),
              ),
              title: Text(
                room == null ? "Thêm phòng" : "Cập nhật phòng",
                style: const TextStyle(color: AdminColors.textPrimary),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _darkField(
                              controller: roomController,
                              label: "Số phòng",
                              icon: Icons.tag,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _darkField(
                              controller: floorController,
                              label: "Tầng",
                              icon: Icons.layers_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _darkField(
                        controller: typeController,
                        label: "Loại phòng",
                        icon: Icons.category_outlined,
                      ),
                      const SizedBox(height: 15),
                      _darkField(
                        controller: priceController,
                        label: "Giá (VNĐ/đêm)",
                        icon: Icons.attach_money,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: manualStatus,
                        dropdownColor: AdminColors.card,
                        style: const TextStyle(color: AdminColors.textPrimary),
                        decoration: _darkDecoration(
                          label: "Trạng thái",
                          icon: Icons.toggle_on_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: RoomStatus.trong,
                            child: Text("Trống (tự động theo đặt phòng)"),
                          ),
                          DropdownMenuItem(
                            value: RoomStatus.choDon,
                            child: Text("Chờ dọn"),
                          ),
                          DropdownMenuItem(
                            value: RoomStatus.baoTri,
                            child: Text("Bảo trì"),
                          ),
                        ],
                        onChanged: (value) {
                          setDialog(() {
                            manualStatus = value ?? RoomStatus.trong;
                          });
                        },
                      ),
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          "Trạng thái \"Đang thuê\" do hệ thống tự set khi có "
                          "booking được duyệt, không chọn thủ công ở đây.",
                          style: TextStyle(
                            color: AdminColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _darkField(
                        controller: imageUrlController,
                        label: "Link ảnh phòng (tuỳ chọn)",
                        icon: Icons.image_outlined,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            final url = imageUrlController.text.trim();
                            setDialog(() {
                              previewUrl = url;
                            });
                          },
                          icon: const Icon(Icons.visibility_outlined,
                              color: AdminColors.gold),
                          label: const Text(
                            "Xem trước ảnh",
                            style: TextStyle(color: AdminColors.gold),
                          ),
                        ),
                      ),
                      if (previewUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            previewUrl,
                            key: ValueKey(previewUrl),
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                height: 130,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stack) {
                              return Container(
                                height: 130,
                                alignment: Alignment.center,
                                color: AdminColors.cardAlt,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AdminColors.textSecondary,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 15),
                      _darkField(
                        controller: descriptionController,
                        label: "Giới thiệu phòng",
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Tiện ích",
                        style: TextStyle(
                          color: AdminColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: RoomAmenities.all.map((a) {
                          final selected = selectedAmenities.contains(a);
                          return _amenityToggle(
                            label: a,
                            selected: selected,
                            onTap: () {
                              setDialog(() {
                                if (selected) {
                                  selectedAmenities.remove(a);
                                } else {
                                  selectedAmenities.add(a);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Huỷ"),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.gold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final roomNumber = roomController.text.trim();
                    final type = typeController.text.trim();
                    final priceText = priceController.text.trim();
                    final imageUrl = imageUrlController.text.trim();
                    final description = descriptionController.text.trim();
                    final floor = int.tryParse(floorController.text.trim());

                    if (roomNumber.isEmpty ||
                        type.isEmpty ||
                        priceText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Vui lòng nhập đầy đủ thông tin"),
                        ),
                      );
                      return;
                    }

                    final price = double.tryParse(priceText);
                    if (price == null || price < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Giá phòng không hợp lệ"),
                        ),
                      );
                      return;
                    }

                    final provider = context.read<RoomProvider>();

                    final newRoom = Room(
                      id: room?.id,
                      roomNumber: roomNumber,
                      type: type,
                      price: price,
                      isBooked: room?.isBooked ?? false,
                      imageUrl: imageUrl,
                      floor: floor ?? (room?.floor ?? 1),
                      status: manualStatus,
                      description: description,
                      amenities: selectedAmenities.toList(),
                    );

                    if (room == null) {
                      await provider.addRoom(newRoom);
                    } else {
                      await provider.updateRoom(newRoom);
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: Text(room == null ? "Thêm" : "Lưu"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _amenityToggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AdminColors.gold.withValues(alpha: 0.2)
              : AdminColors.cardAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AdminColors.gold : AdminColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 14, color: AdminColors.gold),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AdminColors.gold : AdminColors.textPrimary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _darkField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AdminColors.textPrimary),
      decoration: _darkDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _darkDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AdminColors.textSecondary),
      prefixIcon: Icon(icon, color: AdminColors.textSecondary),
      filled: true,
      fillColor: AdminColors.cardAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminColors.gold, width: 1.5),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Xem chi tiết phòng
  // ---------------------------------------------------------------------

  void _showRoomDetail(Room room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AdminColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (room.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      room.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        height: 180,
                        color: AdminColors.cardAlt,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      "Phòng ${room.roomNumber}",
                      style: const TextStyle(
                        color: AdminColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(room.effectiveStatus)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(room.effectiveStatus),
                        style: TextStyle(
                          color: _statusColor(room.effectiveStatus),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "${room.type} • Tầng ${room.floor}",
                  style: const TextStyle(color: AdminColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  "${_formatMoney(room.price)}/đêm",
                  style: const TextStyle(
                    color: AdminColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                if (room.description.isNotEmpty) ...[
                  const Text(
                    "Giới thiệu",
                    style: TextStyle(
                      color: AdminColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    room.description,
                    style: const TextStyle(color: AdminColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                ],
                if (room.amenities.isNotEmpty) ...[
                  const Text(
                    "Tiện ích",
                    style: TextStyle(
                      color: AdminColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: room.amenities
                        .map(
                          (a) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AdminColors.cardAlt,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: AdminColors.border),
                            ),
                            child: Text(
                              a,
                              style: const TextStyle(
                                color: AdminColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          deleteRoom(room);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminColors.red,
                          side: const BorderSide(color: AdminColors.red),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Xoá"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showRoomDialog(room: room);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AdminColors.gold,
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text("Sửa"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteRoom(Room room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AdminColors.border),
        ),
        title: const Text("Xoá", style: TextStyle(color: AdminColors.textPrimary)),
        content: Text(
          "Xoá phòng ${room.roomNumber} ?",
          style: const TextStyle(color: AdminColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Huỷ"),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: AdminColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xoá"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await context.read<RoomProvider>().deleteRoom(room.id!);
    }
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoomProvider>();
    final rooms = provider.rooms;

    final counts = {
      _RoomFilter.all: rooms.length,
      _RoomFilter.trong: rooms
          .where((r) => r.effectiveStatus == RoomStatus.trong)
          .length,
      _RoomFilter.dangThue: rooms
          .where((r) => r.effectiveStatus == RoomStatus.dangThue)
          .length,
      _RoomFilter.choDon: rooms
          .where((r) => r.effectiveStatus == RoomStatus.choDon)
          .length,
      _RoomFilter.baoTri: rooms
          .where((r) => r.effectiveStatus == RoomStatus.baoTri)
          .length,
    };

    final filteredRooms = rooms.where(_matchesFilter).toList()
      ..sort((a, b) {
        final floorCompare = a.floor.compareTo(b.floor);
        if (floorCompare != 0) return floorCompare;
        return a.roomNumber.compareTo(b.roomNumber);
      });

    final Map<int, List<Room>> byFloor = {};
    for (final room in filteredRooms) {
      byFloor.putIfAbsent(room.floor, () => []).add(room);
    }
    final floors = byFloor.keys.toList()..sort();

    return Theme(
      data: adminDarkTheme,
      child: Scaffold(
        backgroundColor: AdminColors.bg,
        drawer: buildAdminDrawer(context),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AdminColors.gold,
          foregroundColor: Colors.black,
          onPressed: () => showRoomDialog(),
          icon: const Icon(Icons.add),
          label: const Text("Thêm phòng"),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu,
                            color: AdminColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Quản lý phòng",
                            style: TextStyle(
                              color: AdminColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Xem và cập nhật trạng thái các phòng",
                            style: TextStyle(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip("Tất cả", _RoomFilter.all, counts),
                      const SizedBox(width: 8),
                      _filterChip("Trống", _RoomFilter.trong, counts),
                      const SizedBox(width: 8),
                      _filterChip("Đang thuê", _RoomFilter.dangThue, counts),
                      const SizedBox(width: 8),
                      _filterChip("Chờ dọn", _RoomFilter.choDon, counts),
                      const SizedBox(width: 8),
                      _filterChip("Bảo trì", _RoomFilter.baoTri, counts),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredRooms.isEmpty
                        ? const Center(
                            child: Text(
                              "Không có phòng nào",
                              style:
                                  TextStyle(color: AdminColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 96),
                            itemCount: floors.length,
                            itemBuilder: (context, index) {
                              final floor = floors[index];
                              final floorRooms = byFloor[floor]!;

                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      "TẦNG $floor",
                                      style: const TextStyle(
                                        color: AdminColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final crossAxisCount =
                                          (constraints.maxWidth / 220)
                                              .floor()
                                              .clamp(1, 6);
                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 1.3,
                                        ),
                                        itemCount: floorRooms.length,
                                        itemBuilder: (context, i) {
                                          return _buildRoomCard(
                                            floorRooms[i],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(
    String label,
    _RoomFilter filter,
    Map<_RoomFilter, int> counts,
  ) {
    final selected = _filter == filter;
    return ChoiceChip(
      label: Text("$label (${counts[filter] ?? 0})"),
      selected: selected,
      onSelected: (_) => setState(() => _filter = filter),
      backgroundColor: AdminColors.cardAlt,
      selectedColor: AdminColors.gold,
      labelStyle: TextStyle(
        color: selected ? Colors.black : AdminColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide(
        color: selected ? AdminColors.gold : AdminColors.border,
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final statusColor = _statusColor(room.effectiveStatus);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showRoomDetail(room),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AdminColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  room.roomNumber,
                  style: const TextStyle(
                    color: AdminColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AdminColors.textSecondary,
                      ),
                      onPressed: () => showRoomDialog(room: room),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              room.type,
              style: const TextStyle(color: AdminColors.textSecondary),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel(room.effectiveStatus),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${_formatMoney(room.price)}/đêm",
              style: const TextStyle(
                color: AdminColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}