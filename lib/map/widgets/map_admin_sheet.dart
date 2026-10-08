import 'package:flutter/material.dart';

import '../../design/brand_theme.dart';
import '../map_document_controller.dart';

class MapAdminSheet extends StatelessWidget {
  const MapAdminSheet({
    super.key,
    required this.places,
    required this.moving,
    required this.adding,
    required this.onToggleMoving,
    required this.onToggleAdding,
    required this.onEdit,
    required this.onHide,
    required this.onRestore,
  });

  final List<MapPlace> places;
  final bool moving;
  final bool adding;
  final VoidCallback onToggleMoving;
  final VoidCallback onToggleAdding;
  final ValueChanged<MapPlace> onEdit;
  final ValueChanged<String> onHide;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Administrar mapa',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Los cambios se validan y guardan con una copia de respaldo.',
              style: TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onToggleMoving,
                    icon: const Icon(Icons.open_with_rounded),
                    label: Text(
                      moving ? 'Finalizar movimiento' : 'Mover puntos',
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onToggleAdding,
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: Text(adding ? 'Cancelar' : 'Agregar punto'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRestore,
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Restaurar respaldo anterior'),
            ),
            const SizedBox(height: 10),
            const Divider(),
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      place.isVisible
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                      color: place.isVisible
                          ? AppColors.primary
                          : AppColors.inkSoft,
                    ),
                    title: Text(
                      place.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(place.category),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('admin-edit-${place.id}'),
                          tooltip: 'Editar punto',
                          onPressed: () => onEdit(place),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                        if (place.isVisible)
                          IconButton(
                            tooltip: 'Ocultar punto',
                            onPressed: () => onHide(place.id),
                            icon: const Icon(Icons.visibility_off_rounded),
                          )
                        else
                          const Text('Oculto'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
