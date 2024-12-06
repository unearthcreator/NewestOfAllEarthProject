import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/widget_utils/card_tap_handler.dart';

class CarouselWidget extends StatefulWidget {
  final double availableHeight;

  const CarouselWidget({super.key, required this.availableHeight});

  @override
  _CarouselWidgetState createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  int _currentIndex = 4;

  @override
  Widget build(BuildContext context) {
    logger.i('Building CarouselWidget');

    return CarouselSlider.builder(
      itemCount: 10,
      options: CarouselOptions(
        initialPage: _currentIndex,
        height: widget.availableHeight * 0.9,
        enlargeCenterPage: true,
        enlargeStrategy: CenterPageEnlargeStrategy.scale,
        enableInfiniteScroll: false,
        viewportFraction: 0.35,
        onPageChanged: (index, reason) {
          setState(() {
            _currentIndex = index;
          });
          logger.i('Carousel page changed to index $index, reason: $reason');
        },
      ),
      itemBuilder: (context, index, realIdx) {
        double opacity = index == _currentIndex ? 1.0 : 0.2;

        return GestureDetector(
          onTap: () {
            logger.i('Card at index $index tapped.');
            handleCardTap(context, index);
          },
          child: Opacity(
            opacity: opacity,
            child: AspectRatio(
              aspectRatio: 1 / 1.3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  color: Colors.blueAccent,
                ),
                child: Center(
                  child: Text(
                    index == 4 ? 'History Tour' : 'Unearth',
                    style: const TextStyle(
                      fontSize: 24.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}