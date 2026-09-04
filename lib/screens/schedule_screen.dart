import 'package:flutter/material.dart';

import '../api/data_store.dart';
import '../api/models.dart';
import '../design/brand_theme.dart';
import '../widgets/page_eyebrow.dart';

/// "Programación de la semana" — groups `DataStore.upcomingEvents` by day.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Programación',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<Event>>(
        valueListenable: DataStore.instance.upcomingEvents,
        builder: (context, events, _) {
          if (events.isEmpty) {
            return const _EmptySchedule();
          }
          final groups = _groupByDay(events);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final entry = groups[i];
              return Padding(
                padding: EdgeInsets.only(bottom: i == groups.length - 1 ? 0 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageEyebrow(
                      icon: Icons.calendar_today_rounded,
                      label: entry.header.toUpperCase(),
                    ),
                    const SizedBox(height: 8),
                    for (final event in entry.events)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EventCard(event: event),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<_DayGroup> _groupByDay(List<Event> events) {
    final map = <String, List<Event>>{};
    final order = <String>[];
    for (final e in events) {
      final key = e.dayHeader;
      if (!map.containsKey(key)) {
        map[key] = <Event>[];
        order.add(key);
      }
      map[key]!.add(e);
    }
    return order
        .map((k) => _DayGroup(header: k, events: map[k]!))
        .toList();
  }
}

class _DayGroup {
  final String header;
  final List<Event> events;
  const _DayGroup({required this.header, required this.events});
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 48,
              color: AppColors.goldDk.withValues(alpha: .7),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aún no hay eventos publicados',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vuelve pronto para conocer la agenda de la semana.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.inkSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showEventDetailSheet(context, event),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: .05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      event.time.isEmpty ? '--:--' : event.time,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.music_note_rounded,
                      color: AppColors.gold.withValues(alpha: .85),
                      size: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.tag.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: .22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.tag.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.goldDk,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    Text(
                      event.artist.isNotEmpty ? event.artist : event.venue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (event.venue.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 12,
                              color: AppColors.inkSoft,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                event.venue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared modal to inspect a full [Event]: hero, info tiles, description,
/// lineup, and includes.
void showEventDetailSheet(BuildContext context, Event event) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EventDetailSheet(event: event),
  );
}

class EventDetailSheet extends StatelessWidget {
  final Event event;
  const EventDetailSheet({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.zero,
          children: [
            _Hero(event: event),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.access_time_rounded,
                          title: event.time.isEmpty ? '—' : event.time,
                          subtitle: event.dayHeader,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.place_rounded,
                          title: event.venue.isEmpty ? '—' : event.venue,
                          subtitle: event.expectedAttendees > 0
                              ? '${(event.expectedAttendees / 1000).toStringAsFixed(1)}K asistentes'
                              : 'Aforo por confirmar',
                        ),
                      ),
                    ],
                  ),
                  if (event.priceLabel.isNotEmpty || event.ageLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: _InfoCard(
                              icon: Icons.confirmation_number_outlined,
                              title: event.priceLabel.isEmpty
                                  ? 'Ingreso libre'
                                  : event.priceLabel,
                              subtitle: event.ageLabel.isEmpty
                                  ? 'Toda la familia'
                                  : event.ageLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'Sobre el evento',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (event.lineup.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'Programación',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final l in event.lineup)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LineupRow(item: l),
                      ),
                  ],
                  if (event.includes.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const Text(
                      '¿Qué incluye?',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final it in event.includes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: const BoxDecoration(
                                color: AppColors.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.primary,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                it,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Event event;
  const _Hero({required this.event});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: event.imageUrl.isNotEmpty
                ? Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.primaryDeep),
                  )
                : Container(color: AppColors.primaryDeep),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black87,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .75),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        if (event.live)
          Positioned(
            top: 22,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.coral,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 6),
                  Text(
                    'EN VIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.tag.isNotEmpty)
                Text(
                  event.tag.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFE7C878),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.7,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                event.artist.isNotEmpty ? event.artist : event.venue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineupRow extends StatelessWidget {
  final LineupItem item;
  const _LineupRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.headliner ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.headliner ? AppColors.primary : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: TextStyle(
                    color: item.headliner ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${item.minutes} min',
                  style: TextStyle(
                    color: item.headliner
                        ? Colors.white70
                        : AppColors.inkSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.artist,
                  style: TextStyle(
                    color: item.headliner ? Colors.white : AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (item.style.isNotEmpty)
                  Text(
                    item.style,
                    style: TextStyle(
                      color: item.headliner
                          ? Colors.white70
                          : AppColors.inkSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (item.headliner)
            const Icon(
              Icons.star_rounded,
              color: AppColors.gold,
              size: 18,
            ),
        ],
      ),
    );
  }
}
