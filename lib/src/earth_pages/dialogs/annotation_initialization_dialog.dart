import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/earth_pages/dialogs/map_icon_selection_dialog.dart'; // For showIconSelectionDialog

Future<Map<String, dynamic>?> showAnnotationInitializationDialog(BuildContext context) async {
  logger.i('Showing initial form dialog (title, icon, date).');
  final titleController = TextEditingController();
  final dateController = TextEditingController();

  IconData chosenIcon = Icons.star;

  return showDialog<Map<String, dynamic>?>(
    context: context,
    barrierDismissible: false, // Ensures user can't dismiss by tapping outside
    builder: (dialogContext) {
      final screenWidth = MediaQuery.of(dialogContext).size.width;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SizedBox(
              width: screenWidth * 0.5,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            logger.i('Close icon tapped in initial form dialog.');
                            Navigator.of(dialogContext).pop(null);
                          },
                          child: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Title:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: titleController,
                      maxLength: 25,
                      decoration: InputDecoration(
                        hintText: 'Max 25 characters',
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.5),
                        ),
                        counterText: '',
                      ),
                      buildCounter: (context, {required int currentLength, required bool isFocused, required int? maxLength}) {
                        if (maxLength == null) return null;
                        if (currentLength == 0) {
                          return null; // No counter if no characters typed
                        } else {
                          return Text(
                            '$currentLength/$maxLength',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Icon:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(chosenIcon),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            logger.i('Opening icon selection dialog from initial form dialog.');
                            final selectedIcon = await showIconSelectionDialog(dialogContext);
                            logger.i('Icon selection dialog returned: $selectedIcon');
                            if (selectedIcon != null) {
                              setState(() {
                                chosenIcon = selectedIcon;
                              });
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        hintText: 'Enter date',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Continue'),
                onPressed: () {
                  logger.i('Continue pressed in initial form dialog.');
                  Navigator.of(dialogContext).pop({
                    'title': titleController.text.trim(),
                    'icon': chosenIcon,
                    'date': dateController.text.trim(),
                  });
                },
              ),
            ],
          );
        },
      );
    },
  );
}