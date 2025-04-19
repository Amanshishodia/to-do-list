class Task {
  String title;
  String description;
  bool isCompleted;

  Task({
    required this.title,
    this.description = '',
    this.isCompleted = false
  });

  // Convert Task to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  // Create Task from JSON data
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'],
    );
  }
}