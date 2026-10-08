import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/brand_theme.dart';
import '../map_view_model.dart';

class MapSearchFilters extends StatelessWidget {
  const MapSearchFilters({
    super.key,
    required this.viewModel,
    required this.onShowAll,
  });

  static const double overlayHeight = 146;

  final MapViewModel viewModel;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          elevation: 6,
          shadowColor: AppColors.ink.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(19),
          child: TextField(
            key: const Key('map-search-field'),
            onChanged: viewModel.setSearch,
            decoration: InputDecoration(
              hintText: 'Buscar baños, escenarios, accesos…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'Ver todo',
                onPressed: onShowAll,
                icon: const Icon(Icons.center_focus_strong_rounded),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) => SizedBox(
            height: 82,
            child: ListView.separated(
              key: const Key('map-category-scroll'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: MapCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final category = MapCategory.values[index];
                return _MapCategoryButton(
                  key: Key('map-category-${category.name}'),
                  category: category,
                  selected: viewModel.state.category == category,
                  onTap: () => viewModel.setCategory(category),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MapCategoryButton extends StatelessWidget {
  const _MapCategoryButton({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final MapCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _CategoryVisual.from(category);
    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      child: AnimatedScale(
        scale: selected ? 1 : .94,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 72,
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
              decoration: BoxDecoration(
                color: selected
                    ? visual.color.withValues(alpha: .14)
                    : Colors.white.withValues(alpha: .96),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? visual.color : AppColors.line,
                  width: selected ? 2.2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? visual.color.withValues(alpha: .28)
                        : AppColors.ink.withValues(alpha: .10),
                    blurRadius: selected ? 10 : 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 45,
                        child: CustomPaint(
                          painter: _CategoryArtworkPainter(
                            category: category,
                            color: visual.color,
                            selected: selected,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        visual.shortLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? visual.color : AppColors.ink,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  if (selected)
                    Positioned(
                      key: Key('map-category-selection-${category.name}'),
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryVisual {
  const _CategoryVisual(this.shortLabel, this.color);

  final String shortLabel;
  final Color color;

  factory _CategoryVisual.from(MapCategory category) {
    switch (category) {
      case MapCategory.all:
        return const _CategoryVisual('Todos', AppColors.primary);
      case MapCategory.events:
        return const _CategoryVisual('Eventos', Color(0xFFB03060));
      case MapCategory.bathrooms:
        return const _CategoryVisual('Baños', Color(0xFF1976C9));
      case MapCategory.accesses:
        return const _CategoryVisual('Accesos', Color(0xFF257B47));
      case MapCategory.exits:
        return const _CategoryVisual('Salidas', Color(0xFFD1453F));
      case MapCategory.attractions:
        return const _CategoryVisual('Atracciones', Color(0xFFE07424));
      case MapCategory.food:
        return const _CategoryVisual('Comida', Color(0xFF9D4A2A));
      case MapCategory.services:
        return const _CategoryVisual('Servicios', Color(0xFF6654A3));
      case MapCategory.parking:
        return const _CategoryVisual('Parqueo', Color(0xFF356D9C));
      case MapCategory.zones:
        return const _CategoryVisual('Zonas', Color(0xFF527C58));
    }
  }
}

class _CategoryArtworkPainter extends CustomPainter {
  const _CategoryArtworkPainter({
    required this.category,
    required this.color,
    required this.selected,
  });

  final MapCategory category;
  final Color color;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      size.shortestSide * .48,
      Paint()..color = color.withValues(alpha: selected ? .18 : .10),
    );

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (category) {
      case MapCategory.all:
        _paintAll(canvas, fill);
        break;
      case MapCategory.events:
        _paintStage(canvas, fill, stroke);
        break;
      case MapCategory.bathrooms:
        _paintBathrooms(canvas, fill);
        break;
      case MapCategory.accesses:
        _paintDoor(canvas, fill, stroke, exiting: false);
        break;
      case MapCategory.exits:
        _paintDoor(canvas, fill, stroke, exiting: true);
        break;
      case MapCategory.attractions:
        _paintFerrisWheel(canvas, fill, stroke);
        break;
      case MapCategory.food:
        _paintFood(canvas, fill, stroke);
        break;
      case MapCategory.services:
        _paintInformation(canvas, fill, stroke);
        break;
      case MapCategory.parking:
        _paintParking(canvas, fill);
        break;
      case MapCategory.zones:
        _paintZones(canvas, fill, stroke);
        break;
    }
  }

  void _paintAll(Canvas canvas, Paint fill) {
    final star = Path()
      ..moveTo(22.5, 8)
      ..lineTo(25.8, 17.7)
      ..lineTo(36, 21)
      ..lineTo(25.8, 24.3)
      ..lineTo(22.5, 34)
      ..lineTo(19.2, 24.3)
      ..lineTo(9, 21)
      ..lineTo(19.2, 17.7)
      ..close();
    canvas.drawPath(star, fill);
    canvas.drawCircle(const Offset(34.5, 10), 2.4, fill);
    canvas.drawCircle(const Offset(11, 33), 1.8, fill);
  }

  void _paintStage(Canvas canvas, Paint fill, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 10, 29, 25),
        const Radius.circular(4),
      ),
      fill,
    );
    final light = Paint()..color = Colors.white.withValues(alpha: .92);
    final curtain = Path()
      ..moveTo(11, 13)
      ..quadraticBezierTo(17, 22, 11, 32)
      ..lineTo(18, 32)
      ..quadraticBezierTo(21, 22, 18, 13)
      ..close();
    canvas.drawPath(curtain, light);
    canvas.save();
    canvas.translate(27, 16);
    canvas.rotate(-math.pi / 6);
    canvas.drawCircle(Offset.zero, 4, light);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-1.4, 3, 2.8, 13),
        const Radius.circular(2),
      ),
      light,
    );
    canvas.restore();
    canvas.drawLine(const Offset(7, 37), const Offset(38, 37), stroke);
  }

  void _paintBathrooms(Canvas canvas, Paint fill) {
    canvas.drawCircle(const Offset(16, 11), 4.2, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(11.5, 16, 9, 16),
        const Radius.circular(3),
      ),
      fill,
    );
    canvas.drawRect(const Rect.fromLTWH(13, 30, 3, 7), fill);
    canvas.drawRect(const Rect.fromLTWH(18, 30, 3, 7), fill);
    canvas.drawCircle(const Offset(30, 11), 4.2, fill);
    final dress = Path()
      ..moveTo(30, 16)
      ..lineTo(23.5, 31)
      ..lineTo(27.5, 31)
      ..lineTo(27.5, 37)
      ..lineTo(32.5, 37)
      ..lineTo(32.5, 31)
      ..lineTo(36.5, 31)
      ..close();
    canvas.drawPath(dress, fill);
  }

  void _paintDoor(
    Canvas canvas,
    Paint fill,
    Paint stroke, {
    required bool exiting,
  }) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 8, 19, 29),
        const Radius.circular(3),
      ),
      stroke,
    );
    canvas.drawCircle(const Offset(23.5, 23), 1.6, fill);
    final arrow = Path();
    if (exiting) {
      arrow
        ..moveTo(20, 22.5)
        ..lineTo(36, 22.5)
        ..moveTo(31, 17)
        ..lineTo(36.5, 22.5)
        ..lineTo(31, 28);
    } else {
      arrow
        ..moveTo(37, 22.5)
        ..lineTo(21, 22.5)
        ..moveTo(26, 17)
        ..lineTo(20.5, 22.5)
        ..lineTo(26, 28);
    }
    canvas.drawPath(arrow, stroke);
  }

  void _paintFerrisWheel(Canvas canvas, Paint fill, Paint stroke) {
    const center = Offset(22.5, 21);
    canvas.drawCircle(center, 12, stroke);
    canvas.drawCircle(center, 2.7, fill);
    for (var index = 0; index < 8; index++) {
      final angle = math.pi * index / 4;
      final edge = Offset(
        center.dx + math.cos(angle) * 12,
        center.dy + math.sin(angle) * 12,
      );
      canvas.drawLine(center, edge, stroke);
      canvas.drawCircle(edge, 2.2, fill);
    }
    canvas.drawLine(center, const Offset(15, 39), stroke);
    canvas.drawLine(center, const Offset(30, 39), stroke);
    canvas.drawLine(const Offset(11, 39), const Offset(34, 39), stroke);
  }

  void _paintFood(Canvas canvas, Paint fill, Paint stroke) {
    canvas.drawCircle(const Offset(23, 23), 10, stroke);
    canvas.drawCircle(const Offset(23, 23), 5.5, stroke);
    canvas.drawLine(const Offset(9, 9), const Offset(9, 36), stroke);
    for (final x in <double>[6.5, 9, 11.5]) {
      canvas.drawLine(Offset(x, 9), Offset(x, 17), stroke);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 8, 3.5, 28),
        const Radius.circular(2),
      ),
      fill,
    );
    canvas.drawOval(const Rect.fromLTWH(33, 8, 7.5, 10), fill);
  }

  void _paintInformation(Canvas canvas, Paint fill, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 8, 25, 29),
        const Radius.circular(7),
      ),
      stroke,
    );
    canvas.drawCircle(const Offset(22.5, 15), 2.4, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20.5, 20, 4, 11),
        const Radius.circular(2),
      ),
      fill,
    );
    canvas.drawLine(const Offset(7, 38), const Offset(38, 38), stroke);
  }

  void _paintParking(Canvas canvas, Paint fill) {
    final body = Path()
      ..moveTo(7, 25)
      ..lineTo(11, 16)
      ..quadraticBezierTo(12, 13, 16, 13)
      ..lineTo(29, 13)
      ..quadraticBezierTo(33, 13, 34, 16)
      ..lineTo(38, 25)
      ..lineTo(38, 32)
      ..lineTo(7, 32)
      ..close();
    canvas.drawPath(body, fill);
    final glass = Paint()..color = Colors.white.withValues(alpha: .8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14, 16, 17, 7),
        const Radius.circular(2),
      ),
      glass,
    );
    final tire = Paint()..color = AppColors.ink;
    canvas.drawCircle(const Offset(13, 33), 3.4, tire);
    canvas.drawCircle(const Offset(32, 33), 3.4, tire);
  }

  void _paintZones(Canvas canvas, Paint fill, Paint stroke) {
    final pale = Paint()..color = color.withValues(alpha: .28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 9, 14, 12),
        const Radius.circular(3),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 7, 14, 16),
        const Radius.circular(3),
      ),
      pale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 24, 12, 13),
        const Radius.circular(3),
      ),
      pale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 26, 14, 11),
        const Radius.circular(3),
      ),
      fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(4, 28)
        ..quadraticBezierTo(22, 15, 41, 30),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _CategoryArtworkPainter oldDelegate) {
    return oldDelegate.category != category ||
        oldDelegate.color != color ||
        oldDelegate.selected != selected;
  }
}
