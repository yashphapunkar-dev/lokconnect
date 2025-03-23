import 'package:flutter/material.dart';

void showCustomAlert({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = "OK",
  String cancelText = "Cancel",
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onCancel != null) onCancel();
            },
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onConfirm != null) onConfirm();
            },
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}
