
import 'package:flutter/material.dart';

class Constants {
  static final String DESIRED_WIFI = 'Senatus Populusque Internetum';
  // static const String DESIRED_WIFI = 'AndroidWifi';
  static const String PAU = 'Pau';
  static const String JACK = 'Jack';
  static const String SUM_UP = 'Summary';
  static const String DELETE = 'delete';
  static const String EDIT = 'edit';

  static getDeviceWidthForList(BuildContext context) {
    return MediaQuery.of(context).size.width * 0.95;
  }

  static getDeviceHeightForList(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.95;
  }

}



