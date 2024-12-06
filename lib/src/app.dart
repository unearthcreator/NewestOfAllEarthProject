// app.dart
import 'package:flutter/material.dart';
import 'package:map_mvp_project/src/starting_pages/main_menu/main_menu.dart'; // Import MainMenuPage as initial screen
import 'package:map_mvp_project/src/starting_pages/world_selector/world_selector.dart'; // Import WorldSelectorPage
import 'package:map_mvp_project/services/error_handler.dart'; // Import logger for error handling

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return MaterialApp(
        title: 'Map MVP Project',
        theme: _buildAppTheme(), // Extracted theme to a separate function for cleaner code
        initialRoute: '/', // Define the initial route (MainMenuPage)
        routes: {
          '/': (context) => const MainMenuPage(), // Set MainMenuPage as initial route
          '/world_selector': (context) => const WorldSelectorPage(), // Define route for WorldSelectorPage
        },
        debugShowCheckedModeBanner: false, // Removes the Debug banner
      );
    } catch (e, stackTrace) {
      logger.e('Error while building MyApp widget', error: e, stackTrace: stackTrace);
      return const SizedBox(); // Return an empty widget if an error occurs
    }
  }

  // Function to build and manage the app theme
  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
    );
  }
}