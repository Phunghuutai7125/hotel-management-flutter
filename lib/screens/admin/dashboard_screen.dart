import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/room.dart';
import '../../models/booking.dart';

import '../../providers/room_provider.dart';
import '../../providers/booking_provider.dart';

import '../../widgets/admin_nav.dart';
import '../../theme/admin_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<RoomProvider>().loadRooms();
      context.read<BookingProvider>().loadBookings();
    });
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    try {
      return DateFormat("dd/MM/yyyy").parse(value);
    } catch (_) {
      return null;
    }
  }

  String _formatMoney(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M₫";
    }
    final formatted = NumberFormat("#,###", "vi").format(value);
    return "${formatted}đ";
  }

  Color _roomStatusColor(String status) {
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

  String _roomStatusLabel(String status) {
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

  Color _bookingStatusColor(String status) {
    switch (status) {
      case "confirmed":
        return AdminColors.green;
      case "rejected":
        return AdminColors.red;
      default:
        return AdminColors.orange;
    }
  }

  String _bookingStatusLabel(String status) {
    switch (status) {
      case "confirmed":
        return "Đang ở";
      case "rejected":
        return "Đã huỷ";
      default:
        return "Chờ xác nhận";
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<RoomProvider>().rooms;
    final bookings = context.watch<BookingProvider>().bookings;

    // -----------------------------------------------------------------
    // Thống kê phòng
    // -----------------------------------------------------------------
    final totalRooms = rooms.length;
    final emptyRooms =
        rooms.where((r) => r.effectiveStatus == RoomStatus.trong).length;
    final occupiedRooms =
        rooms.where((r) => r.effectiveStatus == RoomStatus.dangThue).length;
    final cleaningRooms =
        rooms.where((r) => r.effectiveStatus == RoomStatus.choDon).length;
    final maintenanceRooms =
        rooms.where((r) => r.effectiveStatus == RoomStatus.baoTri).length;
    final occupancyRate =
        totalRooms == 0 ? 0.0 : (occupiedRooms / totalRooms) * 100;

    // -----------------------------------------------------------------
    // Thống kê booking / doanh thu
    // -----------------------------------------------------------------
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final activeToday = bookings.where((b) {
      if (b.status != "confirmed") return false;
      final ci = _parseDate(b.checkInDate);
      final co = _parseDate(b.checkOutDate);
      if (ci == null || co == null) return false;
      return !todayOnly.isBefore(ci) && todayOnly.isBefore(co);
    }).toList();

    final guestsStaying = activeToday.length;
    final pendingCount = bookings.where((b) => b.status == "pending").length;

    double revenueToday = 0;
    for (final b in activeToday) {
      final ci = _parseDate(b.checkInDate)!;
      final co = _parseDate(b.checkOutDate)!;
      final nights = co.difference(ci).inDays;
      revenueToday += nights > 0 ? b.totalPrice / nights : b.totalPrice;
    }

    // Doanh thu 7 tháng gần nhất (gồm tháng hiện tại), tính theo tháng
    // nhận phòng của các booking đã được duyệt hoặc đã trả phòng.
    final months = List.generate(
      7,
      (i) => DateTime(today.year, today.month - 6 + i, 1),
    );
    final revenueByMonth = List<double>.filled(7, 0);
    for (final b in bookings) {
      if (b.status != "confirmed" && b.status != "checked_out") continue;
      final ci = _parseDate(b.checkInDate);
      if (ci == null) continue;
      for (var i = 0; i < months.length; i++) {
        if (ci.year == months[i].year && ci.month == months[i].month) {
          revenueByMonth[i] += b.totalPrice;
        }
      }
    }
    final maxRevenue = revenueByMonth.fold<double>(
      0,
      (prev, e) => e > prev ? e : prev,
    );
    final chartMaxY = maxRevenue <= 0 ? 100.0 : maxRevenue * 1.25;

    // Booking gần đây: sắp theo ngày nhận phòng gần nhất trước.
    final recentBookings = [...bookings]..sort((a, b) {
        final da = _parseDate(a.checkInDate);
        final db = _parseDate(b.checkInDate);
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });
    final recentTop = recentBookings.take(8).toList();

    return Theme(
      data: adminDarkTheme,
      child: Scaffold(
        backgroundColor: AdminColors.bg,
        drawer: buildAdminDrawer(context),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, pendingCount),
                    const SizedBox(height: 24),
                    _buildStatCards(
                      isWide: isWide,
                      totalRooms: totalRooms,
                      emptyRooms: emptyRooms,
                      occupancyRate: occupancyRate,
                      occupiedRooms: occupiedRooms,
                      guestsStaying: guestsStaying,
                      pendingCount: pendingCount,
                      revenueToday: revenueToday,
                    ),
                    const SizedBox(height: 24),
                    isWide
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildRevenueChart(
                                    months: months,
                                    revenueByMonth: revenueByMonth,
                                    chartMaxY: chartMaxY,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildRoomStatusDonut(
                                    emptyRooms: emptyRooms,
                                    occupiedRooms: occupiedRooms,
                                    cleaningRooms: cleaningRooms,
                                    maintenanceRooms: maintenanceRooms,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              _buildRevenueChart(
                                months: months,
                                revenueByMonth: revenueByMonth,
                                chartMaxY: chartMaxY,
                              ),
                              const SizedBox(height: 20),
                              _buildRoomStatusDonut(
                                emptyRooms: emptyRooms,
                                occupiedRooms: occupiedRooms,
                                cleaningRooms: cleaningRooms,
                                maintenanceRooms: maintenanceRooms,
                              ),
                            ],
                          ),
                    const SizedBox(height: 24),
                    _buildRecentBookings(recentTop),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, int pendingCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu, color: AdminColors.textPrimary),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tổng quan",
                style: TextStyle(
                  color: AdminColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Theo dõi tổng quan hoạt động khách sạn",
                style: TextStyle(color: AdminColors.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          DateFormat("yyyy-MM-dd").format(DateTime.now()),
          style: const TextStyle(color: AdminColors.textSecondary),
        ),
        const SizedBox(width: 16),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: AdminColors.textPrimary,
            ),
            if (pendingCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AdminColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$pendingCount",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Stat cards
  // ---------------------------------------------------------------------

  Widget _buildStatCards({
    required bool isWide,
    required int totalRooms,
    required int emptyRooms,
    required double occupancyRate,
    required int occupiedRooms,
    required int guestsStaying,
    required int pendingCount,
    required double revenueToday,
  }) {
    final cards = [
      _StatCardData(
        icon: Icons.hotel_outlined,
        title: "Tổng số phòng",
        value: "$totalRooms",
        subtitle: "$emptyRooms phòng trống",
      ),
      _StatCardData(
        icon: Icons.check_circle_outline,
        title: "Tỉ lệ lấp đầy",
        value: "${occupancyRate.toStringAsFixed(0)}%",
        subtitle: "$occupiedRooms/$totalRooms phòng",
      ),
      _StatCardData(
        icon: Icons.people_alt_outlined,
        title: "Khách đang ở",
        value: "$guestsStaying",
        subtitle: "$pendingCount đặt chờ",
      ),
      _StatCardData(
        icon: Icons.attach_money,
        title: "Doanh thu hôm nay",
        value: _formatMoney(revenueToday),
        subtitle: "Ước tính theo đêm",
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildStatCard(c),
                ),
              ),
            )
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: cards.map(_buildStatCard).toList(),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: AdminColors.gold, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.value,
            style: const TextStyle(
              color: AdminColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            style: const TextStyle(
              color: AdminColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Biểu đồ doanh thu 7 tháng
  // ---------------------------------------------------------------------

  Widget _buildRevenueChart({
    required List<DateTime> months,
    required List<double> revenueByMonth,
    required double chartMaxY,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Doanh thu 7 tháng",
            style: TextStyle(
              color: AdminColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                maxY: chartMaxY,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AdminColors.cardAlt,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        _formatMoney(rod.toY),
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatMoney(value),
                          style: const TextStyle(
                            color: AdminColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "T${months[index].month}",
                            style: const TextStyle(
                              color: AdminColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY / 4,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AdminColors.border,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: List.generate(months.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: revenueByMonth[i],
                        color: AdminColors.gold,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Donut trạng thái phòng
  // ---------------------------------------------------------------------

  Widget _buildRoomStatusDonut({
    required int emptyRooms,
    required int occupiedRooms,
    required int cleaningRooms,
    required int maintenanceRooms,
  }) {
    final total =
        emptyRooms + occupiedRooms + cleaningRooms + maintenanceRooms;

    final entries = [
      (_roomStatusLabel(RoomStatus.trong), emptyRooms,
          _roomStatusColor(RoomStatus.trong)),
      (_roomStatusLabel(RoomStatus.dangThue), occupiedRooms,
          _roomStatusColor(RoomStatus.dangThue)),
      (_roomStatusLabel(RoomStatus.choDon), cleaningRooms,
          _roomStatusColor(RoomStatus.choDon)),
      (_roomStatusLabel(RoomStatus.baoTri), maintenanceRooms,
          _roomStatusColor(RoomStatus.baoTri)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Trạng thái phòng",
            style: TextStyle(
              color: AdminColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: total == 0
                ? const Center(
                    child: Text(
                      "Chưa có dữ liệu phòng",
                      style: TextStyle(color: AdminColors.textSecondary),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 45,
                      sections: entries
                          .where((e) => e.$2 > 0)
                          .map(
                            (e) => PieChartSectionData(
                              value: e.$2.toDouble(),
                              color: e.$3,
                              radius: 26,
                              showTitle: false,
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          ...entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: e.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.$1,
                      style: const TextStyle(
                        color: AdminColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    "${e.$2}",
                    style: const TextStyle(
                      color: AdminColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Đặt phòng gần đây
  // ---------------------------------------------------------------------

  Widget _buildRecentBookings(List<Booking> bookings) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Text(
                "Đặt phòng gần đây",
                style: TextStyle(
                  color: AdminColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${bookings.length} tổng cộng",
                style: const TextStyle(color: AdminColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "Chưa có booking nào",
                  style: TextStyle(color: AdminColors.textSecondary),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AdminColors.cardAlt,
                ),
                dataRowColor: WidgetStateProperty.all(Colors.transparent),
                columns: const [
                  DataColumn(
                    label: Text(
                      "PHÒNG",
                      style: TextStyle(color: AdminColors.textSecondary),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "KHÁCH HÀNG",
                      style: TextStyle(color: AdminColors.textSecondary),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "NHẬN PHÒNG",
                      style: TextStyle(color: AdminColors.textSecondary),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "TRẢ PHÒNG",
                      style: TextStyle(color: AdminColors.textSecondary),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "TRẠNG THÁI",
                      style: TextStyle(color: AdminColors.textSecondary),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "TỔNG TIỀN",
                      style: TextStyle(color: AdminColors.textSecondary),
                    ),
                  ),
                ],
                rows: bookings.map((b) {
                  final statusColor = _bookingStatusColor(b.status);
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          b.roomNumber,
                          style: const TextStyle(
                            color: AdminColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          b.customerName,
                          style: const TextStyle(
                            color: AdminColors.textPrimary,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          b.checkInDate,
                          style: const TextStyle(
                            color: AdminColors.textSecondary,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          b.checkOutDate,
                          style: const TextStyle(
                            color: AdminColors.textSecondary,
                          ),
                        ),
                      ),
                      DataCell(
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
                            _bookingStatusLabel(b.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatMoney(b.totalPrice),
                          style: const TextStyle(
                            color: AdminColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  _StatCardData({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });
}