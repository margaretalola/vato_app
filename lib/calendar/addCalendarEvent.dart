import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'calendarRepository.dart';

class ShowAddAppointmentDialog extends StatefulWidget {
  final TextEditingController subjectController;
  final TextEditingController dateController;
  final TextEditingController start_timeController;
  final TextEditingController end_timeController;
  final String category;
  final List<String> categoryList;
  final String recurrence;
  final List<String> recurrenceList;
  final Future<void> Function() selectedDate;
  final Future<void> Function() selectedStartTime;
  final Future<void> Function() selectedEndTime;
  final Function(String?) onSelectedRecurrenceChange;
  final Function(String?) onSelectedCategoryChange;
  final Function(String, String, String, String, String, String, AppointmentCalendar) onAddOrUpdate;
  final bool isEditMode;
  final String appointmentId;

  ShowAddAppointmentDialog({
    Key? key,
    required this.onAddOrUpdate,
    required this.subjectController,
    required this.dateController,
    required this.end_timeController,
    required this.category,
    required this.categoryList,
    required this.recurrence,
    required this.recurrenceList,
    required this.selectedDate,
    required this.selectedStartTime,
    required this.selectedEndTime,
    required this.onSelectedRecurrenceChange,
    required this.onSelectedCategoryChange,
    required this.start_timeController,
    this.isEditMode = false,
    required this.appointmentId,
  }) : super(key: key);

  @override
  _ShowAddAppointmentDialogState createState() => _ShowAddAppointmentDialogState();
}

class _ShowAddAppointmentDialogState extends State<ShowAddAppointmentDialog> {
  bool _isAdded = false;
  final AppointmentRepository appointmentRepository = AppointmentRepository();

  Future<void> _onAddOrUpdatePressed() async {
    final subject = widget.subjectController.text;
    final date = widget.dateController.text; // Assuming date is in the format "dd-MM-yyyy"
    final start_time = widget.start_timeController.text;
    final end_time = widget.end_timeController.text;

    if (subject.isEmpty || date.isEmpty || start_time.isEmpty || end_time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    try {
      DateTime selectedDate = DateFormat('dd-MM-yyyy').parse(date); // Assuming date is in the correct format
      TimeOfDay selectedStart_time = _parseTimeOfDay(start_time);
      TimeOfDay selectedEnd_time = _parseTimeOfDay(end_time);

      DateTime startDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedStart_time.hour,
        selectedStart_time.minute,
      );

      DateTime endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedEnd_time.hour,
        selectedEnd_time.minute,
      );

      if (widget.isEditMode) {
        await FirebaseFirestore.instance.collection('calendar').doc(widget.appointmentId).update({
          'subject': subject,
          'date': date,
          'start_time': start_time,
          'end_time': end_time,
          'datetime': startDateTime,
          'category': widget.category,
          'recurrence': widget.recurrence,
        });
      } else {
        DocumentReference docRef = await FirebaseFirestore.instance.collection('calendar').add({
          'subject': subject,
          'date': date,
          'start_time': start_time,
          'end_time': end_time,
          'datetime': startDateTime,
          'category': widget.category,
          'recurrence': widget.recurrence,
        });

        final String appointmentId = docRef.id;

        if (!_isAdded) {
          _isAdded = true;
          widget.onAddOrUpdate(
            subject,
            date,
            start_time,
            end_time,
            widget.category,
            widget.recurrence,
            AppointmentCalendar(
              id: appointmentId,
              subject: subject,
              date: date,
              start_time: start_time,
              end_time: end_time,
              recurrence: widget.recurrence,
              category: widget.category,
            ),
          );
        }
      }
      Navigator.pop(context);
    } catch (e) {
      print('Error adding appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding appointment: $e')),
      );
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final timeParts = time.split(' ');
    final formattedTime = timeParts[0];
    final period = timeParts.length > 1 ? timeParts[1].toUpperCase() : '';

    final parts = formattedTime.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    if (period == 'PM' && hour < 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0; // Midnight case
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Appointment' : 'Add Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child:
        Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Subject'),
              controller: widget.subjectController,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: widget.dateController,
              readOnly: true,
              onTap: () => widget.selectedDate(),
              decoration: InputDecoration(
                labelText: 'Date',
                suffixIcon: IconButton(
                  onPressed: widget.selectedDate,
                  icon: const Icon(Icons.calendar_today),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: widget.start_timeController,
              readOnly: true,
              onTap: () => widget.selectedStartTime(),
              decoration: InputDecoration(
                labelText: 'Start Time',
                suffixIcon: IconButton(
                  onPressed: widget.selectedStartTime,
                  icon: const Icon(Icons.access_time),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: widget.end_timeController,
              readOnly: true,
              onTap: widget.selectedEndTime,
              decoration: InputDecoration(
                labelText: 'End Time',
                suffixIcon: IconButton(
                  onPressed: () =>  widget.selectedEndTime(),
                  icon: const Icon(Icons.access_time),
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Category',
              ),
              value: widget.category, // Ensure the initial value is valid
              onChanged: (newValue) {
                widget.onSelectedCategoryChange(newValue);
              },
              items: widget.categoryList.map((String category) {
                return DropdownMenuItem<String>(
                  value: category, // Explicitly set the value
                  child: Text(category),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Recurrence',
              ),
              value: widget.recurrence, // Ensure the initial value is valid
              onChanged: (newValue) {
                widget.onSelectedRecurrenceChange(newValue);
              },
              items: widget.recurrenceList.map((String recurrence) {
                return DropdownMenuItem<String>(
                  value: recurrence, // Explicitly set the value
                  child: Text(recurrence),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onAddOrUpdatePressed,
              child: Text(widget.isEditMode ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}