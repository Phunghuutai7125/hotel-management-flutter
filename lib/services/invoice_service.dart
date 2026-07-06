import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/invoice.dart';

class InvoiceService {
  final CollectionReference _ref =
      FirebaseFirestore.instance.collection('invoices');

  Future<List<Invoice>> getInvoices() async {
    final snapshot = await _ref.get();

    return snapshot.docs
        .map(
          (doc) => Invoice.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<String> addInvoice(Invoice invoice) async {
    final docRef = await _ref.add(invoice.toMap());
    return docRef.id;
  }
}