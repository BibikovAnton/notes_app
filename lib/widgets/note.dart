class Note {
  int? id;
  String? title;
  String content;
  DateTime date;
  bool isImportant;
  bool isFavorite;
  String? imagePath;

  Note({
    this.id,
    this.title,
    required this.content,
    required this.date,
    this.isImportant = false,
    this.isFavorite = false,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'isImportant': isImportant ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'imagePath': imagePath,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: DateTime.parse(map['date']),
      isImportant: map['isImportant'] == 1,
      isFavorite: map['isFavorite'] == 1,
      imagePath: map['imagePath'],
    );
  }
}
