import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/task.dart';


class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with SingleTickerProviderStateMixin {
  List<Task> _tasks = [];
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDescriptionController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }

  // Load tasks from SharedPreferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];

    setState(() {
      _tasks = tasksJson
          .map((taskJson) => Task.fromJson(jsonDecode(taskJson)))
          .toList();
    });
  }

  // Save tasks to SharedPreferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = _tasks
        .map((task) => jsonEncode(task.toJson()))
        .toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  void _addTask() {
    if (_taskTitleController.text.isNotEmpty) {
      setState(() {
        _tasks.add(Task(
          title: _taskTitleController.text,
          description: _taskDescriptionController.text,
        ));
        _taskTitleController.clear();
        _taskDescriptionController.clear();
      });
      _saveTasks();
      Navigator.pop(context);
    }
  }

  void _toggleTaskStatus(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
    _saveTasks();

    // If task is completed, switch to completed tab
    if (_tasks[index].isCompleted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _tabController.animateTo(1);
      });
    } else {
      // If task is uncompleted, switch to active tab
      Future.delayed(const Duration(milliseconds: 300), () {
        _tabController.animateTo(0);
      });
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskTitleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'Enter task title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _taskDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Task Description',
                hintText: 'Enter task description (optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addTask,
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(Task task, int index) {
    final TextEditingController titleController = TextEditingController(text: task.title);
    final TextEditingController descriptionController = TextEditingController(text: task.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Task Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _tasks[index].title = titleController.text;
                _tasks[index].description = descriptionController.text;
              });
              _saveTasks();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => _toggleTaskStatus(index),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: task.description.isNotEmpty
            ? Text(
          task.description,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showTaskDetails(task, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _tasks.removeAt(index);
                });
                _saveTasks();
              },
            ),
          ],
        ),
        onTap: () => _showTaskDetails(task, index),
      ),
    );
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter tasks into active and completed
    final activeTasks = _tasks.where((task) => !task.isCompleted).toList();
    final completedTasks = _tasks.where((task) => task.isCompleted).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('To-Do List'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Active (${activeTasks.length})',
              icon: const Icon(Icons.check_box_outline_blank),
            ),
            Tab(
              text: 'Completed (${completedTasks.length})',
              icon: const Icon(Icons.check_box),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Tasks Tab
          activeTasks.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _showAddTaskDialog,
                  child: const Text('Create A Task'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No active tasks. Add a task to get started!',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: activeTasks.length,
            itemBuilder: (context, index) {
              // Find the original index in the complete tasks list
              final originalIndex = _tasks.indexOf(activeTasks[index]);
              return _buildTaskItem(activeTasks[index], originalIndex);
            },
          ),

          // Completed Tasks Tab
          completedTasks.isEmpty
              ? const Center(
            child: Text(
              'No completed tasks yet.',
              style: TextStyle(fontSize: 18),
            ),
          )
              : ListView.builder(
            itemCount: completedTasks.length,
            itemBuilder: (context, index) {
              // Find the original index in the complete tasks list
              final originalIndex = _tasks.indexOf(completedTasks[index]);
              return _buildTaskItem(completedTasks[index], originalIndex);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Task',
      ),
    );
  }
}