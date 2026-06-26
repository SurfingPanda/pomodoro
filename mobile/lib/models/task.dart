/// A to-do task belonging to the current user.
class Task {
  final int id;
  final String title;
  final bool isDone;

  Task({required this.id, required this.title, required this.isDone});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      isDone: json['is_done'] as bool,
    );
  }
}
