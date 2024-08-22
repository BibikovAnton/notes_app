import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

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
