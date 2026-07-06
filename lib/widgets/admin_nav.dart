import 'package:flutter/material.dart';

import '../screens/admin/dashboard_screen.dart';
import '../screens/admin/room_screen.dart';
import '../screens/admin/booking_screen.dart';
import '../screens/admin/customer_screen.dart';
import '../screens/admin/statistic_screen.dart';
import '../screens/admin/checkinout_screen.dart';
import '../screens/admin/invoice_screen.dart';
import '../screens/auth/login_screen.dart';

import 'app_drawer.dart';

/// Điều hướng dùng chung cho các trang admin. Dùng Navigator.push bình
/// thường (không phải pushReplacement) để AppBar tự động hiện nút back
/// — nhiều trang admin cũ (Khách hàng, Báo cáo...) chỉ dựa vào nút back
/// tự động này, không có drawer/nút "về trang chủ" riêng.
void _goTo(BuildContext context, Widget page) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => page),
  );
}

void _comingSoon(BuildContext context, String featureName) {
  Navigator.of(context).pop(); // đóng drawer trước
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("$featureName đang được phát triển")),
  );
}

/// Danh sách 7 mục menu admin, dùng chung cho mọi trang admin.
/// Gắn vào Scaffold bằng: `drawer: AppDrawer(items: buildAdminMenuItems(context))`
List<AppDrawerItem> buildAdminMenuItems(BuildContext context) {
  return [
    AppDrawerItem(
      title: "Tổng quan",
      icon: Icons.grid_view_rounded,
      onTap: () => _goTo(context, const DashboardScreen()),
    ),
    AppDrawerItem(
      title: "Quản lý phòng",
      icon: Icons.meeting_room_outlined,
      onTap: () => _goTo(context, const RoomScreen()),
    ),
    AppDrawerItem(
      title: "Đặt phòng",
      icon: Icons.event_note_outlined,
      onTap: () => _goTo(context, const BookingScreen()),
    ),
    AppDrawerItem(
      title: "Nhận/Trả phòng",
      icon: Icons.compare_arrows_outlined,
      onTap: () => _goTo(context, const CheckInOutScreen()),
    ),
    AppDrawerItem(
      title: "Khách hàng",
      icon: Icons.people_outline,
      onTap: () => _goTo(context, const CustomerScreen()),
    ),
    AppDrawerItem(
      title: "Hoá đơn",
      icon: Icons.receipt_long_outlined,
      onTap: () => _goTo(context, const InvoiceScreen()),
    ),
    AppDrawerItem(
      title: "Báo cáo",
      icon: Icons.bar_chart_outlined,
      onTap: () => _goTo(context, const StatisticScreen()),
    ),
  ];
}

/// Dùng hàm này thay vì tự dựng `AppDrawer(...)` ở từng trang admin, để
/// đảm bảo LUÔN có `onLogoutComplete` điều hướng về LoginScreen — thiếu
/// bước này là nguyên nhân gây lỗi "bấm Đăng xuất không có phản ứng gì".
Widget buildAdminDrawer(BuildContext context) {
  return AppDrawer(
    headerTitle: "Grand Palace",
    headerSubtitle: "Hotel Manager",
    items: buildAdminMenuItems(context),
    onLogoutComplete: () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    },
  );
}