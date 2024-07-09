import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'taskRepository.dart';
import 'navigationBar.dart';
import 'addingTask.dart';

class MyDay extends StatefulWidget {
  final TaskRepository taskRepository;

  MyDay({Key? key, required this.taskRepository}) : super(key: key);

  @override
  State<MyDay> createState() => _MyDayState();
}

class _MyDayState extends State<MyDay> {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  int _selectedRemind = 0;
  late String _selectedCategory;
  int selectedIndex = 0;
  List<Task> _tasks = [];
  final List<int> _remindList = [0, 5, 10, 15];
  final List<String> _categoryList = ['Personal', 'Meetings', 'Business', 'Shopping', 'Other'];
  final List<String> _sortingCategory = ['Complete', 'Incomplete', 'Today', 'Tomorrow', '7 Days'];
  late Stream<List<Task>> _taskStream;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categoryList[0];
    _taskStream = widget.taskRepository.getTasks();
    _taskStream.listen((tasks) {
      setState(() {
        _tasks = tasks;
      });
    });
  }

  Future<void> _selectedDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _selectedTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  void _handleTap(Task task) {
    _showEditTaskDialog(task);
  }

  void _showEditTaskDialog(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddingTask(
          subjectController: TextEditingController(text: task.title),
          descriptionController: TextEditingController(text: task.description),
          dateController: TextEditingController(text: task.date),
          timeController: TextEditingController(text: task.time),
          selectedRemind: task.selectedRemind,
          remindList: _remindList,
          selectCategory: task.selectedCategory,
          categoryList: _categoryList,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          onSelectedRemindChange: (int? value) {
            if (value != null) {
              setState(() {
                _selectedRemind = value;
              });
            }
          },
          onSelectedCategoryChange: (String? value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
              });
            }
          },
          onAddOrUpdate: (subject, description, date, time, remind, category, task) async {
            await widget.taskRepository.updateTask(Task(
              id: task.id,
              title: subject,
              description: description,
              date: date,
              time: time,
              selectedRemind: remind,
              selectedCategory: category,
              isDone: task.isDone,
            ));
            Navigator.pop(context);
          },
          isEditMode: true,
          taskId: task.id,
          taskRepository: widget.taskRepository,
          tasks: _tasks,
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    _clearControllers();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddingTask(
          subjectController: subjectController,
          descriptionController: descriptionController,
          dateController: _dateController,
          timeController: _timeController,
          selectedRemind: _selectedRemind,
          remindList: _remindList,
          selectCategory: _selectedCategory,
          categoryList: _categoryList,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          onSelectedRemindChange: (int? value) {
            if (value != null) {
              setState(() {
                _selectedRemind = value;
              });
            }
          },
          onSelectedCategoryChange: (String? value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
              });
            }
          },
          onAddOrUpdate: (subject, description, date, time, remind, category, task) async {
            await widget.taskRepository.addTask(Task(
              id: '', // Firestore will generate the ID
              title: subject,
              description: description,
              date: date,
              time: time,
              selectedRemind: remind,
              selectedCategory: category,
              isDone: false,
            ));
            Navigator.pop(context);
          },
          isEditMode: false,
          taskId: '',
          taskRepository: widget.taskRepository,
          tasks: [],
        ),
      ),
    );
  }

  void _toggleTaskCompletion(int taskIndex) {
    setState(() {
      _tasks[taskIndex].isDone = !_tasks[taskIndex].isDone;
      widget.taskRepository.updateTask(_tasks[taskIndex]);
      _tasks.sort((task1, task2) => task1.isDone ? 1 : -1);
    });
  }

  void _sortTasks(String sortingCategory) {
    setState(() {
      if (sortingCategory == 'Complete') {
        _tasks.sort((task1, task2) => task1.isDone == task2.isDone ? 0 : (task1.isDone ? -1 : 1));
      } else if (sortingCategory == 'Incomplete') {
        _tasks.sort((task1, task2) => task1.isDone == task2.isDone ? 0 : (task1.isDone ? 1 : -1));
      } else if (sortingCategory == 'Today') {
        final now = DateTime.now();
        _tasks.sort((task1, task2) {
          final task1Date = DateFormat('dd-MM-yyyy').parse(task1.date);
          final task2Date = DateFormat('dd-MM-yyyy').parse(task2.date);
          final task1IsToday = task1Date.year == now.year && task1Date.month == now.month && task1Date.day == now.day;
          final task2IsToday = task2Date.year == now.year && task2Date.month == now.month && task2Date.day == now.day;
          return task1IsToday ? -1 : (task2IsToday ? 1 : 0);
        });
      } else if (sortingCategory == 'Tomorrow') {
        final tomorrow = DateTime.now().add(Duration(days: 1));
        _tasks.sort((task1, task2) {
          final task1Date = DateFormat('dd-MM-yyyy').parse(task1.date);
          final task2Date = DateFormat('dd-MM-yyyy').parse(task2.date);
          final task1IsTomorrow = task1Date.year == tomorrow.year && task1Date.month == tomorrow.month && task1Date.day == tomorrow.day;
          final task2IsTomorrow = task2Date.year == tomorrow.year && task2Date.month == tomorrow.month && task2Date.day == tomorrow.day;
          return task1IsTomorrow ? -1 : (task2IsTomorrow ? 1 : 0);
        });
      } else if (sortingCategory == '7 Days') {
        final sevenDaysFromNow = DateTime.now().add(Duration(days: 7));
        _tasks.sort((task1, task2) {
          final task1Date = DateFormat('dd-MM-yyyy').parse(task1.date);
          final task2Date = DateFormat('dd-MM-yyyy').parse(task2.date);
          final task1IsInNext7Days = task1Date.isBefore(sevenDaysFromNow) && task1Date.isAfter(DateTime.now());
          final task2IsInNext7Days = task2Date.isBefore(sevenDaysFromNow) && task2Date.isAfter(DateTime.now());
          return task1IsInNext7Days ? -1 : (task2IsInNext7Days ? 1 : 0);
        });
      } else {
        _tasks.sort((task1, task2) => task1.title.compareTo(task2.title));
      }
    });
  }

  Future<void> _deleteTask(Task task) async {
    await widget.taskRepository.deleteTask(task.id);
    setState(() {
      _tasks.remove(task);
    });
  }

  void _clearControllers() {
    subjectController.clear();
    descriptionController.clear();
    _dateController.clear();
    _timeController.clear();
    _selectedCategory = _categoryList[0];
    _selectedRemind = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Day'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: (String value) {
              _sortTasks(value);
            },
            itemBuilder: (BuildContext context) {
              return _sortingCategory.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _tasks.isEmpty
          ? Center(
        child: Text(
          'No tasks available',
          style: TextStyle(fontSize: 20),
        ),
      )
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Slidable(
              key: ValueKey(task.id),
              startActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) => _showEditTaskDialog(task),
                    backgroundColor: Colors.blue,
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
                    onPressed: (context) => _deleteTask(task),
                    backgroundColor: Color(0xFFFE4A49),
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => _handleTap(task),
                child: Container(
                  decoration: BoxDecoration(
                    color: task.isDone ? Colors.greenAccent : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.description),
                        Text('${task.date} ${task.time}'),
                        Text(task.selectedCategory),
                      ],
                    ),
                    trailing: Checkbox(
                      value: task.isDone,
                      onChanged: (bool? value) async {
                        setState(() {
                          task.isDone = value ?? false;
                        });
                        await widget.taskRepository.updateTask(task);
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: NavBar(
        selectedIndex: selectedIndex,
        subjectController: subjectController,
        descriptionController: descriptionController,
        dateController: _dateController,
        timeController: _timeController,
        selectedRemind: _selectedRemind,
        remindList: _remindList,
        selectCategory: _selectedCategory,
        categoryList: _categoryList,
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        onSelectedRemindChange: (int? value) {
          if (value != null) {
            setState(() {
              _selectedRemind = value;
            });
          }
        },
        onSelectedCategoryChange: (String? value) {
          if (value != null) {
            setState(() {
              _selectedCategory = value;
            });
          }
        },
        onAddTask: _showAddTaskDialog,
        onNavItemTapped: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}
