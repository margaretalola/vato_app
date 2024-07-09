import 'package:flutter/material.dart';
import 'package:vato_app/myDay/taskRepository.dart';
import 'package:vato_app/myDay/voice.dart';

class NavBar extends StatelessWidget {
  final NavBarConfig _config;

  NavBar({
    required TextEditingController subjectController,
    required TextEditingController descriptionController,
    required int selectedIndex,
    required Function(int) onNavItemTapped,
    required TextEditingController dateController,
    required TextEditingController timeController,
    required int selectedRemind,
    required List<int> remindList,
    required String selectCategory,
    required List<String> categoryList,
    required Future<void> Function() selectedDate,
    required Future<void> Function() selectedTime,
    required Function(int?) onSelectedRemindChange,
    required Function(String?) onSelectedCategoryChange,
    required void Function() onAddTask,
  }) : _config = NavBarConfig(
    subjectController: subjectController,
    descriptionController: descriptionController,
    selectedIndex: selectedIndex,
    onNavItemTapped: onNavItemTapped,
    dateController: dateController,
    timeController: timeController,
    selectedRemind: selectedRemind,
    remindList: remindList,
    selectCategory: selectCategory,
    categoryList: categoryList,
    selectedDate: selectedDate,
    selectedTime: selectedTime,
    onSelectedRemindChange: onSelectedRemindChange,
    onSelectedCategoryChange: onSelectedCategoryChange,
    onAddTask: onAddTask,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(right: 10, left: 10, bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 3),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: _buildAddButton(context),
          ),
          SizedBox(width: 1),
          Expanded(child: _openVoiceAssistant(context)),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: _config.onAddTask,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(60),
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
            disabledForegroundColor: Colors.blue.withOpacity(0.38),
          ),
          onPressed: null,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Masukkan tugas disini',
              textAlign: TextAlign.start,
            ),
          ),
        ),
      ),
    );
  }

  Widget _openVoiceAssistant(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.5,
            child: VoiceAssistant(taskRepository: TaskRepository()),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(11), // Add some padding around the icon
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mic,
          color: Colors.white,
        ),
      ),
    );
  }
}

class NavBarConfig {
  final TextEditingController subjectController;
  final TextEditingController descriptionController;
  final int selectedIndex;
  final Function(int) onNavItemTapped;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final int selectedRemind;
  final List<int> remindList;
  final String selectCategory;
  final List<String> categoryList;
  final Future<void> Function() selectedDate;
  final Future<void> Function() selectedTime;
  final Function(int?) onSelectedRemindChange;
  final Function(String?) onSelectedCategoryChange;
  final void Function() onAddTask;

  NavBarConfig({
    required this.subjectController,
    required this.descriptionController,
    required this.selectedIndex,
    required this.onNavItemTapped,
    required this.dateController,
    required this.timeController,
    required this.selectedRemind,
    required this.remindList,
    required this.selectCategory,
    required this.categoryList,
    required this.selectedDate,
    required this.selectedTime,
    required this.onSelectedRemindChange,
    required this.onSelectedCategoryChange,
    required this.onAddTask,
  });
}