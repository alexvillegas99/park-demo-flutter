import 'package:flutter/material.dart';

import '../../design/brand_theme.dart';
import '../map_document_controller.dart';

class MapAdminPlaceDraft {
  const MapAdminPlaceDraft({
    required this.name,
    required this.category,
    required this.isVisible,
    required this.isFeatured,
    required this.events,
  });

  final String name;
  final String category;
  final bool isVisible;
  final bool isFeatured;
  final List<Map<String, Object?>> events;
}

class MapAdminPlaceDialog extends StatefulWidget {
  const MapAdminPlaceDialog({super.key, required this.place});

  final MapPlace place;

  @override
  State<MapAdminPlaceDialog> createState() => _MapAdminPlaceDialogState();
}

class _MapAdminPlaceDialogState extends State<MapAdminPlaceDialog> {
  static const _categories = <String, String>{
    'evento': 'Evento',
    'show': 'Show',
    'bano': 'Baños',
    'acceso': 'Acceso',
    'salida': 'Salida',
    'comida': 'Comida',
    'servicio': 'Servicio',
    'parqueo': 'Parqueo',
    'zona': 'Zona',
  };

  late final TextEditingController _name;
  late String _category;
  late bool _isVisible;
  late bool _isFeatured;
  late final List<_AdminEventControllers> _events;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.place.name);
    _category = widget.place.category;
    _isVisible = widget.place.isVisible;
    _isFeatured = widget.place.isFeatured;
    _events = widget.place.events
        .map(
          (event) => _AdminEventControllers(
            time: '${event['time'] ?? ''}',
            title: '${event['title'] ?? ''}',
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _name.dispose();
    for (final event in _events) {
      event.dispose();
    }
    super.dispose();
  }

  void _addEvent() {
    setState(() {
      _events.add(_AdminEventControllers(time: '', title: ''));
      _error = null;
    });
  }

  void _removeEvent(int index) {
    setState(() {
      _events.removeAt(index).dispose();
      _error = null;
    });
  }

  void _save() {
    final name = _name.text.trim();
    final events = <Map<String, Object?>>[];
    if (name.isEmpty) {
      setState(() => _error = 'Escribe un nombre para el punto.');
      return;
    }
    for (final event in _events) {
      final time = event.time.text.trim();
      final title = event.title.text.trim();
      if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(time) ||
          title.isEmpty) {
        setState(
          () => _error = 'Completa cada evento con hora HH:mm y nombre.',
        );
        return;
      }
      events.add(<String, Object?>{'time': time, 'title': title});
    }
    Navigator.of(context).pop(
      MapAdminPlaceDraft(
        name: name,
        category: _category,
        isVisible: _isVisible,
        isFeatured: _isFeatured,
        events: events,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar punto'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('admin-place-name'),
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.place_rounded),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('admin-place-category'),
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categories.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              SwitchListTile.adaptive(
                key: const Key('admin-place-visible'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Visible para visitantes'),
                value: _isVisible,
                onChanged: (value) => setState(() => _isVisible = value),
              ),
              SwitchListTile.adaptive(
                key: const Key('admin-place-featured'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Punto destacado'),
                subtitle: const Text('Se muestra con mayor prioridad.'),
                value: _isFeatured,
                onChanged: (value) => setState(() => _isFeatured = value),
              ),
              const Divider(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Eventos del punto',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('admin-add-event'),
                    onPressed: _addEvent,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              for (var index = 0; index < _events.length; index++) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: TextField(
                        key: Key('admin-event-time-$index'),
                        controller: _events[index].time,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(labelText: 'Hora'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: Key('admin-event-title-$index'),
                        controller: _events[index].title,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: 'Evento'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar evento',
                      onPressed: () => _removeEvent(index),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('admin-save-place'),
          onPressed: _save,
          child: const Text('Guardar cambios'),
        ),
      ],
    );
  }
}

class _AdminEventControllers {
  _AdminEventControllers({required String time, required String title})
    : time = TextEditingController(text: time),
      title = TextEditingController(text: title);

  final TextEditingController time;
  final TextEditingController title;

  void dispose() {
    time.dispose();
    title.dispose();
  }
}
