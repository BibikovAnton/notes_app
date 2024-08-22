import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:moon_notes/main.dart';
import 'package:moon_notes/presentation/screens/deleted_notes_screen.dart';
import 'package:moon_notes/presentation/screens/favorite_notes_screen.dart';
import 'package:moon_notes/presentation/screens/note_add_screen.dart';
import 'package:moon_notes/providers/confetti_provider.dart';
import 'package:moon_notes/widgets/note_card.dart';
import 'package:provider/provider.dart';

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
                'Меню',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text(
                'Удаленные заметки  🗑️',
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
              title: Text('Любимые заметки  ⭐️',
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
              prefixIcon: Icon(Icons.search),
              label: Text('Поиск...'),
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
