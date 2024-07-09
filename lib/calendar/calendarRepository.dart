import 'dart:async';
import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentCalendar {
  final String id;
  final String subject;
  final String date;
  final String start_time;
  final String end_time;
  final String recurrence;
  final String category;
  bool isCompleted;
  bool isSelected;
  DateTime dateTime;

  AppointmentCalendar({
    required this.id,
    required this.subject,
    required this.date,
    required this.start_time,
    required this.end_time,
    required this.recurrence,
    required this.category,
    this.isCompleted = false,
    this.isSelected = false,
  }) : dateTime = DateFormat('yyyy-MM-dd HH:mm').parse('$date $start_time');

  static DateTime _parseDateTime(String date, String time) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final timeFormatter = DateFormat('HH:mm');
    final parsedDate = dateFormatter.parse(date);
    final timeParts = timeFormatter.parse(time);
    final hour = timeParts.hour;
    final minute = timeParts.minute;

    return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
  }

  static AppointmentCalendar empty() {
    return AppointmentCalendar(
      id: '',
      subject: '',
      start_time: '',
      end_time: '',
      date: '',
      recurrence: '',
      category: '',
    );
  }

  factory AppointmentCalendar.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['datetime'] as Timestamp;
    final date = DateFormat('yyyy-MM-dd').format(timestamp.toDate());

    final startTime = data['start_time'] as String?;
    final endTime = data['end_time'] as String?;
    if (startTime == null || endTime == null || startTime.isEmpty || endTime.isEmpty) {
      print('Warning: start_time or end_time is missing or empty');
      return AppointmentCalendar(
        id: doc.id,
        subject: data['subject'],
        date: date,
        start_time: '00:00', // Default value
        end_time: '00:00', // Default value
        recurrence: data['recurrence'],
        category: data['category'],
      );
    }

    try {
      final startDateTime = DateFormat('yyyy-MM-dd HH:mm').parse('$date $startTime');
      final endDateTime = DateFormat('yyyy-MM-dd HH:mm').parse('$date $endTime');

      return AppointmentCalendar(
        id: doc.id,
        subject: data['subject'],
        date: date,
        start_time: startTime,
        end_time: endTime,
        recurrence: data['recurrence'],
        category: data['category'],
      );
    } catch (e) {
      print('Error parsing appointment: $e');
      return AppointmentCalendar(
        id: doc.id,
        subject: data['subject'],
        date: date,
        start_time: '00:00',
        end_time: '00:00',
        recurrence: data['recurrence'],
        category: data['category'],
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    final startDateTime = _parseDateTime(date, start_time);
    final endDateTime = _parseDateTime(date, end_time);

    return {
      'subject': subject,
      'date': date,
      'start_time': start_time,
      'end_time': end_time,
      'datetime': startDateTime,
      'category': category,
      'recurrence': recurrence,
    };
  }
}

class AppointmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  late CollectionReference _calendarCollection;

  AppointmentRepository() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _userId = user.uid;
        _calendarCollection = _firestore.collection('users').doc(_userId!).collection('calendar');
        print('User logged in: $_userId');
      } else {
        _userId = null;
        print('User logged out.');
      }
    });
  }

  Future<void> addAppointment(AppointmentCalendar appointment) async {
    if (_userId == null) {
      print('Error: _userId is null. User is not logged in or authentication is incomplete.');
      return;
    }
    try {
      await _calendarCollection.add(appointment.toFirestore());
      print('Appointment added: ${appointment.toFirestore()}');
    } catch (e) {
      print('Error adding appointment: $e');
    }
  }

  Future<void> deleteAppointment(String eventId) async {
    if (_userId == null) {
      print('Error: _userId is null. User is not logged in or authentication is incomplete.');
      return;
    }
    try {
      await _calendarCollection.doc(eventId).delete();
      print('Appointment deleted: $eventId');
    } catch (e) {
      print('Error deleting appointment: $e');
    }
  }

  Future<void> updateAppointment(AppointmentCalendar appointment) async {
    if (_userId == null) {
      print('Error: _userId is null. User is not logged in or authentication is incomplete.');
      return;
    }
    try {
      await _calendarCollection.doc(appointment.id).update(appointment.toFirestore());
      print('Appointment updated: ${appointment.toFirestore()}');
    } catch (e) {
      print('Error updating appointment: $e');
    }
  }

  Stream<List<AppointmentCalendar>> getAppointments() {
    if (_userId == null) {
      print('Error: User is not logged in.');
      return Stream.empty();
    }

    return _calendarCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppointmentCalendar.fromFirestore(doc)).toList();
    });
  }

  Future<List<AppointmentCalendar>> getTodaysAppointments() async {
    final today = DateTime.now();
    final formattedToday = DateFormat('yyyy-MM-dd').format(today);

    try {
      // Get all appointments
      final appointments = await _calendarCollection.get().then((snapshot) =>
          snapshot.docs.map((doc) => AppointmentCalendar.fromFirestore(doc)).toList());

      // Filter appointments for today
      final todaysAppointments = appointments.where((appointment) =>
      appointment.date == formattedToday // Access 'date' on 'appointment'
      ).toList();
      return todaysAppointments; // Return the filtered list
    } catch (e) {
      print('Error fetching appointments: $e');
      return []; // Return an empty list in case of error
    }
  }
}