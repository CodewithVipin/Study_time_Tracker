/* ------------------- MODELS USED IN MEMORY ------------------- */

class StudySubject {
  int? id; // null until saved in DB
  String name;
  int seconds;
  bool isRunning;

  StudySubject({
    this.id,
    required this.name,
    this.seconds = 0,
    this.isRunning = false,
  });

  factory StudySubject.fromRow(Map<String, dynamic> row) {
    return StudySubject(
      id: row['id'] as int,
      name: row['name'] as String,
      seconds: row['seconds'] as int,
      isRunning: false,
    );
  }
}
