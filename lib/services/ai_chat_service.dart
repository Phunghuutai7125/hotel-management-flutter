import 'package:google_generative_ai/google_generative_ai.dart';
import '../secrets.dart';

class AiChatService {
  static const String _apiKey = geminiApiKey;
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _apiKey,
    systemInstruction: Content.system(
      'Bạn là trợ lý ảo hỗ trợ khách hàng cho hệ thống quản lý khách sạn. '
      'Trả lời ngắn gọn, thân thiện, bằng tiếng Việt.',
    ),
  );

  Future<String> sendMessage(String message) async {
    try {
      final response = await _model.generateContent([Content.text(message)]);
      return response.text ?? 'Xin lỗi, mình chưa trả lời được câu này.';
    } catch (e) {
      return 'Đã có lỗi xảy ra: $e';
    }
  }
}