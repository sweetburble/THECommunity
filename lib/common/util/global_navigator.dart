import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GlobalNavigator {
  static void showToast({
    required String msg,
  }) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
