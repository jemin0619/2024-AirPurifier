import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SwitchProvider with ChangeNotifier {
  bool _isActive = false;
  Color _color = Colors.grey;

  bool get isActive => _isActive;
  Color get color => _color;

  void setSwitch(bool value) {
    _isActive = value;
    if(value==true) _color = Colors.black;
    else _color = Colors.grey;
    notifyListeners();
  }

  void toggleSwitch() {
    _isActive = !_isActive;
    notifyListeners();
  }
}
