import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Task {
  String id;
  String title;
  String description;
  String date;
  String time;
  int selectedRemind;
  String selectedCategory;
  bool isDone;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.selectedRemind,
    required this.selectedCategory,
    this.isDone = false,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      selectedRemind: data['selectedRemind'] ?? 0,
      selectedCategory: data['selectedCategory'] ?? 'Other',
      isDone: data['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'selectedRemind': selectedRemind,
      'selectedCategory': selectedCategory,
      'isDone': isDone,
    };
  }
}

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String? _userId = _auth.currentUser?.uid;
  late CollectionReference _tasksCollection;

  TaskRepository() {
    _userId = _auth.currentUser?.uid ?? '';
    _tasksCollection = _firestore.collection('users').doc(_userId).collection('todo');
  }

  Future<void> addTask(Task task) async {
    try {
      await _tasksCollection.add(task.toFirestore());
      print('Task added: ${task.toFirestore()}');
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (_userId == null) {
      print('User is not authenticated');
      return;
    }
    try {
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    if (_userId == null) {
      print('User is not authenticated');
      return;
    }
    try {
      await _tasksCollection.doc(task.id).set(task.toFirestore());
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    if (_userId == null) {
      print('User is not authenticated');
      return;
    }
    try {
      final doc = await _tasksCollection.doc(taskId).get();
      if (doc.exists) {
        final task = Task.fromFirestore(doc);
        await _tasksCollection.doc(taskId).update({'isDone': !task.isDone});
      }
    } catch (e) {
      print('Error toggling task completion: $e');
    }
  }

  Stream<List<Task>> getTasks() {
    if (_userId == null) {
      return Stream.empty();
    }
    return _tasksCollection.snapshots().map((QuerySnapshot snapshot) {
      print('Tasks fetched: ${snapshot.docs.length}');
      return snapshot.docs.map((DocumentSnapshot doc) {
        Task task = Task.fromFirestore(doc);
        print('Task fetched: ${task.title}, Date: ${task.date}');
        return task;
      }).toList();
    });
  }
}