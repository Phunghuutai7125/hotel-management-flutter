class Validator {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Trường này không được để trống";
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng nhập email";
    }

    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

    if (!regex.hasMatch(value.trim())) {
      return "Email không hợp lệ";
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return "Vui lòng nhập mật khẩu";
    }

    if (value.length < 6) {
      return "Mật khẩu phải có ít nhất 6 ký tự";
    }

    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng nhập số điện thoại";
    }

    final regex = RegExp(r'^[0-9]{9,11}$');

    if (!regex.hasMatch(value.trim())) {
      return "Số điện thoại không hợp lệ";
    }

    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng nhập giá phòng";
    }

    final parsed = double.tryParse(value.trim());

    if (parsed == null) {
      return "Giá phòng phải là số";
    }

    if (parsed <= 0) {
      return "Giá phòng phải lớn hơn 0";
    }

    return null;
  }
}