import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const TodoApp());
}

// Task model class
class Task {
  String title;
  bool isCompleted;

  Task({required this.title, this.isCompleted = false});

  // Convert task to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  // Create task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final Color _primaryColor = const Color.fromARGB(255, 15, 138, 238);
  final Color _secondaryColor = const Color.fromARGB(255, 45, 152, 240);
  List<Task> tasks = [];
  final TextEditingController _typedTextController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Get file path for storing tasks
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/tasks.json');
  }

  // Save tasks to file
  Future<void> _saveTasks() async {
    try {
      final file = await _localFile;
      final taskMap = {
        'data': tasks. map((task) => task.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(taskMap));
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  // Load tasks from file
  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final taskMap = jsonDecode(contents);
        final taskList = List<Map<String, dynamic>>.from(taskMap['data']);
        
        setState(() {
          tasks = taskList.map((taskJson) => Task.fromJson(taskJson)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add new task
  void _addTask() {
    final text = _typedTextController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        tasks.insert(0, Task(title: text));
        _typedTextController.clear();
        _saveTasks();
      });
    }
  }

  // Toggle task completion status
  void _toggleTaskCompletion(int index) {
    setState(() {
      tasks[index].isCompleted = !tasks[index].isCompleted;
      _saveTasks();
    });
  }

  // Delete task
  void _deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
      _saveTasks();
    });
  }

  // Build task list items
  List<Widget> _buildTaskItems() {
    return List.generate(tasks.length, (index) {
      final task = tasks[index];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Dismissible(
          key: Key('task_${task.title}_$index'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteTask(index),
          child: Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              leading: Checkbox(
                value: task.isCompleted,
                activeColor: _primaryColor,
                onChanged: (_) => _toggleTaskCompletion(index),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted 
                      ? TextDecoration.lineThrough 
                      : TextDecoration.none,
                  color: task.isCompleted ? Colors.grey : Colors.black,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteTask(index),
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: _primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor),
        appBarTheme: AppBarTheme(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              'TODO APP',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
        body: Container( 
          color: _primaryColor.withOpacity(0.3),
          child:  
         Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              //color: _primaryColor.withOpacity(0.2),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _typedTextController,
                      decoration: InputDecoration(
                        hintText: 'Add task',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.task),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 15.0,
                        ),
                      ),
                      onSubmitted: (_) => _addTask(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addTask,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 15.0,
                        horizontal: 15.0,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 5),
                        Text('Add'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _secondaryColor.withOpacity(0.3),
                      Colors.white,
                    ],
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : tasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 80,
                                  color: _primaryColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No tasks yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Add a task to get started',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            children: _buildTaskItems(),
                          ),
              ),
            ),
          ],
        )
      ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              // Filter out completed tasks
              tasks = tasks.where((task) => !task.isCompleted).toList();
              _saveTasks();
            });
          },
          backgroundColor: _primaryColor,
          tooltip: 'Clear completed tasks',
          child: const Icon(Icons.cleaning_services),
        ),
      ),
    );
  }
}