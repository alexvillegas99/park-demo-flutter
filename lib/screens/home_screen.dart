import 'package:flutter/material.dart';

import '../api/data_store.dart';
import '../api/models.dart' as api;
import '../design/brand_theme.dart';
import 'schedule_screen.dart';

class HomeScreen extends StatelessWidget {
  final String displayName;
  final VoidCallback? onOpenPackages;
  final VoidCallback? onOpenRuni;
  final VoidCallback? onOpenAccount;

  const HomeScreen({
    super.key,
    required this.displayName,
    this.onOpenPackages,
    this.onOpenRuni,
    this.onOpenAccount,
  });

  void _openSchedule(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ScheduleScreen()),
    );
  }

  static const _defaultAttractions =
      <({String name, String zone, String wait, String imageAsset})>[
        (
          name: 'Resbaladera Gigante',
          zone: 'Zona Norte',
          wait: '5 min',
          imageAsset: 'assets/attractions/resbaladera-gigante.png',
        ),
        (
          name: 'Bosque de Dinosaurios',
          zone: 'Zona Norte',
          wait: '10 min',
          imageAsset: 'assets/attractions/bosque-dinosaurios.png',
        ),
        (
          name: 'Paseo en Tren',
          zone: 'Recorrido',
          wait: '5 min',
          imageAsset: 'assets/attractions/paseo-tren.png',
        ),
        (
          name: 'Granja interactiva',
          zone: 'Zona Familiar',
          wait: 'Sin fila',
          imageAsset: 'assets/attractions/granja-interactiva.png',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: DataStore.instance.notifier,
      builder: (context, _, __) {
        final apiAttractions = DataStore.instance.attractions;
        return ColoredBox(
          color: AppColors.surface,
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 138),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MrHeader(onAccount: onOpenAccount),
                  const SizedBox(height: 24),
                  Text(
                    '¡Hola, ${displayName.trim()}!',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 29,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '¿Qué aventura vivimos hoy?',
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: onOpenRuni,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryDeep,
                            AppColors.primary,
                            AppColors.coral,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .28),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: .18),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: .6),
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RUNI · TU GUÍA CON IA',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Hay poca fila en la Resbaladera Gigante. ¡Ve antes de las 11h!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.3,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.gold,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ValueListenableBuilder<api.Event?>(
                    valueListenable: DataStore.instance.todayEvent,
                    builder: (context, todayEvent, _) => _TodayEventBadge(
                      event: todayEvent,
                      onOpenSchedule: () => _openSchedule(context),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const Key('home-open-schedule'),
                      onPressed: () => _openSchedule(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                      ),
                      icon: const Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Ver agenda de la semana',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Atracciones populares',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        'Ver todas',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 196,
                    child: apiAttractions.isNotEmpty
                        ? ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: apiAttractions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, index) =>
                                _HomeAttractionApiCard(
                                    attraction: apiAttractions[index]),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _defaultAttractions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, index) => _HomeAttractionCard(
                                attraction: _defaultAttractions[index]),
                          ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryDeep,
                          AppColors.primary,
                          AppColors.primaryDk,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDeep.withValues(alpha: .3),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -22,
                          top: -36,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold.withValues(alpha: .12),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SOLO SÁBADOS',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '2x1 en el paquete '),
                                  TextSpan(
                                    text: 'All Day',
                                    style: TextStyle(color: AppColors.gold),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Dinosaurios, piscinas, tren, cabalgata y más. Todo el día, toda la familia.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: onOpenPackages,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.primaryDeep,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 17,
                                  vertical: 11,
                                ),
                              ),
                              child: const Text(
                                'Ver paquetes',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(
                        child: _HomeStat(value: '12', label: 'Atracciones'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _HomeStat(value: '09–18h', label: 'Abierto hoy'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _HomeStat(value: 'Km 12', label: 'Vía Riobamba'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TodayEventBadge extends StatelessWidget {
  final api.Event? event;
  final VoidCallback onOpenSchedule;
  const _TodayEventBadge({required this.event, required this.onOpenSchedule});

  @override
  Widget build(BuildContext context) {
    final ev = event;
    if (ev == null) {
      // Fallback when nothing is scheduled for today (API returned 404).
      return Semantics(
        button: true,
        label: 'Ver la agenda semanal',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onOpenSchedule,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line, width: 1.4),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.goldDk.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.event_note_outlined,
                      color: AppColors.goldDk,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AGENDA',
                          style: TextStyle(
                            color: AppColors.goldDk,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'No hay show programado para hoy',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Mira la agenda semanal',
                          style: TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
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
        ),
      );
    }
    return Semantics(
      button: true,
      label: 'Ver detalle del evento del día',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showEventDetailSheet(context, ev),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line, width: 1.4),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ev.tag.isEmpty ? 'EVENTO DEL DÍA' : ev.tag,
                        style: const TextStyle(
                          color: AppColors.goldDk,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ev.artist.isEmpty ? ev.venue : ev.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${ev.venue} · ${ev.time}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _MrHeader extends StatelessWidget {
  final VoidCallback? onAccount;
  const _MrHeader({this.onAccount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              colors: [AppColors.primaryDk, AppColors.primaryDeep],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'MR',
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMPLEJO INTERCULTURAL Y DEPORTIVO',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.goldDk,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.15,
                ),
              ),
              Text(
                'Mushuc Runa',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 21,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          shape: CircleBorder(
            side: BorderSide(color: AppColors.gold, width: 2),
          ),
          child: InkWell(
            key: const Key('home-account-button'),
            customBorder: const CircleBorder(),
            onTap: onAccount,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeAttractionCard extends StatelessWidget {
  final ({String name, String zone, String wait, String imageAsset}) attraction;

  const _HomeAttractionCard({required this.attraction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 166,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .1),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 108,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  attraction.imageAsset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppColors.primarySoft,
                    child: Icon(
                      Icons.attractions_rounded,
                      color: AppColors.primary,
                      size: 44,
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x66000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 9,
                  top: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      attraction.wait,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attraction.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '★ 4.9 · ${attraction.zone}',
                  style: const TextStyle(
                    color: AppColors.goldDk,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
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

class _HomeAttractionApiCard extends StatelessWidget {
  final api.Attraction attraction;
  const _HomeAttractionApiCard({required this.attraction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 166,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .1),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 108,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (attraction.imageUrl.isNotEmpty)
                  Image.network(
                    attraction.imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => _placeholder(attraction.emoji),
                  )
                else
                  _placeholder(attraction.emoji),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x66000000)],
                    ),
                  ),
                ),
                if (attraction.featured)
                  Positioned(
                    left: 9,
                    top: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'DESTACADO',
                        style: TextStyle(
                          color: AppColors.primaryDeep,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attraction.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (attraction.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    attraction.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.goldDk,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(String emoji) => ColoredBox(
        color: AppColors.primarySoft,
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 44)),
        ),
      );
}

class _HomeStat extends StatelessWidget {
  final String value;
  final String label;

  const _HomeStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
