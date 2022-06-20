import 'package:flutter/material.dart';

class Styles {

  static ButtonStyle buttonStyle() {
    return OutlinedButton.styleFrom(
      backgroundColor: Colors.transparent,
      side: BorderSide(width: 1.0, color: Colors.indigo),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
    );
  }

}
