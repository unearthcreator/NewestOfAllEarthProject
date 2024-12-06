import 'package:flutter/material.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/carousel.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/world_selector_buttons.dart';
import 'package:map_mvp_project/services/error_handler.dart';

class WorldSelectorPage extends StatelessWidget {
  const WorldSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      logger.i('Building WorldSelectorPage widget');

      final double screenHeight = MediaQuery.of(context).size.height;
      final double availableHeight = screenHeight - 56 - 40;

      logger.d('Screen height: $screenHeight, Available height for carousel: $availableHeight');

      return Scaffold(
        body: Column(
          children: [
            const WorldSelectorButtons(),
            Expanded(
              child: Center(
                child: CarouselWidget(
                  availableHeight: availableHeight,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      logger.e('Error building WorldSelectorPage', error: e, stackTrace: stackTrace);
      return const Center(child: Text('Error loading World Selector'));
    }
  }
}