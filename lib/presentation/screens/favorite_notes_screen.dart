import 'package:flutter/material.dart';
import 'package:moon_notes/main.dart';
import 'package:moon_notes/widgets/note_card.dart';
import 'package:provider/provider.dart';

class FavoriteNotesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Любимые заметки'),
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
