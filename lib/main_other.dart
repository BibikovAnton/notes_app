import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moon_notes/main.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AnimatedNotesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => ConfettiProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Notes',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness:
                  themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
            ),
            home: NameInputScreen(),
          );
        },
      ),
    );
  }
}

class ConfettiProvider with ChangeNotifier {
  final ConfettiController _controller =
      ConfettiController(duration: const Duration(seconds: 1));

  ConfettiController get controller => _controller;

  void play() {
    _controller.play();
    notifyListeners();
  }

  void stop() {
    _controller.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  late Database _database;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'theme.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE theme(id INTEGER PRIMARY KEY, isDarkMode INTEGER)',
        );
      },
    );
    await _loadTheme();
  }

  Future<void> _saveNoteToDatabase(Note note) async {
    await _database.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _updateNoteInDatabase(Note note) async {
    await _database.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> _loadTheme() async {
    final List<Map<String, dynamic>> maps = await _database.query('theme');
    if (maps.isNotEmpty) {
      _isDarkMode = maps.first['isDarkMode'] == 1;
      notifyListeners();
    }
  }

  Future<void> _saveTheme() async {
    await _database.insert(
      'theme',
      {'id': 0, 'isDarkMode': _isDarkMode ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }
}

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

class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];
  List<Note> _deletedNotes = [];
  List<Note> _filteredNotes = [];
  List<Note> _favoriteNotes = [];
  late Database _database;

  List<Note> get notes => _filteredNotes.isEmpty ? _notes : _filteredNotes;
  List<Note> get deletedNotes => _deletedNotes;
  List<Note> get favoriteNotes => _favoriteNotes;

  NoteProvider() {
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'notes.db');
    _database = await openDatabase(
      path,
      version: 4, // Increment the version to trigger the onUpgrade method
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, date TEXT, isImportant INTEGER, isFavorite INTEGER, imagePath TEXT)', // Added imagePath
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute(
              'ALTER TABLE notes ADD COLUMN isImportant INTEGER DEFAULT 0');
        }
        if (oldVersion < 3) {
          db.execute(
              'ALTER TABLE notes ADD COLUMN isFavorite INTEGER DEFAULT 0');
        }
        if (oldVersion < 4) {
          // Upgrade to version 4 to add imagePath
          db.execute('ALTER TABLE notes ADD COLUMN imagePath TEXT');
        }
      },
    );
    await _loadNotes();
  }

  Future<void> _loadNotes() async {
    final List<Map<String, dynamic>> maps = await _database.query('notes');
    _notes = List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
    _favoriteNotes = _notes.where((note) => note.isFavorite).toList();
    notifyListeners();
  }

  Future<void> _saveNoteToDatabase(Note note) async {
    await _database.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _removeNoteFromDatabase(int id) async {
    await _database.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _updateNoteInDatabase(Note note) async {
    await _database.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  void addNote(Note note) {
    _notes.add(note);
    if (note.isFavorite) {
      _favoriteNotes.add(note);
    }
    _saveNoteToDatabase(note);
    notifyListeners();
  }

  void removeNote(Note note) {
    _notes.remove(note);
    _deletedNotes.add(note);
    if (note.isFavorite) {
      _favoriteNotes.remove(note);
    }
    _removeNoteFromDatabase(note.id ?? 0);
    notifyListeners();
  }

  void restoreNote(Note note) {
    _deletedNotes.remove(note);
    addNote(note);
    notifyListeners();
  }

  void permanentlyDeleteNote(Note note) {
    _deletedNotes.remove(note);
    notifyListeners();
  }

  void updateNote(Note note) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      if (note.isFavorite) {
        final favoriteIndex = _favoriteNotes.indexWhere((n) => n.id == note.id);
        if (favoriteIndex != -1) {
          _favoriteNotes[favoriteIndex] = note;
        } else {
          _favoriteNotes.add(note);
        }
      } else {
        _favoriteNotes.removeWhere((n) => n.id == note.id);
      }
      _updateNoteInDatabase(note);
      notifyListeners();
    }
  }

  void toggleFavorite(Note note) {
    note.isFavorite = !note.isFavorite;
    if (note.isFavorite) {
      _favoriteNotes.add(note);
    } else {
      _favoriteNotes.remove(note);
    }
    _saveNoteToDatabase(note);
    notifyListeners();
  }

  void swapNotesOrder() {
    _notes = _notes.reversed.toList();
    notifyListeners();
  }

  void searchNotes(String query) {
    if (query.isEmpty) {
      _filteredNotes = [];
    } else {
      _filteredNotes = _notes.where((note) {
        return (note.title?.contains(query) ?? false) ||
            note.content.contains(query);
      }).toList();
    }
    notifyListeners();
  }

  void searchNotesByDate(DateTime startDate, DateTime endDate) {
    _filteredNotes = _notes.where((note) {
      return note.date.isAfter(startDate) && note.date.isBefore(endDate);
    }).toList();
    notifyListeners();
  }

  void shareNote(BuildContext context, Note note) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final String text = '${note.title ?? 'Untitled'}\n\n${note.content}';
    Share.share(text,
        subject: note.title ?? 'Untitled',
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }
}

class NoteListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final noteProvider = Provider.of<NoteProvider>(context);
    final confettiProvider = Provider.of<ConfettiProvider>(context);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.black : Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text(
                'Deleted Notes  🗑️',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeletedNotesScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Favorite Notes  ⭐️',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FavoriteNotesScreen()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: SizedBox(
          height: 50,
          child: TextField(
            decoration: InputDecoration(
              label: Text('Search notes...'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              hintStyle: TextStyle(color: Colors.white60),
            ),
            style: TextStyle(color: Colors.white),
            onChanged: (query) {
              noteProvider.searchNotes(query);
            },
          ),
        ),
        actions: [
          IconButton(
            icon: themeProvider.isDarkMode
                ? Icon(Icons.brightness_7)
                : Icon(Icons.brightness_2),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(Icons.swap_vert),
            onPressed: () {
              noteProvider.swapNotesOrder();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<NoteProvider>(
            builder: (context, noteProvider, child) {
              return ListView.builder(
                itemCount: noteProvider.notes.length,
                itemBuilder: (context, index) {
                  final note = noteProvider.notes[index];
                  return NoteCard(note: note);
                },
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConfettiWidget(
              confettiController: confettiProvider.controller,
              blastDirection: -3.14 / 2, // вверх
              maxBlastForce: 30, // максимальная сила выброса
              minBlastForce: 20, // минимальная сила выброса
              emissionFrequency: 0.05, // частота выброса конфетти
              numberOfParticles: 20, // количество частиц
              gravity: 0.04, // гравитация конфетти
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NoteAddScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final Note note;

  NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(note.title ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.content),
            SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().format(note.date),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              note.isImportant ? 'Important' : '',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              note.isFavorite ? 'Favorite' : '',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (note.imagePath != null) // Проверка на наличие изображения
              Image.file(
                  File(note.imagePath!)), // Отображение изображения из пути
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      note.isFavorite ? Icons.star : Icons.star_border,
                      color: note.isFavorite ? Colors.yellow : null,
                    ),
                    onPressed: () {
                      Provider.of<NoteProvider>(context, listen: false)
                          .toggleFavorite(note);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteEditScreen(note: note),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      Provider.of<NoteProvider>(context, listen: false)
                          .removeNote(note);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () {
                      Provider.of<NoteProvider>(context, listen: false)
                          .shareNote(context, note);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteAddScreen extends StatefulWidget {
  @override
  _NoteAddScreenState createState() => _NoteAddScreenState();
}

class _NoteAddScreenState extends State<NoteAddScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final ValueNotifier<bool> isImportant = ValueNotifier<bool>(false);
  File? _image;

  void _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final confettiProvider =
        Provider.of<ConfettiProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Note'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              labelText: 'Title',
            ),
          ),
          SizedBox(height: 20),
          TextField(
            maxLines: 15,
            controller: contentController,
            decoration: InputDecoration(
              hintText: 'Content',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 20),
          ValueListenableBuilder<bool>(
            valueListenable: isImportant,
            builder: (context, value, child) {
              return SwitchListTile(
                title: Text('Mark as Important'),
                value: value,
                onChanged: (newValue) {
                  isImportant.value = newValue;
                },
              );
            },
          ),
          SizedBox(height: 20),
          _image != null ? Image.file(_image!) : SizedBox.shrink(),
          ElevatedButton(
            onPressed: () {
              _pickImage(ImageSource.camera);
            },
            child: Text('Pick Image from Camera'),
          ),
          ElevatedButton(
            onPressed: () {
              _pickImage(ImageSource.gallery);
            },
            child: Text('Pick Image from Gallery'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final note = Note(
                title: titleController.text,
                content: contentController.text,
                date: DateTime.now(),
                isImportant: isImportant.value,
                imagePath: _image?.path,
              );
              Provider.of<NoteProvider>(context, listen: false).addNote(note);
              confettiProvider.play();
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}

class NoteEditScreen extends StatefulWidget {
  final Note note;

  NoteEditScreen({required this.note});

  @override
  _NoteEditScreenState createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  pickMyImage(ImageSource source) async {
    File? file;
    //Откуда мы берем фотографию
    final result = await ImagePicker().pickImage(source: source);

    if (result == null) return;
    var image = result;

    setState(() {});
  }

  pickMyFile() async {
    FilePickerResult? resultFile = await FilePicker.platform.pickFiles();

    if (resultFile != null) {
      File file = File(resultFile.files.single.path!);
    } else {
      // User canceled the picker
    }
  }

  late TextEditingController titleController;
  late TextEditingController contentController;
  late bool isImportant;
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
    contentController = TextEditingController(text: widget.note.content);
    isImportant = widget.note.isImportant;
    isFavorite = widget.note.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Edit Note'),
        ),
        body: ListView.builder(
          itemCount: 1,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: 'Title'),
                ),
                SizedBox(
                  height: 20,
                ),
                TextField(
                  maxLines: 15,
                  controller: contentController,
                  decoration: InputDecoration(
                    hintText: 'Content',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SwitchListTile(
                  title: Text('Mark as Important'),
                  value: isImportant,
                  onChanged: (newValue) {
                    setState(() {
                      isImportant = newValue;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    final updatedNote = Note(
                      id: widget.note.id,
                      title: titleController.text,
                      content: contentController.text,
                      date: widget.note.date,
                      isImportant: isImportant,
                      isFavorite: isFavorite,
                    );
                    Provider.of<NoteProvider>(context, listen: false)
                        .updateNote(updatedNote);
                    Navigator.pop(context);
                  },
                  child: Text('Update'),
                ),
              ],
            ),
          ),
        ));
  }
}

class DeletedNotesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Deleted Notes'),
      ),
      body: ListView.builder(
        itemCount: noteProvider.deletedNotes.length,
        itemBuilder: (context, index) {
          final note = noteProvider.deletedNotes[index];
          return ListTile(
            title: Text(note.title ?? ''),
            subtitle: Text(note.content),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.restore),
                  onPressed: () {
                    noteProvider.restoreNote(note);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_forever),
                  onPressed: () {
                    noteProvider.permanentlyDeleteNote(note);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FavoriteNotesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Notes'),
      ),
      body: ListView.builder(
        itemCount: noteProvider.favoriteNotes.length,
        itemBuilder: (context, index) {
          final note = noteProvider.favoriteNotes[index];
          return NoteCard(note: note);
        },
      ),
    );
  }
}

class UserNameInputScreen extends StatefulWidget {
  @override
  _UserNameInputScreenState createState() => _UserNameInputScreenState();
}

class _UserNameInputScreenState extends State<UserNameInputScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Your Name'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String name = _nameController.text;
                if (name.isNotEmpty) {
                  Provider.of<UserProvider>(context, listen: false)
                      .setName(name);
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class UserProvider with ChangeNotifier {
  String? _name;

  String? get name => _name;

  void setName(String name) {
    _name = name;
    notifyListeners();
  }
}
