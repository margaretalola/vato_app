import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:vato_app/calendar/expandButton.dart';
import 'package:vato_app/calendar/voiceCalendar.dart';
import 'calendarRepository.dart';
import 'package:vato_app/Assets/getRandomColor.dart';

class CalendarCustom extends StatefulWidget {
  final AppointmentRepository appointmentRepository;
  const CalendarCustom({super.key, required this.appointmentRepository});

  @override
  State<CalendarCustom> createState() => _CalendarCustomState();
}

class _CalendarCustomState extends State<CalendarCustom> {
  List<AppointmentCalendar> _meetings = [];
  late Stream<List<AppointmentCalendar>> _appointmentStream;
  late List<String> _categoryList = ['Personal', 'Meetings', 'Work', 'Other'];
  late List<String> _recurrenceList = ['None', 'Daily', 'Weekly', 'Monthly'];
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController start_timeController = TextEditingController();
  final TextEditingController end_timeController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  late String _selectedRecurrence = 'None';
  late String _selectedCategory = 'Personal';
  late StreamSubscription<List<AppointmentCalendar>> _appointmentSubscription;
  DataSource? _dataSource;
  late AppointmentRepository _appointmentRepository;
  Map<String, bool> _checkboxStates = {};

  @override
  void initState() {
    super.initState();
    _appointmentRepository = widget.appointmentRepository;
    _appointmentStream = _appointmentRepository.getAppointments();
    _appointmentSubscription = _appointmentStream.listen((appointments) {
      _initializeDataSource(appointments);
    });
  }

  @override
  void dispose() {
    _appointmentSubscription.cancel();
    subjectController.dispose();
    start_timeController.dispose();
    end_timeController.dispose();
    dateController.dispose();
    super.dispose();
  }

  void _initializeDataSource(List<AppointmentCalendar> appointments) {
    if (mounted) {
      setState(() {
        _meetings = appointments;
        _dataSource = DataSource(_meetings);
        for (var appointment in appointments) {
          _checkboxStates[appointment.id] = false;
        }
      });
    }
  }

  Future<void> selectedDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> selectTime(TextEditingController timeController) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      final formattedTime = DateFormat('HH:mm').format(DateTime(now.year, now.month, now.day, picked.hour, picked.minute));
      setState(() {
        timeController.text = formattedTime;
      });
    }
  }

  Future<void> _showEditAppointmentDialog(AppointmentCalendar appointment) async {
    subjectController.text = appointment.subject;
    descriptionController.text = appointment.description;
    start_timeController.text = appointment.start_time;
    end_timeController.text = appointment.end_time;
    dateController.text = appointment.date;
    _selectedRecurrence = appointment.recurrence;
    _selectedCategory = appointment.category;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: Text('Edit Appointment')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(labelText: 'Subject'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: start_timeController,
                    decoration: InputDecoration(labelText: 'Start Time'),
                    onTap: () async {
                      await selectTime(start_timeController);
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: end_timeController,
                    decoration: InputDecoration(labelText: 'End Time'),
                    onTap: () async {
                      await selectTime(end_timeController);
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: dateController,
                    decoration: InputDecoration(labelText: 'Date'),
                    onTap: () async {
                      await selectedDate();
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedRecurrence,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRecurrence = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Recurrence',
                    ),
                    items: _recurrenceList.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Category',
                    ),
                    items: _categoryList.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final updatedAppointment = AppointmentCalendar(
                  id: appointment.id,
                  subject: subjectController.text,
                  description: descriptionController.text,
                  start_time: start_timeController.text,
                  end_time: end_timeController.text,
                  date: dateController.text,
                  recurrence: _selectedRecurrence,
                  category: _selectedCategory,
                );
                await _appointmentRepository.updateAppointment(updatedAppointment);
                Navigator.of(context).pop();
              },
              label: Text('Update'),
              icon: Icon(Icons.save),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddAppointmentDialog() async {
    subjectController.clear();
    descriptionController.clear();
    start_timeController.clear();
    end_timeController.clear();
    dateController.clear();
    _selectedRecurrence = 'None';
    _selectedCategory = 'Personal';

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: Text('Add Appointment')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(labelText: 'Subject'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: start_timeController,
                    decoration: InputDecoration(labelText: 'Start Time'),
                    onTap: () async {
                      await selectTime(start_timeController);
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: end_timeController,
                    decoration: InputDecoration(labelText: 'End Time'),
                    onTap: () async {
                      await selectTime(end_timeController);
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: dateController,
                    decoration: InputDecoration(labelText: 'Date'),
                    onTap: () async {
                      await selectedDate();
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedRecurrence,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRecurrence = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Recurrence',
                    ),
                    items: _recurrenceList.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Category',
                    ),
                    items: _categoryList.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final newAppointment = AppointmentCalendar(
                  id: '',
                  subject: subjectController.text,
                  description: descriptionController.text,
                  start_time: start_timeController.text,
                  end_time: end_timeController.text,
                  date: dateController.text,
                  recurrence: _selectedRecurrence,
                  category: _selectedCategory,
                );
                await _appointmentRepository.addAppointment(newAppointment);
                Navigator.of(context).pop();
              },
              label: Text('Add'),
              icon: Icon(Icons.save),
            ),
          );
        },
      ),
    );
  }

  void _handleTap(CalendarTapDetails details) {
    print('Tapped details: $details');
    if (details.targetElement == CalendarElement.appointment) {
      print('Tapped on an appointment.');
      if (details.appointments != null && details.appointments!.isNotEmpty) {
        print('Appointments: ${details.appointments}');

        // Get the first tapped Appointment object
        final Appointment tappedAppointment = details.appointments!.first;
        print('Tapped appointment: $tappedAppointment');

        // Find the corresponding AppointmentCalendar
        final tappedAppointmentCalendar = _meetings.firstWhere(
                (appointment) => appointment.id == tappedAppointment.id,
            orElse: () => AppointmentCalendar.empty()
        );

        if (tappedAppointmentCalendar.id.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Appointment not found.'))
          );
          return; // Exit the function
        }

        _showEditAppointmentDialog(tappedAppointmentCalendar);
      } else {
        print('No appointments found.');
      }
    } else {
      print('Tapped on a different element: ${details.targetElement}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: SfCalendar(
        view: CalendarView.month,
        allowedViews: [
          CalendarView.month,
          CalendarView.schedule,
        ],
        dataSource: _dataSource,
        monthViewSettings: MonthViewSettings(
          showAgenda: true,
        ),
        scheduleViewSettings: ScheduleViewSettings(
          appointmentItemHeight: 50,
        ),
        showNavigationArrow: true,
        onTap: _handleTap,
        appointmentBuilder: (BuildContext context, CalendarAppointmentDetails details) {
          final Appointment appointment = details.appointments.first as Appointment;
          final appointmentCalendar = _meetings.firstWhere((element) => element.id == appointment.id);

          final bool isChecked = _checkboxStates[appointmentCalendar.id] ?? false;
          final Color backgroundColor = isChecked ? Colors.green : getCategoryColor(appointmentCalendar.category);

          return Slidable(
            key: ValueKey(appointmentCalendar.id),
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (BuildContext context) {
                    _showEditAppointmentDialog(appointmentCalendar);
                  },
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  label: 'Edit',
                ),
              ],
            ),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (BuildContext context) async {
                    await widget.appointmentRepository.deleteAppointment(appointmentCalendar.id);
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 50,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor, // Menggunakan backgroundColor yang sudah dihitung
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isChecked ? Colors.greenAccent : Colors.transparent, // Misalnya menambahkan border jika dicentang
                  width: isChecked ? 2.0 : 0.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: appointment.subject,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        TextSpan(
                          text: '\n${appointmentCalendar.category} | ${appointmentCalendar.start_time} - ${appointmentCalendar.end_time}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: _checkboxStates[appointmentCalendar.id] ?? false,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _checkboxStates[appointmentCalendar.id] = newValue!;
                      });
                    },
                    activeColor: Colors.blue, // Set the active color of the checkbox
                    checkColor: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: ExpandableFab(
        distance: 14.0,
        children: [
          ActionButton(
            onPressed: _showAddAppointmentDialog,
            icon: const Icon(Icons.add),
          ),
          ActionButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: VoiceAssistant(appointmentRepository: AppointmentRepository())
                  )
              );
            },
          ),
        ],
      ),
    );
  }
}

class DataSource extends CalendarDataSource {
  DataSource(List<AppointmentCalendar> source) {
    appointments = source
        .map(
          (appointment) => Appointment(
              id: appointment.id,
              startTime: appointment.dateTime,
              endTime: appointment.dateTime.add(Duration(minutes: 30)),
              subject: appointment.subject,
              color: getCategoryColor(appointment.category),
      ),
    )
        .toList();
  }
}