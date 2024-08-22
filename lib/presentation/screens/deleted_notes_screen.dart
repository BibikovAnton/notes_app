import 'package:flutter/material.dart';
import 'package:moon_notes/main.dart';

import 'package:provider/provider.dart';

class DeletedNotesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Удаленные заметки'),
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
