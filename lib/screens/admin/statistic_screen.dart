import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/booking_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/room_provider.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() =>
      _StatisticScreenState();
}

class _StatisticScreenState
    extends State<StatisticScreen> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {

      context.read<RoomProvider>().loadRooms();

      context.read<CustomerProvider>().loadCustomers();

      context.read<BookingProvider>().loadBookings();

    });

  }

  Widget buildCard({

    required IconData icon,

    required String title,

    required String value,

    required Color color,

  }) {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [

          BoxShadow(

            color: Colors.black12,

            blurRadius: 8,

            offset: const Offset(0,4),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          CircleAvatar(

            radius: 24,

            backgroundColor: color,

            child: Icon(

              icon,

              color: Colors.white,

            ),

          ),

          const Spacer(),

          Text(

            value,

            style: const TextStyle(

              fontSize: 26,

              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height:6),

          Text(

            title,

            style: TextStyle(

              color: Colors.grey.shade700,

            ),

          ),

        ],

      ),

    );

  }
    @override
  Widget build(BuildContext context) {

    final roomProvider =
        context.watch<RoomProvider>();

    final customerProvider =
        context.watch<CustomerProvider>();

    final bookingProvider =
        context.watch<BookingProvider>();

    final totalRooms =
        roomProvider.rooms.length;

    final bookedRooms =
        roomProvider.rooms
            .where((e) => e.isBooked)
            .length;

    final freeRooms =
        totalRooms - bookedRooms;

    final totalCustomers =
        customerProvider.customers.length;

    final totalBookings =
        bookingProvider.bookings.length;

    final pendingBookings =
        bookingProvider.bookings
            .where(
              (e) => e.status == "pending",
            )
            .length;

    return Scaffold(

      backgroundColor:
          Colors.grey.shade100,

      appBar: AppBar(

        centerTitle: true,

        title: const Text(
          "Thống kê",
        ),

      ),

      body: Padding(

        padding:
            const EdgeInsets.all(16),

        child: GridView.count(

          crossAxisCount: 2,

          crossAxisSpacing: 15,

          mainAxisSpacing: 15,

          children: [

            buildCard(

              icon: Icons.hotel,

              title: "Tổng phòng",

              value:
                  totalRooms.toString(),

              color: Colors.blue,

            ),

            buildCard(

              icon:
                  Icons.check_circle,

              title:
                  "Phòng trống",

              value:
                  freeRooms.toString(),

              color: Colors.green,

            ),

            buildCard(

              icon:
                  Icons.meeting_room,

              title:
                  "Đã đặt",

              value:
                  bookedRooms.toString(),

              color: Colors.red,

            ),

            buildCard(

              icon:
                  Icons.people,

              title:
                  "Khách hàng",

              value:
                  totalCustomers
                      .toString(),

              color:
                  Colors.orange,

            ),

            buildCard(

              icon:
                  Icons.book_online,

              title:
                  "Booking",

              value:
                  totalBookings
                      .toString(),

              color:
                  Colors.deepPurple,

            ),

            buildCard(

              icon:
                  Icons.pending,

              title:
                  "Chờ duyệt",

              value:
                  pendingBookings
                      .toString(),

              color:
                  Colors.amber,

            ),

          ],

        ),

      ),

    );

  }

}