import 'package:flutter/material.dart';

import '../../design/brand_theme.dart';
import '../map_document_controller.dart';

class MapPlaceSheet extends StatelessWidget {
  const MapPlaceSheet({
    super.key,
    required this.place,
    required this.programming,
    required this.onClose,
    required this.onNavigate,
  });

  final MapPlace place;
  final List<Map<String, String>> programming;
  final VoidCallback onClose;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('map-place-sheet'),
      elevation: 12,
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon(place.category), color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar detalle',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (place.venue != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Programación de hoy',
                style: TextStyle(
                  color: AppColors.goldDk,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 5),
              if (programming.isEmpty)
                const Text('Sin presentaciones programadas para este día')
              else
                ...programming
                    .take(3)
                    .map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '${event['time']} · ${event['title']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
            ],
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.directions_walk_rounded),
                label: const Text('Ir caminando'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _icon(String category) => switch (category) {
    'bano' => Icons.wc_rounded,
    'acceso' => Icons.login_rounded,
    'salida' => Icons.exit_to_app_rounded,
    'comida' => Icons.restaurant_rounded,
    'parqueo' => Icons.local_parking_rounded,
    'evento' => Icons.mic_rounded,
    _ => Icons.place_rounded,
  };
}
