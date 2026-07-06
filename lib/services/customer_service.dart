import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer.dart';

class CustomerService {
  final CollectionReference _ref =
      FirebaseFirestore.instance.collection('customers');

  Future<List<Customer>> getCustomers() async {
    final snapshot = await _ref.get();

    return snapshot.docs
        .map(
          (doc) => Customer.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> addCustomer(Customer customer) async {
    await _ref.add(customer.toMap());
  }

  Future<void> updateCustomer(Customer customer) async {
    if (customer.id == null) return;
    await _ref.doc(customer.id).update(customer.toMap());
  }

  Future<void> deleteCustomer(String id) async {
    await _ref.doc(id).delete();
  }
}