import 'package:flutter/material.dart';

class Styles {

  static ButtonStyle buttonStyle({Color color = Colors.indigo,
    Color background = Colors.transparent
  }) {

    return OutlinedButton.styleFrom(
      backgroundColor: background,
      side: BorderSide(width: 1.5, color: color),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
    );
  }

}
