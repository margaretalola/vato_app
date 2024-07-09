import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'calendarRepository.dart';

class VoiceAssistant extends StatefulWidget {
  final AppointmentRepository appointmentRepository;

  const VoiceAssistant({Key? key, required this.appointmentRepository}) : super(key: key);

  @override
  State<VoiceAssistant> createState() => _VoiceAssistantState();
}

class _VoiceAssistantState extends State<VoiceAssistant> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  bool _hasPermission = false;
  bool _isProcessing = false;
  String _subject = '';
  String _date = '';
  String _time = '';

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      setState(() {
        _hasPermission = true;
      });
    } else {
      setState(() {
        _hasPermission = false;
      });
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Denied'),
        content: Text('Microphone permission is required for voice input.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startListening() async {
    if (!_hasPermission) {
      await _requestPermission();
    }
    if (!_isListening) {
      setState(() {
        _isListening = true;
        _isProcessing = true;
      });

      bool available = await _speechToText.initialize(debugLogging: true);
      if (available) {
        _speechToText.listen(onResult: (val) {
          setState(() {
            _recognizedText = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _parseRecognizedText(_recognizedText);
            }
            _isProcessing = false;
          });
        });
      } else {
        setState(() {
          _isListening = false;
          _isProcessing = false;
        });
      }
    } else {
      setState(() {
        _isListening = false;
      });
      _speechToText.stop();
    }
  }

  void _parseRecognizedText(String recognizedText) {
    print('Recognized text: $recognizedText');

    // Extract the subject
    final RegExp subjectRegex = RegExp(r'^(.*?)\son\s');
    final RegExpMatch? subjectMatch = subjectRegex.firstMatch(recognizedText);
    if (subjectMatch != null) {
      _subject = subjectMatch.group(1)?.trim() ?? '';
      print('Extracted subject: $_subject');
    } else {
      print('No subject found');
    }

    // Extract the date
    final RegExp dateRegex = RegExp(r'(\d{1,2}(st|nd|rd|th)?\s+(January|February|March|April|May|June|July|August|September|October|November|December))');
    final RegExpMatch? dateMatch = dateRegex.firstMatch(recognizedText);
    if (dateMatch != null) {
      final String spokenDate = dateMatch.group(0) ?? '';
      final List<String> dateParts = spokenDate.split(' ');
      final String day = dateParts[0].replaceAll(RegExp(r'(st|nd|rd|th)'), '').trim();
      final String month = dateParts[1];
      final int year = DateTime.now().year;

      final DateFormat inputFormat = DateFormat('d MMMM yyyy', 'en_US');
      final DateTime parsedDate = inputFormat.parse('$day $month $year');
      final String formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);

      _date = formattedDate;
      print('Extracted date: $_date');
    } else {
      print('No date found');
    }

    // Extract the time
    final RegExp timeRegex = RegExp(r'at\s+(\d{1,2}(:\d{2})?\s*(AM|PM)?)');
    final RegExpMatch? timeMatch = timeRegex.firstMatch(recognizedText);
    if (timeMatch != null) {
      final String spokenTime = timeMatch.group(1)?.trim() ?? '';
      try {
        DateTime parsedTime;
        if (spokenTime.contains('AM') || spokenTime.contains('PM')) {
          parsedTime = DateFormat('h:mm a').parse(spokenTime);
        } else {
          parsedTime = DateFormat('H:mm').parse(spokenTime);
        }
        _time = DateFormat('HH:mm').format(parsedTime);
        print('Extracted time: $_time');
      } catch (e) {
        print('Error parsing time: $e');
      }
    } else {
      print('No time found');
    }

    if (_subject.isNotEmpty && _date.isNotEmpty && _time.isNotEmpty) {
      _saveAppointment();
    }
  }

  void _saveAppointment() {
    print('Subject: $_subject');
    print('Date: $_date');
    print('Time: $_time');

    if (_subject.isNotEmpty && _date.isNotEmpty && _time.isNotEmpty) {
      try {
        final DateTime appointmentDate = DateTime.parse(_date);
        print('Parsed appointment date: $appointmentDate');

        final DateTime appointmentTime;

        if (_time.isNotEmpty) {
          appointmentTime = DateTime.parse('1970-01-01 ${_time}'); // Parse time with a dummy date
          print('Parsed appointment time: $appointmentTime');
        } else {
          throw FormatException('Time string is empty');
        }

        // Combine date and time into a single DateTime object
        final DateTime finalAppointmentDate = DateTime(
          appointmentDate.year,
          appointmentDate.month,
          appointmentDate.day,
          appointmentTime.hour,
          appointmentTime.minute,
        );
        print('Combined date and time: $finalAppointmentDate');

        final String formattedDate = DateFormat('yyyy-MM-dd').format(finalAppointmentDate);
        final String formattedStartTime = DateFormat('HH:mm').format(finalAppointmentDate);

        final AppointmentCalendar appointment = AppointmentCalendar(
          id: '',
          subject: _subject,
          date: formattedDate,
          start_time: formattedStartTime,
          end_time: '', // Set end time to an empty string
          recurrence: '',
          category: 'Personal',
          isCompleted: false,
        );

        widget.appointmentRepository.addAppointment(appointment);
        setState(() {
          _recognizedText = 'Appointment saved!';
        });
        print('Appointment created: $appointment');
      } catch (e) {
        setState(() {
          _recognizedText = 'Error saving appointment. Please check the details.';
        });
        print('Error: $e');
      }
    } else {
      setState(() {
        _recognizedText = 'Please fill in subject, date, and time';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            _recognizedText,
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 20),
          Icon(
            _isListening? Icons.mic : Icons.mic_none,
            size: 40,
            color: _isListening? Colors.blue : Colors.black,
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _startListening,
            child: _isListening? Text('Stop Speaking') : Text('Start Speaking'),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: _saveAppointment,
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}