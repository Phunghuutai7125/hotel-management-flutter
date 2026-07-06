import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../providers/customer_provider.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() =>
      _CustomerScreenState();
}

class _CustomerScreenState
    extends State<CustomerScreen> {
  final nameController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  String keyword = "";

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context
          .read<CustomerProvider>()
          .loadCustomers();
    });
  }

  void showCustomerDialog({
    Customer? customer,
  }) {
    if (customer != null) {
      nameController.text =
          customer.name;

      phoneController.text =
          customer.phone;
    } else {
      nameController.clear();
      phoneController.clear();
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            customer == null
                ? "Thêm khách hàng"
                : "Cập nhật khách hàng",
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [

              TextField(
                controller:
                    nameController,
                decoration:
                    const InputDecoration(
                  labelText: "Họ tên",
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              TextField(
                controller:
                    phoneController,
                keyboardType:
                    TextInputType.phone,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Số điện thoại",
                ),
              ),

            ],
          ),
          actions: [

            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
              ),
              child:
                  const Text("Huỷ"),
            ),

            ElevatedButton(
              onPressed: () async {
                final provider =
                    context.read<
                        CustomerProvider>();

                if (customer ==
                        null &&
                    provider.phoneExists(
                        phoneController
                            .text)) {
                  ScaffoldMessenger.of(
                          context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Số điện thoại đã tồn tại",
                      ),
                    ),
                  );
                  return;
                }

                final data =
                    Customer(
                  id: customer?.id,
                  name:
                      nameController.text,
                  phone:
                      phoneController.text,
                );

                if (customer ==
                    null) {
                  await provider
                      .addCustomer(
                          data);
                } else {
                  await provider
                      .updateCustomer(
                          data);
                }

                Navigator.pop(
                    context);
              },
              child: Text(
                customer == null
                    ? "Thêm"
                    : "Lưu",
              ),
            ),

          ],
        );
      },
    );
  }

  Future<void> deleteCustomer(
      Customer customer) async {
    final ok =
        await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
        title:
            const Text("Xoá"),
        content: Text(
          "Xoá ${customer.name} ?",
        ),
        actions: [

          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),
            child:
                const Text("Huỷ"),
          ),

          ElevatedButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            child:
                const Text("Xoá"),
          ),

        ],
      ),
    );

    if (ok == true) {
      await context
          .read<
              CustomerProvider>()
          .deleteCustomer(
              customer.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<
            CustomerProvider>();

    final customers = provider
        .customers
        .where(
          (e) =>
              e.name
                  .toLowerCase()
                  .contains(
                    keyword
                        .toLowerCase(),
                  ) ||
              e.phone.contains(
                  keyword),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
            "Khách hàng"),
      ),
      floatingActionButton:
          FloatingActionButton(
        onPressed: () {
          showCustomerDialog();
        },
        child:
            const Icon(Icons.add),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(
                16),
        child: Column(
          children: [

            TextField(
              decoration:
                  const InputDecoration(
                prefixIcon:
                    Icon(Icons.search),
                hintText:
                    "Tìm khách hàng...",
              ),
              onChanged: (value) {
                setState(() {
                  keyword = value;
                });
              },
            ),

            const SizedBox(
                height: 20),

            Expanded(
              child:
                  ListView.builder(
                itemCount:
                    customers.length,
                itemBuilder:
                    (_, index) {
                  final customer =
                      customers[
                          index];

                  return Card(
                    child: ListTile(
                      leading:
                          const CircleAvatar(
                        child: Icon(
                          Icons.person,
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                      subtitle: Text(
                          customer.phone),
                      trailing: Row(
                        mainAxisSize:
                            MainAxisSize
                                .min,
                        children: [

                          IconButton(
                            icon:
                                const Icon(
                              Icons.edit,
                              color: Colors
                                  .blue,
                            ),
                            onPressed:
                                () {
                              showCustomerDialog(
                                customer:
                                    customer,
                              );
                            },
                          ),

                          IconButton(
                            icon:
                                const Icon(
                              Icons.delete,
                              color: Colors
                                  .red,
                            ),
                            onPressed:
                                () {
                              deleteCustomer(
                                  customer);
                            },
                          ),

                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}