import 'package:flutter/material.dart';

class HistoryProvider extends ChangeNotifier {
  void notifyHistoryChanged() {
    notifyListeners();
  }
} 