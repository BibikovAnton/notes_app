import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moon_notes/consts/const_color.dart';
import 'package:moon_notes/main.dart';
import 'package:moon_notes/providers/confetti_provider.dart';
import 'package:moon_notes/widgets/note.dart';
import 'package:provider/provider.dart';

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
        title: Text('добавить заметку'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
              hintText: 'заголовок',
            ),
          ),
          SizedBox(height: 20),
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 20),
          ValueListenableBuilder<bool>(
            valueListenable: isImportant,
            builder: (context, value, child) {
              return SwitchListTile(
                activeColor: Colors.teal,
                title: Text('Отметить как важное'),
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
            child: Text('Выберите изображение с камеры'),
          ),
          ElevatedButton(
            onPressed: () {
              _pickImage(ImageSource.gallery);
            },
            child: Text('Выберите изображение из галереи'),
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
            child: Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
