import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moon_notes/main.dart';
import 'package:moon_notes/presentation/screens/note_edit_screen.dart';
import 'package:moon_notes/widgets/note.dart';
import 'package:provider/provider.dart';

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
              note.isImportant ? 'Важное' : '',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              note.isFavorite ? 'Любимое' : '',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (note.imagePath != null) Image.file(File(note.imagePath!)),
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
