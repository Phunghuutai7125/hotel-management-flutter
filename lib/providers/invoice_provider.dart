import 'package:flutter/material.dart';

import '../models/invoice.dart';
import '../services/invoice_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceService _service = InvoiceService();

  List<Invoice> invoices = [];
  bool isLoading = false;

  Future<void> loadInvoices() async {
    isLoading = true;
    notifyListeners();

    try {
      invoices = await _service.getInvoices();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addInvoice(Invoice invoice) async {
    await _service.addInvoice(invoice);
    await loadInvoices();
  }
}