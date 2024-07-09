import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'taskRepository.dart';

class AddingTask extends StatefulWidget {
  final TextEditingController subjectController;
  final TextEditingController descriptionController;
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
  final Function(
      String,
      String,
      String,
      String,
      int,
      String,
      Task,
      ) onAddOrUpdate;
  final bool isEditMode;
  final String taskId;
  final TaskRepository taskRepository;
  final List<Task> tasks;

  AddingTask({
    required this.subjectController,
    required this.descriptionController,
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
    required this.onAddOrUpdate,
    required this.isEditMode,
    required this.taskId,
    required this.taskRepository,
    required this.tasks,
  });

  @override
  _AddingTaskState createState() => _AddingTaskState();
}

class _AddingTaskState extends State<AddingTask> {
  late int _selectedRemind;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedRemind = widget.selectedRemind;
    _selectedCategory = widget.selectCategory;
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        widget.dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        widget.timeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Task' : 'Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: widget.subjectController,
              decoration: InputDecoration(labelText: 'Subject'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: widget.descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: widget.dateController,
              readOnly: true,
              onTap: _selectDate,
              decoration: InputDecoration(labelText: 'Date'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: widget.timeController,
              readOnly: true,
              onTap: _selectTime,
              decoration: InputDecoration(labelText: 'Time'),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _selectedRemind,
              onChanged: (int? newValue) {
                setState(() {
                  _selectedRemind = newValue!;
                });
                widget.onSelectedRemindChange(newValue);
              },
              decoration: InputDecoration(
                labelText: 'Remind me before',
              ),
              items: widget.remindList.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
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
                widget.onSelectedCategoryChange(newValue);
              },
              decoration: InputDecoration(
                labelText: 'Category',
              ),
              items: widget.categoryList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      floatingActionButton:  FloatingActionButton.extended(
        onPressed: () async {
          widget.onAddOrUpdate(
            widget.subjectController.text,
            widget.descriptionController.text,
            widget.dateController.text,
            widget.timeController.text,
            _selectedRemind,
            _selectedCategory,
            Task(
              id: widget.taskId,
              title: widget.subjectController.text,
              description: widget.descriptionController.text,
              date: widget.dateController.text,
              time: widget.timeController.text,
              selectedRemind: _selectedRemind,
              selectedCategory: _selectedCategory,
              isDone: false,
            ),
          );
        },
        // child: Text(widget.isEditMode ? 'Update' : 'Add'),
        label: Text(widget.isEditMode ? 'Update' : 'Save'),
        icon: Icon(Icons.save),
      ),
    );
  }
}

