import 'package:flutter/material.dart';

Widget? _lastDialog;

void showMissingMedicineDialog(BuildContext context, Function(String) onAdd) {
  if (_lastDialog != null) return; // Prevent double open

  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) {
      _lastDialog = const SizedBox(); // Mark as open
      return AlertDialog(
        title: const Text('إبلاغ عن دواء ناقص'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'اسم الدواء',
            hintText: 'مثال: Panadol Extra',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _lastDialog = null;
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAdd(controller.text);
                Navigator.pop(context);
              }
              _lastDialog = null;
            },
            child: const Text('إضافة'),
          ),
        ],
      );
    },
  ).then((_) => _lastDialog = null);
}
