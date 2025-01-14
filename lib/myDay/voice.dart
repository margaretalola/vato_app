import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'taskRepository.dart';

class VoiceAssistant extends StatefulWidget {
  final TaskRepository taskRepository;

  const VoiceAssistant({Key? key, required this.taskRepository}) : super(key: key);

  @override
  State<VoiceAssistant> createState() => _VoiceAssistantState();
}

class _VoiceAssistantState extends State<VoiceAssistant> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  bool _hasPermission = false;
  bool _isProcessing = false;
  String _title = '';
  String _date = '';
  String _time = '';
  List<Task> _tasksToBeAdded = [];

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

  String _removeOrdinalSuffix(String date) {
    // Remove ordinal suffixes and trim spaces
    return date.replaceAll(RegExp(r'(st|nd|rd|th)'), '').trim();
  }

  void _parseRecognizedText(String recognizedText) {
    print('Recognized text: $recognizedText');
    RegExp taskPattern = RegExp(r"(.*) on (\d+(?:st|nd|rd|th)? \w+) at (\d+:\d+)");
    print('Task pattern: $taskPattern');
    var matches = taskPattern.allMatches(recognizedText);

    if (matches.isEmpty) {
      print('No matches found');
      return;
    }

    //check match
    for (var match in matches) {
      print('Match found: ${match.group(0)}');
      String? title = match.group(1)?.trim();
      print('Title: $title');
      String? date = match.group(2)?.trim();
      print('Date: $date');
      String? time = match.group(3)?.trim();
      print('Time: $time');

      if (title != null && date != null && time != null) {
        try {
          String cleanedDate = _removeOrdinalSuffix(date);
          print('Cleaned Date: $cleanedDate');
          String currentYear = DateFormat('yyyy').format(DateTime.now());
          List<String> dateParts = cleanedDate.split(' ');
          String day = dateParts[0].padLeft(2, '0');
          String monthName = dateParts[1];
          DateTime month = DateFormat('MMMM').parse(monthName);
          String monthNumber = DateFormat('MM').format(month);
          String dateTimeString = '$day $monthNumber $currentYear $time';
          print('DateTime String: $dateTimeString');

          DateTime parsedDateTime = DateFormat('dd MM yyyy HH:mm').parse(dateTimeString);
          String formattedDate = DateFormat('dd-MM-yyyy').format(parsedDateTime);
          String formattedTime = DateFormat('HH:mm').format(parsedDateTime);

          setState(() {
            _title = title;
            _date = formattedDate;
            _time = formattedTime;
          });

          _saveTaskToRepository(Task(
            id: '',
            title: _title,
            description: '',
            date: _date,
            time: _time,
            selectedRemind: 0,
            selectedCategory: 'Other',
            isDone: false,
          ));

        } catch (e) {
          print('Error parsing date and time: $e');
        }
      }
    }
  }

  void _saveTaskToRepository(Task task) async {
    try {
      await widget.taskRepository.addTask(task);
      setState(() {
        _tasksToBeAdded.add(task);
        _recognizedText = 'Task saved!';
      });
      _showSuccessDialog('Task added successfully');
    } catch (e) {
      print('Error: $e');
      _showErrorDialog('Error adding task: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
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
            _isListening ? Icons.mic : Icons.mic_none,
            size: 50,
            color: _isListening ? Colors.blue : Colors.black,
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _startListening,
            child: _isListening ? Text('Stop Speaking') : Text('Start Speaking'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Close'),
          )
        ],
      ),
    );
  }
}
