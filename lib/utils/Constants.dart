
import 'package:flutter/material.dart';

class Constants {
  static const String PAU = 'Pau';
  static const String JACK = 'Jack';
  static const String SUM_UP = 'Summary';
  static const String DELETE = 'delete';
  static const String EDIT = 'edit';

  // static const String SERVER_ADDRESS = 'http://10.0.2.2:8080/'; // locally on computer -> android studio needs that
  // static const String SERVER_ADDRESS = 'http://192.168.0.17:8080'; // asus computer
  // static const String SERVER_ADDRESS = 'http://192.168.0.108:8080/'; // this computer as service
  static String SERVER_IP = '34.118.121.246';  // gcp vm
  static String SERVER_ADDRESS = 'http://$SERVER_IP:8080/';  // gcp vm


  static getDeviceWidthForList(BuildContext context) {
    return MediaQuery.of(context).size.width * 0.95;
  }

  static getDeviceHeightForList(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.95;
  }

}



