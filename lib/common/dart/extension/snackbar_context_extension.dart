import 'package:flutter/material.dart';

import '../../common.dart';

extension SnackbarContextExtension on BuildContext {
  /// Scaffold안에 Snackbar를 보여준다
  void showSnackbar(
    String message, {
    Widget? extraButton,
    bool isFloating = false,
  }) {
    _showSnackBarWithContext(
      this,
      _SnackbarFactory.createSnackBar(this, message,
          extraButton: extraButton, isFloating: isFloating),
    );
  }

  /// Scaffold안에 빨간색 Snackbar를 보여준다
  void showErrorSnackbar(
    String message, {
    Color bgColor = AppColors.salmon,
    double bottomMargin = 0,
    bool isFloating = false,
  }) {
    _showSnackBarWithContext(
      this,
      _SnackbarFactory.createErrorSnackBar(
        this,
        message,
        bgColor: bgColor,
        bottomMargin: bottomMargin,
        isFloating: isFloating,
      ),
    );
  }
}

void _showSnackBarWithContext(BuildContext context, SnackBar snackbar) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(snackbar);
}

class _SnackbarFactory {
  static SnackBar createSnackBar(
    BuildContext context,
    String message, {
    Color? bgColor,
    Widget? extraButton,
    bool isFloating = false,
  }) {
    Color snackbarBgColor = bgColor ?? context.appColors.snackbarBgColor;
    return SnackBar(
        elevation: 0,
        behavior:
            isFloating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        backgroundColor: Colors.transparent,
        content: Tap(
          onTap: () {
            try {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            } catch (e) {
              // do nothing
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: snackbarBgColor,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontStyle: FontStyle.normal,
                      )),
                ),
                if (extraButton != null) extraButton,
              ],
            ),
          ),
        ));
  }

  static SnackBar createErrorSnackBar(
    BuildContext context,
    String? message, {
    Color bgColor = AppColors.salmon,
    double bottomMargin = 0,
    bool isFloating = false,
  }) {
    return SnackBar(
        elevation: 0,
        behavior: isFloating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        backgroundColor: Colors.transparent,
        content: Tap(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.all(20),
            margin: EdgeInsets.only(bottom: bottomMargin),
            child: Text("$message",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontStyle: FontStyle.normal,
                )),
          ),
        ));
  }
}
