import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Assets/buttonNavigationBar.dart';
import '../calendar/calendarRepository.dart';
import '../myDay/taskRepository.dart';
import '../registerPage/signIn.dart';
import '../calendar/calendar.dart';
import '../myDay/myDay.dart';

class Homepage extends StatefulWidget {
  Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _homepage();
}

class _homepage extends State<Homepage> {
  firebase_auth.FirebaseAuth firebaseAuth = firebase_auth.FirebaseAuth.instance;
  String _greetingMessage = '';
  String _dateMessage = '';
  late AppointmentRepository _appointmentRepository;
  List<AppointmentCalendar> _todaysAppointments = [];
  late TaskRepository _taskRepository;
  List<Task> _tasks = [];
  late Stream<List<AppointmentCalendar>> _appointmentStream;
  late Stream<List<Task>> _taskStream;

  late StreamSubscription<List<AppointmentCalendar>> _appointmentSubscription;
  late StreamSubscription<List<Task>> _taskSubscription;

  @override
  void initState() {
    super.initState();
    _updateGreetingMessage();
    _updateDateMessage();
    _appointmentRepository = AppointmentRepository();
    _taskRepository = TaskRepository();
    _fetchTodaysAppointments();
    _fetchTasks();
    _appointmentStream = _appointmentRepository.getAppointments().asBroadcastStream();
    _taskStream = _taskRepository.getTasks().asBroadcastStream();
    _appointmentSubscription = _appointmentRepository.getAppointments().listen((appointments) {
      final today = DateTime.now().toUtc();
      final todaysAppointments = appointments.where((appointment) {
        final appointmentDate = DateFormat('yyyy-MM-dd').parse(appointment.date);
        return appointmentDate.year == today.year && appointmentDate.month == today.month && appointmentDate.day == today.day;
      }).toList();
      setState(() {
        _todaysAppointments = todaysAppointments;
      });
    });
    _taskSubscription = _taskRepository.getTasks().listen((tasks) {
      final today = DateTime.now().toUtc();
      final todaysTasks = tasks.where((task) {
        final taskDate = DateFormat('yyyy-MM-dd').parse(task.date);
        return taskDate.year == today.year && taskDate.month == today.month && taskDate.day == today.day;
      }).toList();
      setState(() {
        _tasks = todaysTasks;
      });
    });
  }

  @override
  void dispose() {
    _appointmentSubscription.cancel();
    _taskSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        backgroundColor: Colors.lightBlue,
        elevation: 5,
        title: SizedBox(
          height: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _greetingMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                _dateMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              size: 30,
              color: Colors.white,
            ),
            onPressed: () async {
              await firebaseAuth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignInPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.only(bottom: 65),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNotificationCard(
              title: "Your Schedule",
              description: 'Check your upcoming schedule now.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: ButtonNavigationBarCustom(),
    );
  }

  void _updateGreetingMessage() {
    final hour = TimeOfDay.now().hour;
    setState(() {
      if (hour < 12) {
        _greetingMessage = 'Good Morning';
      } else if (hour < 17) {
        _greetingMessage = 'Good Afternoon';
      } else {
        _greetingMessage = 'Good Evening';
      }
    });
  }

  void _updateDateMessage() {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, d MMMM');
    setState(() {
      _dateMessage = dateFormat.format(now);
    });
  }

  Future<void> _fetchTodaysAppointments() async {
    try {
      final appointmentStream = _appointmentRepository.getAppointments();
      appointmentStream.listen((appointments) {
        print('Appointments fetched: $appointments');
        final today = DateTime.now();
        final todaysAppointments = appointments.where((appointment) {
          final appointmentDate = DateTime.parse(appointment.date);
          return appointmentDate.year == today.year &&
              appointmentDate.month == today.month &&
              appointmentDate.day == today.day;
        }).toList();
        setState(() {
          _todaysAppointments = todaysAppointments;
          print('Todays appointments: $_todaysAppointments');
        });
      });
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }

  Future<void> _fetchTasks() async {
    try {
      final tasksStream = _taskRepository.getTasks();
      tasksStream.listen((tasks) {
        print('Tasks fetched: $tasks');
        final today = DateTime.now();
        final todaysTasks = tasks.where((task) {
          try {
            final taskDate = DateTime.parse(task.date);
            return taskDate.year == today.year &&
                taskDate.month == today.month &&
                taskDate.day == today.day;
          } catch (e) {
            print('Invalid date format for task: ${task.date}');
            return false;
          }
        }).toList();
        setState(() {
          _tasks = todaysTasks;
          print('Today\'s tasks: $_tasks');
        });
      });
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  Widget _buildNotificationCard({
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20),
      constraints: BoxConstraints(
        minWidth: 0.0,
        minHeight: 0.0,
        maxWidth: double.infinity,
        maxHeight: 500,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Tasks:',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StreamBuilder<List<Task>>(
                  stream: _taskRepository.getTasks(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print('Error: ${snapshot.error}');
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('No tasks available');
                    } else {
                      final today = DateTime.now();
                      final tasksToday = snapshot.data!.where((task) {
                        try {
                          final taskDate = DateFormat('dd-MM-yyyy').parse(task.date);
                          return taskDate.year == today.year &&
                              taskDate.month == today.month &&
                              taskDate.day == today.day;
                        } catch (e) {
                          print('Invalid date format for task: ${task.date}');
                          return false;
                        }
                      }).take(5).toList();

                      if (tasksToday.isEmpty) {
                        return Text('No tasks assigned for today');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: tasksToday.map((task) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2.0),
                            child: Row(
                              children: [
                                Text(
                                  '${task.time} ${task.title}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MyDay(taskRepository: _taskRepository)),
                        );
                      },
                      child: Text('See All Tasks'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Event:',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StreamBuilder<List<AppointmentCalendar>>(
                  stream: _appointmentRepository.getAppointments(),
                  builder: (context, snapshot) {
                    print('Appointment snapshot: $snapshot');
                    if (snapshot.hasData) {
                      final todaysAppointment = snapshot.data!
                          .where((appointment) => DateTime.parse(appointment.date).day == DateTime.now().day)
                          .take(5)
                          .toList();
                      if (todaysAppointment.isEmpty) {
                        return Text('No Appointments scheduled for today');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: todaysAppointment.map((appointment) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2.0),
                            child: Row(
                              children: [
                                Text(
                                  '${appointment.start_time} - ${appointment.end_time} ${appointment.subject}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CalendarCustom(appointmentRepository: _appointmentRepository)),
                        );
                      },
                      child: Text('See All Appointments'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
