import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vato_app/calendar/calendarRepository.dart';
import '../homepage/Homepage.dart';
import '../myDay/taskRepository.dart';
import '../myDay/myDay.dart';
import '../calendar/calendar.dart';
import 'package:provider/provider.dart';
import 'appState.dart';

// class ButtonNavigationBarCustom extends StatefulWidget {
//   const ButtonNavigationBarCustom({Key? key}) : super(key: key);
//
//   @override
//   State<ButtonNavigationBarCustom> createState() => _ButtonNavigationBarCustomState();
// }

class ButtonNavigationBarCustom extends StatelessWidget {
  int selectedIndex = 1; // Set the initial selected index to 1 (homepage)

  TaskRepository taskRepository = TaskRepository();
  AppointmentRepository appointmentRepository = AppointmentRepository();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return _navBar(appState, context); // Pass appState here
      },
    );
  }

  Widget _navBar(AppState appState, BuildContext context) { // appState is now a parameter
    return Container(
      height: 65,
      margin: const EdgeInsets.only(
        right: 30,
        left: 30,
        bottom: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.lightBlue.shade50,
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.track_changes, 0, appState, context),
          _buildNavItem(Icons.home_filled, 1,appState, context),
          _buildNavItem(Icons.calendar_month, 2, appState, context),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, AppState appState,BuildContext context) {
    bool isSelected = appState.selectedIndex == index;
    return GestureDetector(
      onTap: () {
        appState.setSelectedIndex(index);

        if (index == 1) {
          Navigator.of(true as BuildContext).popUntil((route) => route.isFirst);
        } else {
          Widget selectedPage;
          switch (index) {
            case 0:
              selectedPage = MyDay(taskRepository: taskRepository);
              break;
            case 2:
              selectedPage = CalendarCustom(appointmentRepository: appointmentRepository);
              break;
            default:
              selectedPage = Homepage();
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => selectedPage),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected? Colors.blue : Colors.white,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.blue, width: 1)
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}