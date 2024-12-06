import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart'; // Import logger
import 'package:map_mvp_project/src/starting_pages/main_menu/widgets/menu_button.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MenuButton(
              icon: Icons.public,
              label: 'Go to Worlds',
              onPressed: () {
                logger.i('Navigating to World Selector Page');
                Navigator.pushNamed(context, '/world_selector');
              },
            ),
            const SizedBox(height: 20),
            MenuButton(
              icon: Icons.settings,
              label: 'Options',
              onPressed: () {
                logger.i('Options button clicked');
                // Placeholder for Options functionality
              },
            ),
            const SizedBox(height: 20),
            MenuButton(
              icon: Icons.star,
              label: 'Subscription',
              onPressed: () {
                logger.i('Subscription button clicked');
                // Placeholder for Subscription functionality
              },
            ),
            const SizedBox(height: 20),
            MenuButton(
              icon: Icons.exit_to_app,
              label: 'Exit',
              onPressed: () {
                logger.i('Exit button clicked');
                // Placeholder for exit functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}