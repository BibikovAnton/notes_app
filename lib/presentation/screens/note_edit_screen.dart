import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moon_notes/consts/const_color.dart';
import 'package:moon_notes/main.dart';
import 'package:moon_notes/widgets/note.dart';
import 'package:provider/provider.dart';

class NoteEditScreen extends StatefulWidget {
  final Note note;

  NoteEditScreen({required this.note});

  @override
  _NoteEditScreenState createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  pickMyImage(ImageSource source) async {
    File? file;

    final result = await ImagePicker().pickImage(source: source);

    if (result == null) return;
    var image = result;

    setState(() {});
  }

  pickMyFile() async {
    FilePickerResult? resultFile = await FilePicker.platform.pickFiles();

    if (resultFile != null) {
      File file = File(resultFile.files.single.path!);
    } else {}
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
          title: Text('Редактировать заметку'),
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
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: lightPurple),
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: purpleColor)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: 'заголовок'),
                ),
                SizedBox(
                  height: 20,
                ),
                TextField(
                  maxLines: 15,
                  controller: contentController,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: lightPurple),
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: purpleColor)),
                    hintText: 'содержание',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SwitchListTile(
                  activeColor: Colors.teal,
                  title: Text('отметить как важное'),
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
                  child: Text('Редактирование'),
                ),
              ],
            ),
          ),
        ));
  }
}
