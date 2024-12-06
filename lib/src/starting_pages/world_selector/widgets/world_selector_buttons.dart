import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';

class WorldSelectorButtons extends StatelessWidget {
  const WorldSelectorButtons({super.key});

  @override
  Widget build(BuildContext context) {
    logger.i('Building WorldSelectorButtons widget');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              try {
                Navigator.pop(context); // Navigate back to MainMenuPage
                logger.i('WorldSelectorButtons: Back button pressed, navigating to MainMenuPage');
              } catch (e, stackTrace) {
                logger.e('WorldSelectorButtons: Error navigating back to MainMenuPage', error: e, stackTrace: stackTrace);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              try {
                logger.i('WorldSelectorButtons: Settings button pressed');
                // Future: Add settings functionality here
              } catch (e, stackTrace) {
                logger.e('WorldSelectorButtons: Error handling settings action', error: e, stackTrace: stackTrace);
              }
            },
          ),
        ],
      ),
    );
  }
}