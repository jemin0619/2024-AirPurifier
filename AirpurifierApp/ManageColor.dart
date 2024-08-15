import 'package:flutter/material.dart';

class ColorProvider with ChangeNotifier {
  Color _PM25Color = Colors.grey;
  Color _filterColor = Colors.grey;
  Color get PM25Color => _PM25Color;
  Color get filterColor => _filterColor;

  void setPM25Color(Color color) {
    _PM25Color = color;
    notifyListeners();
  }

  void setfilterColor(Color color){
    _filterColor = color;
    notifyListeners();
  }
}