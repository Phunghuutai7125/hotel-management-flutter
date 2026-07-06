import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/invoice_provider.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<InvoiceProvider>().loadInvoices());
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>().invoices.where((inv) {
      if (_query.isEmpty) return true;
      return inv.customerName.toLowerCase().contains(_query) ||
          inv.roomNumber.toLowerCase().contains(_query);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalRevenue =
        invoices.fold<double>(0, (sum, e) => sum + e.totalPrice);

    return Scaffold(
      appBar: AppBar(title: const Text('Hóa đơn')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên khách hoặc số phòng',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng doanh thu',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${NumberFormat("#,###", "vi").format(totalRevenue)}đ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: invoices.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có hóa đơn nào',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final inv = invoices[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade50,
                            child: const Icon(Icons.receipt_long,
                                color: Colors.green),
                          ),
                          title: Text(
                            inv.customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Phòng ${inv.roomNumber} • ${inv.checkInDate} → ${inv.checkOutDate}\n'
                            'Lập ngày: ${DateFormat("dd/MM/yyyy HH:mm").format(inv.createdAt)}',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            '${NumberFormat("#,###", "vi").format(inv.totalPrice)}đ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
