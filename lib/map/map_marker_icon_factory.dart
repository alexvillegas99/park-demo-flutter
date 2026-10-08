import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../design/brand_theme.dart';
import 'map_document_controller.dart';

class MapMarkerIconFactory {
  static const double _venueCenterLongitude = -78.647792380582;

  final Map<String, Future<BitmapDescriptor>> _cache =
      <String, Future<BitmapDescriptor>>{};

  Future<BitmapDescriptor> create(
    MapPlace place, {
    required bool selected,
    required double devicePixelRatio,
  }) {
    final presentation = place.markerPresentation;
    final cacheKey = <Object>[
      presentation.iconKey,
      place.category,
      presentation.isLarge,
      presentation.showsLabel ? place.name : '',
      _labelOnLeft(place),
      selected,
      devicePixelRatio.toStringAsFixed(1),
    ].join('|');
    return _cache.putIfAbsent(
      cacheKey,
      () => _render(
        place,
        selected: selected,
        devicePixelRatio: devicePixelRatio,
      ),
    );
  }

  static Offset anchorFor(MapPlace place) {
    if (!place.markerPresentation.isLarge) return const Offset(.5, 1);
    return _labelOnLeft(place) ? const Offset(.84, 1) : const Offset(.16, 1);
  }

  static bool _labelOnLeft(MapPlace place) =>
      place.longitude > _venueCenterLongitude;

  Future<BitmapDescriptor> _render(
    MapPlace place, {
    required bool selected,
    required double devicePixelRatio,
  }) async {
    final presentation = place.markerPresentation;
    final logicalSize = presentation.isLarge
        ? const Size(190, 70)
        : Size.square(selected ? 72 : 64);
    final ratio = devicePixelRatio.clamp(2.0, 3.0);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    if (presentation.isLarge) {
      _drawFeaturedMarker(canvas, logicalSize, place, selected);
    } else {
      _drawPinMarker(canvas, logicalSize, place, selected);
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (logicalSize.width * ratio).ceil(),
      (logicalSize.height * ratio).ceil(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    final bytes = Uint8List.view(byteData.buffer);
    return BitmapDescriptor.bytes(
      bytes,
      width: logicalSize.width,
      height: logicalSize.height,
    );
  }

  void _drawPinMarker(Canvas canvas, Size size, MapPlace place, bool selected) {
    final centerX = size.width / 2;
    final pin = _pinPath(
      centerX: centerX,
      top: 4,
      radius: selected ? 27 : 24,
      bottom: size.height - 3,
    );
    canvas.drawShadow(pin, Colors.black.withValues(alpha: .34), 5, true);
    canvas.drawPath(pin, Paint()..color = _backgroundFor(place));
    canvas.drawPath(
      pin,
      Paint()
        ..color = selected ? AppColors.gold : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 4.5 : 3,
    );
    _drawGlyph(
      canvas,
      place.markerPresentation.iconKey,
      Offset(centerX, selected ? 31 : 28),
      selected ? 31 : 27,
      Colors.white,
      _backgroundFor(place),
    );
  }

  void _drawFeaturedMarker(
    Canvas canvas,
    Size size,
    MapPlace place,
    bool selected,
  ) {
    final labelOnLeft = _labelOnLeft(place);
    final pinCenter = Offset(labelOnLeft ? 160 : 30, 29);
    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelOnLeft ? 4 : 24, 8, size.width - 28, 49),
      const Radius.circular(22),
    );
    final pillPath = Path()..addRRect(pill);
    canvas.drawShadow(pillPath, Colors.black.withValues(alpha: .32), 5, true);
    canvas.drawRRect(pill, Paint()..color = Colors.white);
    canvas.drawRRect(
      pill,
      Paint()
        ..color = selected ? AppColors.gold : AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 3.5 : 2,
    );

    final pin = _pinPath(
      centerX: pinCenter.dx,
      top: 2,
      radius: selected ? 27 : 25,
      bottom: size.height - 2,
    );
    canvas.drawShadow(pin, Colors.black.withValues(alpha: .32), 5, true);
    canvas.drawPath(pin, Paint()..color = _backgroundFor(place));
    canvas.drawPath(
      pin,
      Paint()
        ..color = selected ? AppColors.gold : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 4.5 : 3,
    );
    _drawGlyph(
      canvas,
      place.markerPresentation.iconKey,
      pinCenter,
      selected ? 31 : 28,
      Colors.white,
      _backgroundFor(place),
    );

    final painter = TextPainter(
      text: TextSpan(
        text: place.name,
        style: const TextStyle(
          color: AppColors.primaryDk,
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
      ),
      maxLines: 2,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 68);
    painter.paint(
      canvas,
      Offset(labelOnLeft ? 12 : 59, 32 - painter.height / 2),
    );
  }

  Path _pinPath({
    required double centerX,
    required double top,
    required double radius,
    required double bottom,
  }) {
    final left = centerX - radius;
    final right = centerX + radius;
    final centerY = top + radius;
    return Path()
      ..moveTo(centerX, bottom)
      ..cubicTo(centerX - 5, bottom - 9, left, centerY + 14, left, centerY)
      ..cubicTo(left, centerY - radius, centerX - 12, top, centerX, top)
      ..cubicTo(centerX + 12, top, right, centerY - radius, right, centerY)
      ..cubicTo(right, centerY + 14, centerX + 5, bottom - 9, centerX, bottom)
      ..close();
  }

  Color _backgroundFor(MapPlace place) {
    return switch (place.markerPresentation.iconKey) {
      'dinosaur' => const Color(0xFF2E7D32),
      'farm' => const Color(0xFFC5762A),
      'slide' => const Color(0xFFDE5B3E),
      'park' || 'rides' => const Color(0xFF6946A5),
      'moon' => const Color(0xFF51458E),
      'sun' => const Color(0xFFD99400),
      'restroom' => const Color(0xFF2878B8),
      'entrance' => AppColors.green,
      'exit' => const Color(0xFFD53A3A),
      'food' => const Color(0xFFE27824),
      'parking' => const Color(0xFF4655A8),
      'water' => const Color(0xFF278CA6),
      'medical' => const Color(0xFFC62828),
      'zone' => const Color(0xFF24726F),
      _ => AppColors.primary,
    };
  }

  void _drawGlyph(
    Canvas canvas,
    String iconKey,
    Offset center,
    double size,
    Color foreground,
    Color background,
  ) {
    switch (iconKey) {
      case 'dinosaur':
        _drawDinosaur(canvas, center, size, foreground, background);
      case 'farm':
        _drawCow(canvas, center, size, foreground, background);
      case 'slide':
        _drawSlide(canvas, center, size, foreground);
      case 'bull':
        _drawBull(canvas, center, size, foreground, background);
      default:
        _drawMaterialIcon(
          canvas,
          _materialIcon(iconKey),
          center,
          size,
          foreground,
        );
    }
  }

  IconData _materialIcon(String iconKey) => switch (iconKey) {
    'stage' => Icons.mic_rounded,
    'moon' => Icons.nightlight_round,
    'sun' => Icons.wb_sunny_rounded,
    'park' => Icons.attractions_rounded,
    'rides' => Icons.toys_rounded,
    'comedy' => Icons.theater_comedy_rounded,
    'military' => Icons.shield_rounded,
    'restroom' => Icons.wc_rounded,
    'entrance' => Icons.login_rounded,
    'exit' => Icons.logout_rounded,
    'attraction' => Icons.stars_rounded,
    'food' => Icons.restaurant_rounded,
    'parking' => Icons.local_parking_rounded,
    'ticket' => Icons.confirmation_number_rounded,
    'medical' => Icons.medical_services_rounded,
    'water' => Icons.water_drop_rounded,
    'scanner' => Icons.qr_code_scanner_rounded,
    'zone' => Icons.grid_view_rounded,
    _ => Icons.info_rounded,
  };

  void _drawMaterialIcon(
    Canvas canvas,
    IconData icon,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          inherit: false,
          color: color,
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  void _drawDinosaur(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
    Color detail,
  ) {
    canvas.save();
    canvas.translate(center.dx - size / 2, center.dy - size / 2);
    canvas.scale(size / 24);
    final fill = Paint()..color = color;
    canvas.drawOval(const Rect.fromLTWH(5, 9, 13, 8), fill);
    canvas.drawPath(
      Path()
        ..moveTo(6, 11)
        ..lineTo(1, 8)
        ..lineTo(5, 15)
        ..close(),
      fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(15, 11)
        ..cubicTo(16, 8, 16, 4, 19, 3)
        ..lineTo(22, 4)
        ..lineTo(21, 8)
        ..lineTo(18, 9)
        ..lineTo(18, 14)
        ..close(),
      fill,
    );
    final legs = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(8, 15), const Offset(7, 21), legs);
    canvas.drawLine(const Offset(15, 15), const Offset(16, 21), legs);
    canvas.drawCircle(const Offset(20.3, 5.1), .8, Paint()..color = detail);
    canvas.restore();
  }

  void _drawCow(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
    Color detail,
  ) {
    canvas.save();
    canvas.translate(center.dx - size / 2, center.dy - size / 2);
    canvas.scale(size / 24);
    final fill = Paint()..color = color;
    canvas.drawOval(const Rect.fromLTWH(5, 4, 14, 17), fill);
    canvas.drawOval(const Rect.fromLTWH(1, 5, 7, 5), fill);
    canvas.drawOval(const Rect.fromLTWH(16, 5, 7, 5), fill);
    canvas.drawPath(
      Path()
        ..moveTo(6, 6)
        ..lineTo(4, 1)
        ..lineTo(9, 5)
        ..close(),
      fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(18, 6)
        ..lineTo(20, 1)
        ..lineTo(15, 5)
        ..close(),
      fill,
    );
    canvas.drawOval(
      const Rect.fromLTWH(8, 14, 8, 5),
      Paint()..color = detail.withValues(alpha: .75),
    );
    canvas.drawCircle(const Offset(9, 10), 1, Paint()..color = detail);
    canvas.drawCircle(const Offset(15, 10), 1, Paint()..color = detail);
    canvas.restore();
  }

  void _drawSlide(Canvas canvas, Offset center, double size, Color color) {
    canvas.save();
    canvas.translate(center.dx - size / 2, center.dy - size / 2);
    canvas.scale(size / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(const Offset(7, 5), const Offset(7, 21), stroke);
    canvas.drawLine(const Offset(3, 9), const Offset(10, 9), stroke);
    canvas.drawLine(const Offset(3, 14), const Offset(10, 14), stroke);
    canvas.drawPath(
      Path()
        ..moveTo(7, 5)
        ..lineTo(14, 5)
        ..cubicTo(14, 12, 16, 17, 22, 20),
      stroke,
    );
    canvas.drawCircle(const Offset(14, 3), 2, Paint()..color = color);
    canvas.restore();
  }

  void _drawBull(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
    Color detail,
  ) {
    canvas.save();
    canvas.translate(center.dx - size / 2, center.dy - size / 2);
    canvas.scale(size / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(const Rect.fromLTWH(1, 2, 10, 9), 3.2, 2.5, false, stroke);
    canvas.drawArc(const Rect.fromLTWH(13, 2, 10, 9), -2.5, 2.5, false, stroke);
    canvas.drawOval(const Rect.fromLTWH(6, 5, 12, 16), Paint()..color = color);
    canvas.drawCircle(const Offset(10, 12), 1, Paint()..color = detail);
    canvas.drawCircle(const Offset(14, 12), 1, Paint()..color = detail);
    canvas.restore();
  }
}
