import 'package:flutter/material.dart';

Future<IconData?> showIconSelectionDialog(BuildContext context) async {
  // A small set of icons to choose from
  final icons = [
    Icons.star,
    Icons.flag,
    Icons.home,
    Icons.camera,
    Icons.map,
    Icons.favorite,
  ];

  return showDialog<IconData>(
    context: context,
    builder: (iconDialogContext) {
      return AlertDialog(
        title: const Text('Select an Icon'),
        content: SizedBox(
          width: MediaQuery.of(iconDialogContext).size.width * 0.5,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: icons.map((icon) {
              return GestureDetector(
                onTap: () {
                  // When tapped, return this icon
                  Navigator.of(iconDialogContext).pop(icon);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 32),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}