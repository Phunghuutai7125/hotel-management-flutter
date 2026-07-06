import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerService _service = CustomerService();

  List<Customer> customers = [];
  bool isLoading = false;

  Future<void> loadCustomers() async {
    isLoading = true;
    notifyListeners();

    try {
      customers = await _service.getCustomers();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    await _service.addCustomer(customer);
    await loadCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _service.updateCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await _service.deleteCustomer(id);
    await loadCustomers();
  }

  /// Kiểm tra số điện thoại đã tồn tại trong danh sách đã load hay chưa.
  bool phoneExists(String phone) {
    return customers.any((c) => c.phone == phone);
  }
}