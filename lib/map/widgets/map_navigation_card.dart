import 'package:flutter/material.dart';

import '../../design/brand_theme.dart';

class MapNavigationCard extends StatelessWidget {
  const MapNavigationCard({
    super.key,
    required this.destination,
    required this.remainingMeters,
    required this.progress,
    required this.onStop,
  });

  final String destination;
  final double remainingMeters;
  final double progress;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('map-navigation-card'),
      color: Colors.white,
      elevation: 10,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              child: Icon(Icons.directions_walk_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text('${remainingMeters.round()} m restantes'),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(value: progress),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Detener ruta',
              onPressed: onStop,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
