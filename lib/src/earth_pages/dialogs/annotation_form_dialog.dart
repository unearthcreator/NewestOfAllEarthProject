import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';

Future<Map<String, String>?> showAnnotationFormDialog(
  BuildContext context, {
  required String title,
  required IconData chosenIcon,
  required String date,
}) async {
  logger.i('Showing annotation form dialog (icon, title, date, note).');
  final noteController = TextEditingController();

  return showDialog<Map<String, String>?>(
    context: context,
    builder: (dialogContext) {
      final screenWidth = MediaQuery.of(dialogContext).size.width;
      return AlertDialog(
        content: SizedBox(
          width: screenWidth * 0.5, // 50% of screen width
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row with icon (left), title (center, bigger), date (right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(chosenIcon),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    Text(
                      date,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    hintText: 'Enter note',
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              logger.i('User cancelled annotation form dialog.');
              Navigator.of(dialogContext).pop(null);
            },
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              final note = noteController.text.trim();
              logger.i('User pressed save in annotation form dialog, note=$note.');
              Navigator.of(dialogContext).pop({
                'note': note,
              });
            },
          ),
        ],
      );
    },
  );
}