import 'package:flutter/material.dart';

extension EContext on BuildContext {
  Future<void> navigateTo(Widget toPage, {bool replace = false}) {
    if(replace) {
      return Navigator.pushReplacement(this, MaterialPageRoute(builder: (context) => toPage));
    }

    return Navigator.push(
      this,
      MaterialPageRoute(builder: (context) => toPage),
    );
  }
}
