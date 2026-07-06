import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/room.dart';
import '../secrets.dart';

class AiChatService {
  static const String _apiKey = geminiApiKey; // key thật của bạn

  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _apiKey,
    systemInstruction: Content.system(
      'Bạn là trợ lý ảo hỗ trợ khách hàng cho hệ thống quản lý khách sạn. '
      'Trả lời ngắn gọn, thân thiện, bằng tiếng Việt. '
      'Nếu người dùng hỏi về phòng trống, giá phòng, loại phòng, hãy dựa vào '
      'DANH SÁCH PHÒNG HIỆN TẠI được cung cấp trong tin nhắn để trả lời chính xác. '
      'Nếu câu hỏi không liên quan đến dữ liệu phòng, trả lời bình thường theo kiến thức chung.',
    ),
  );

  /// Tóm tắt danh sách phòng thành đoạn text ngắn để đưa vào prompt,
  /// giúp AI trả lời được câu hỏi liên quan tới phòng trống/giá phòng.
  String _buildRoomContext(List<Room> rooms) {
    if (rooms.isEmpty) return 'DANH SÁCH PHÒNG HIỆN TẠI: (chưa có dữ liệu)';

    final lines = rooms.map((r) {
      final trangThai = r.isBooked ? 'Đang thuê' : 'Trống';
      return '- Phòng ${r.roomNumber} (${r.type}): ${r.price.toStringAsFixed(0)}đ/đêm, '
          'trạng thái: $trangThai';
    }).join('\n');

    return 'DANH SÁCH PHÒNG HIỆN TẠI:\n$lines';
  }

  Future<String> sendMessage(String message, {List<Room> rooms = const []}) async {
    try {
      final context = _buildRoomContext(rooms);

      final prompt = '$context\n\nCÂU HỎI CỦA KHÁCH: $message';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Xin lỗi, mình chưa trả lời được câu này.';
    } catch (e) {
      return 'Đã có lỗi xảy ra: $e';
    }
  }
}