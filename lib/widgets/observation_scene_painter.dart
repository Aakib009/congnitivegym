import 'package:flutter/material.dart';

/// Renders high-resolution local image assets for all Observation Challenge scenarios.
class ObservationSceneWidget extends StatelessWidget {
  final String? imagePath;
  final String sceneType;

  const ObservationSceneWidget({
    super.key,
    this.imagePath,
    required this.sceneType,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePath = imagePath ?? _resolveImagePath(sceneType);

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Image.asset(
            effectivePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static String _resolveImagePath(String sceneType) {
    switch (sceneType.toLowerCase()) {
      case 'cafe':
        return 'assets/images/observation/CafeProject.jpeg';
      case 'classroom':
        return 'assets/images/observation/ClassRoomProject.jpeg';
      case 'kidspark':
        return 'assets/images/observation/KidsParkProject.jpeg';
      case 'library':
        return 'assets/images/observation/LibraryProject.jpeg';
      case 'livingroom':
        return 'assets/images/observation/LivingRoomProject.jpeg';
      case 'park':
      case 'garden':
        return 'assets/images/observation/ParkProject.jpeg';
      case 'studyroom':
      case 'studydesk':
        return 'assets/images/observation/StudyRoomProject.jpeg';
      case 'workplace':
      case 'office':
        return 'assets/images/observation/WorkPlaceProject.jpeg';
      case 'grocery':
      case 'shopping':
      case 'supermarket':
        return 'assets/images/observation/shoppingProject.jpeg';
      default:
        return 'assets/images/observation/LibraryProject.jpeg';
    }
  }
}
