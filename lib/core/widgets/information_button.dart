import 'package:flutter/material.dart';

class InformationButton extends StatelessWidget {
  const InformationButton({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: title,
    icon: const Icon(Icons.info_outline_rounded, size: 20),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    ),
  );
}
