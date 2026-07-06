import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../providers/booking_provider.dart';
import '../../models/booking.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() =>
      _CalendarScreenState();
}

class _CalendarScreenState
    extends State<CalendarScreen> {

  DateTime focusedDay = DateTime.now();

  DateTime selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {

      context
          .read<BookingProvider>()
          .loadBookings();

    });

  }

  List<Booking> getBookingOfDay(
      List<Booking> bookings) {

    return bookings.where((booking) {

      return booking.checkInDate ==
          "${selectedDay.day.toString().padLeft(2, '0')}/"
          "${selectedDay.month.toString().padLeft(2, '0')}/"
          "${selectedDay.year}";

    }).toList();

  }

  Color statusColor(String status) {

    switch (status) {

      case "confirmed":
        return Colors.green;

      case "rejected":
        return Colors.red;

      default:
        return Colors.orange;

    }

  }

  String statusText(String status) {

    switch (status) {

      case "confirmed":
        return "Đã duyệt";

      case "rejected":
        return "Đã từ chối";

      default:
        return "Chờ duyệt";

    }

  }
    @override
  Widget build(BuildContext context) {

    final bookings =
        context.watch<BookingProvider>().bookings;

    final todayBookings =
        getBookingOfDay(bookings);

    return Scaffold(

      backgroundColor:
          Colors.grey.shade100,

      appBar: AppBar(

        centerTitle: true,

        title: const Text(
          "Lịch Booking",
        ),

      ),

      body: Column(

        children: [

          Card(

            margin:
                const EdgeInsets.all(16),

            elevation: 5,

            shape:
                RoundedRectangleBorder(

              borderRadius:
                  BorderRadius.circular(20),

            ),

            child: Padding(

              padding:
                  const EdgeInsets.all(10),

              child: TableCalendar(

                firstDay:
                    DateTime(2024),

                lastDay:
                    DateTime(2035),

                focusedDay:
                    focusedDay,

                selectedDayPredicate:
                    (day) {

                  return isSameDay(
                    day,
                    selectedDay,
                  );

                },

                onDaySelected:
                    (selected, focused) {

                  setState(() {

                    selectedDay =
                        selected;

                    focusedDay =
                        focused;

                  });

                },

                calendarStyle:
                    CalendarStyle(

                  todayDecoration:
                      const BoxDecoration(

                    color:
                        Colors.orange,

                    shape:
                        BoxShape.circle,

                  ),

                  selectedDecoration:
                      const BoxDecoration(

                    color:
                        Colors.blue,

                    shape:
                        BoxShape.circle,

                  ),

                ),

              ),

            ),

          ),

          Padding(

            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
            ),

            child: Row(

              children: [

                const Icon(
                  Icons.event,
                ),

                const SizedBox(
                  width: 10,
                ),

                Text(

                  "Booking ngày ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}",

                  style:
                      const TextStyle(

                    fontWeight:
                        FontWeight.bold,

                    fontSize: 18,

                  ),

                ),

              ],

            ),

          ),

          const SizedBox(
            height: 10,
          ),

          Expanded(

            child:
                todayBookings.isEmpty

                    ? const Center(

                        child: Text(

                          "Không có booking",

                          style: TextStyle(

                            fontSize: 18,

                            fontWeight:
                                FontWeight.bold,

                          ),

                        ),

                      )

                    : ListView.builder(

                        padding:
                            const EdgeInsets.all(
                          16,
                        ),

                        itemCount:
                            todayBookings.length,

                        itemBuilder:
                            (context, index) {

                          final booking =
                              todayBookings[index];

                          return Card(

                            elevation: 4,

                            margin:
                                const EdgeInsets.only(
                              bottom: 15,
                            ),

                            shape:
                                RoundedRectangleBorder(

                              borderRadius:
                                  BorderRadius.circular(
                                      18),

                            ),

                            child: ListTile(

                              leading:
                                  CircleAvatar(

                                backgroundColor:
                                    statusColor(
                                  booking.status,
                                ),

                                child: const Icon(

                                  Icons.hotel,

                                  color:
                                      Colors.white,

                                ),

                              ),

                              title: Text(

                                "Phòng ${booking.roomNumber}",

                                style:
                                    const TextStyle(

                                  fontWeight:
                                      FontWeight.bold,

                                ),

                              ),

                              subtitle: Column(

                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Text(
                                    booking.customerName,
                                  ),

                                  const SizedBox(
                                    height: 5,
                                  ),

                                  Text(
                                    "Check In : ${booking.checkInDate}",
                                  ),

                                  Text(
                                    "Check Out : ${booking.checkOutDate}",
                                  ),

                                ],

                              ),

                              trailing: Container(

                                padding:
                                    const EdgeInsets.symmetric(

                                  horizontal: 10,

                                  vertical: 6,

                                ),

                                decoration:
                                    BoxDecoration(

                                  color:
                                      statusColor(
                                    booking.status,
                                  ),

                                  borderRadius:
                                      BorderRadius.circular(
                                          20),

                                ),

                                child: Text(

                                  statusText(
                                    booking.status,
                                  ),

                                  style:
                                      const TextStyle(

                                    color:
                                        Colors.white,

                                    fontWeight:
                                        FontWeight.bold,

                                  ),

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