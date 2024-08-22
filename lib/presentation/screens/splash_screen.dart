import 'package:flutter/material.dart';
import 'package:moon_notes/presentation/screens/note_list_screen.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  @override
  void initState() {
    super.initState();
    routing();
  }

  Future<void> routing() async {
    await Future.delayed(Duration(seconds: 2));
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => NoteListScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          height: 50,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Moon-',
              style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.w800,
                  color: const Color.fromARGB(255, 136, 91, 249)),
            ),
            Text(
              'Notes',
              style: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.w800,
                  color: Colors.black),
            )
          ],
        ),
        SizedBox(
          height: 30,
        ),
        Image.asset('assets/images/logo.jpg'),
      ]),
    );
  }
}
