import 'package:flutter/material.dart';

import '../../design/brand_theme.dart';
import '../map_document_controller.dart';

@immutable
class MapVenueProgrammingDay {
  const MapVenueProgrammingDay({
    required this.weekday,
    required this.day,
    required this.month,
    required this.fullDate,
    required this.events,
  });

  final String weekday;
  final String day;
  final String month;
  final String fullDate;
  final List<Map<String, String>> events;

  String get id => '$weekday-$day-$month';

  DateTime? dateInYear(int year) {
    final monthNumber = switch (month.toUpperCase()) {
      'ENE' => 1,
      'FEB' => 2,
      'MAR' => 3,
      'ABR' => 4,
      'MAY' => 5,
      'JUN' => 6,
      'JUL' => 7,
      'AGO' => 8,
      'SEP' => 9,
      'OCT' => 10,
      'NOV' => 11,
      'DIC' => 12,
      _ => null,
    };
    final dayNumber = int.tryParse(day);
    if (monthNumber == null || dayNumber == null) return null;
    return DateTime(year, monthNumber, dayNumber);
  }
}

class MapPlaceSheet extends StatefulWidget {
  const MapPlaceSheet({
    super.key,
    required this.place,
    required this.programmingDays,
    required this.onClose,
    required this.onNavigate,
    this.today,
  });

  final MapPlace place;
  final List<MapVenueProgrammingDay> programmingDays;
  final VoidCallback onClose;
  final VoidCallback onNavigate;
  final DateTime? today;

  @override
  State<MapPlaceSheet> createState() => _MapPlaceSheetState();
}

class _MapPlaceSheetState extends State<MapPlaceSheet> {
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _preferredDayIndex(widget.programmingDays, _today);
  }

  @override
  void didUpdateWidget(covariant MapPlaceSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.place.id != widget.place.id ||
        oldWidget.today != widget.today) {
      _selectedDay = _preferredDayIndex(widget.programmingDays, _today);
      return;
    }

    final previousId = _selectedDay < oldWidget.programmingDays.length
        ? oldWidget.programmingDays[_selectedDay].id
        : null;
    final matchingIndex = previousId == null
        ? -1
        : widget.programmingDays.indexWhere((day) => day.id == previousId);
    _selectedDay = matchingIndex >= 0
        ? matchingIndex
        : _preferredDayIndex(widget.programmingDays, _today);
  }

  DateTime get _today => widget.today ?? DateTime.now();

  static int _preferredDayIndex(
    List<MapVenueProgrammingDay> days,
    DateTime today,
  ) {
    final normalized = DateTime(today.year, today.month, today.day);
    final exact = days.indexWhere(
      (day) => day.dateInYear(today.year) == normalized,
    );
    if (exact >= 0) return exact;

    for (var index = 0; index < days.length; index++) {
      final date = days[index].dateInYear(today.year);
      if (date != null && date.isAfter(normalized)) return index;
    }
    return days.isEmpty ? 0 : days.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = widget.programmingDays.isEmpty
        ? null
        : widget.programmingDays[_selectedDay];
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
                  child: Icon(
                    _icon(widget.place.category),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.place.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar detalle',
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (widget.place.venue != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Programación por día',
                style: TextStyle(
                  color: AppColors.goldDk,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 7),
              if (widget.programmingDays.isNotEmpty) ...[
                SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.programmingDays.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final day = widget.programmingDays[index];
                      return _VenueDayButton(
                        key: Key('map-venue-day-$index'),
                        day: day,
                        selected: index == _selectedDay,
                        onTap: () => setState(() => _selectedDay = index),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  selectedDay!.fullDate,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
              ],
              if (selectedDay == null || selectedDay.events.isEmpty)
                const Text('Sin presentaciones programadas para este día')
              else
                ...selectedDay.events.map(
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
                onPressed: widget.onNavigate,
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

class _VenueDayButton extends StatelessWidget {
  const _VenueDayButton({
    super.key,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final MapVenueProgrammingDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: day.fullDate,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 58,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.line,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day.weekday,
                style: TextStyle(
                  color: selected ? AppColors.gold : AppColors.goldDk,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
              Text(
                day.day,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.ink,
                  fontSize: 18,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
