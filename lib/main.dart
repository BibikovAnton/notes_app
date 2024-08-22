
import 'package:flutter/material.dart';

import 'package:moon_notes/presentation/screens/splash_screen.dart';
import 'package:moon_notes/providers/confetti_provider.dart';

import 'package:moon_notes/unfocus.dart';
import 'package:moon_notes/widgets/note.dart';
import 'package:provider/provider.dart';

import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(TextFieldUnfocus(child: HomePage()));
}

class HomePage extends StatelessWidget {
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
          return TextFieldUnfocus(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Notes',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                brightness: themeProvider.isDarkMode
                    ? Brightness.dark
                    : Brightness.light,
              ),
              home: NameInputScreen(),
            ),
          );
        },
      ),
    );
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
      version: 4,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, date TEXT, isImportant INTEGER, isFavorite INTEGER, imagePath TEXT)',
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
