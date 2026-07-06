
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {GoogleGenerativeAI} = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

exports.chatWithAI = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Bạn cần đăng nhập để dùng tính năng này."
    );
  }

  const userMessage = request.data.message;
  if (!userMessage || userMessage.trim() === "") {
    throw new HttpsError("invalid-argument", "Tin nhắn trống.");
  }

  const model = genAI.getGenerativeModel({
    model: "gemini-2.0-flash",
    systemInstruction:
      "Bạn là trợ lý ảo hỗ trợ khách hàng cho hệ thống quản lý khách sạn. Trả lời ngắn gọn, thân thiện, bằng tiếng Việt.",
  });

  const result = await model.generateContent(userMessage);
  const reply = result.response.text();

  return {reply: reply};
});
