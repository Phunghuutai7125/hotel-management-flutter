import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/booking.dart';
import '../../models/room.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;
  final Room room;

  const PaymentScreen({
    super.key,
    required this.booking,
    required this.room,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Uint8List? _receiptBytes;
  bool _isSubmitting = false;

  String _formatMoney(double value) {
    return "${NumberFormat("#,###", "vi").format(value)}đ";
  }

  String get _qrPayload {
    final b = widget.booking;
    return "NGAN HANG: VIETCOMBANK\n"
        "STK: 0123456789\n"
        "CHU TK: GRAND PALACE HOTEL\n"
        "SO TIEN: ${b.totalPrice.toStringAsFixed(0)}\n"
        "NOI DUNG: DP${b.id?.substring(0, b.id!.length.clamp(0, 8)) ?? ''}";
  }

  Future<void> _pickReceipt() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không đọc được file, thử lại nhé")),
        );
        return;
      }

      setState(() {
        _receiptBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể chọn ảnh, thử lại")),
      );
    }
  }

  Future<void> _submitConfirmation() async {
    setState(() => _isSubmitting = true);

    try {
      if (_receiptBytes != null) {
        final base64Str = base64Encode(_receiptBytes!);
        await context.read<BookingProvider>().updateBooking(
              widget.booking.copyWith(receiptUrl: base64Str),
            );
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppGradients.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppGradients.accent, size: 30),
          ),
          title: const Text("Đã gửi xác nhận"),
          content: const Text(
            "Cảm ơn bạn! Booking đang chờ khách sạn xác nhận thanh toán. "
            "Bạn có thể theo dõi trạng thái ở mục Lịch sử đặt phòng.",
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 160,
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text("Đã hiểu"),
                ),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;
      // Đóng màn thanh toán, quay lại trang chủ user.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final room = widget.room;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // -------------------------------------------------------
            // Header gradient
            // -------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Xác nhận thanh toán",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // -----------------------------------------------
                    // Thông tin đặt phòng
                    // -----------------------------------------------
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.hotel_rounded,
                                    color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Phòng ${room.roomNumber} - ${room.type}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _infoRow("Khách hàng", b.customerName),
                          _infoRow("Nhận phòng", b.checkInDate),
                          _infoRow("Trả phòng", b.checkOutDate),
                          const Divider(height: 24),
                          _infoRow(
                            "Tổng tiền",
                            _formatMoney(b.totalPrice),
                            valueColor: const Color(0xFF2563EB),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // -----------------------------------------------
                    // Mã QR
                    // -----------------------------------------------
                    _sectionCard(
                      child: Column(
                        children: [
                          const Text(
                            "Quét mã để chuyển khoản",
                            style:
                                TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "(Mã QR minh hoạ - dùng để demo quy trình)",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: _qrPayload,
                              version: QrVersions.auto,
                              size: 190,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _infoRow("Ngân hàng", "Vietcombank"),
                          _infoRow("Số tài khoản", "0123456789"),
                          _infoRow("Chủ tài khoản", "GRAND PALACE HOTEL"),
                          _infoRow(
                            "Số tiền",
                            _formatMoney(b.totalPrice),
                            valueColor: const Color(0xFF2563EB),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // -----------------------------------------------
                    // Tải sao kê (tuỳ chọn)
                    // -----------------------------------------------
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Ảnh sao kê chuyển khoản (không bắt buộc)",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Tải lên nếu bạn muốn khách sạn xác nhận nhanh hơn.",
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          if (_receiptBytes != null)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _receiptBytes!,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _receiptBytes = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: _pickReceipt,
                              icon: const Icon(Icons.upload_file_outlined),
                              label: const Text("Chọn ảnh sao kê"),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitConfirmation,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label:
                              Text(_isSubmitting ? "Đang gửi..." : "Gửi xác nhận"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "Booking của bạn đã được ghi nhận (chờ xác nhận),\n"
                        "kể cả khi bạn chưa gửi ảnh sao kê.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}