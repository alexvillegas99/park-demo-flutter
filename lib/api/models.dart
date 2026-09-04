import 'package:flutter/material.dart';

import '../design/brand_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PARSING HELPERS
// ═══════════════════════════════════════════════════════════════════════════
double toDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

int toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

// ═══════════════════════════════════════════════════════════════════════════
// POI
// ═══════════════════════════════════════════════════════════════════════════
enum PoiCategory { event, livestock, autos, food, artisan, service }

PoiCategory _poiCategoryFromString(String? s) {
  switch (s) {
    case 'event':
      return PoiCategory.event;
    case 'livestock':
      return PoiCategory.livestock;
    case 'autos':
      return PoiCategory.autos;
    case 'food':
      return PoiCategory.food;
    case 'artisan':
      return PoiCategory.artisan;
    case 'service':
      return PoiCategory.service;
    default:
      return PoiCategory.service;
  }
}

extension PoiCategoryX on PoiCategory {
  String get label => switch (this) {
    PoiCategory.event => 'Eventos',
    PoiCategory.livestock => 'Ganadería',
    PoiCategory.autos => 'Expo Autos',
    PoiCategory.food => 'Gastronomía',
    PoiCategory.artisan => 'Artesanías',
    PoiCategory.service => 'Servicios',
  };
  IconData get icon => switch (this) {
    PoiCategory.event => Icons.music_note_rounded,
    PoiCategory.livestock => Icons.pets_rounded,
    PoiCategory.autos => Icons.directions_car_rounded,
    PoiCategory.food => Icons.restaurant_rounded,
    PoiCategory.artisan => Icons.palette_rounded,
    PoiCategory.service => Icons.info_outline_rounded,
  };
  Color get color => switch (this) {
    PoiCategory.event => AppColors.primary,
    PoiCategory.livestock => const Color(0xFF7C4A20),
    PoiCategory.autos => const Color(0xFF334155),
    PoiCategory.food => AppColors.orange,
    PoiCategory.artisan => const Color(0xFF9333EA),
    PoiCategory.service => const Color(0xFF0891B2),
  };
}

class Poi {
  final String id, name, description, zone, emoji, imageUrl;
  final PoiCategory category;
  final Offset position;
  final double rating;
  final String? schedule;
  final int? waitMins;
  final double? price;
  final bool featured;
  const Poi({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.position,
    required this.emoji,
    required this.imageUrl,
    this.zone = 'Central',
    this.rating = 4.7,
    this.schedule,
    this.waitMins,
    this.price,
    this.featured = false,
  });

  factory Poi.fromJson(Map<String, dynamic> j) {
    final pos = j['position'];
    double x = 0.5, y = 0.5;
    if (pos is Map) {
      x = toDouble(pos['x'], 0.5);
      y = toDouble(pos['y'], 0.5);
    }
    return Poi(
      id: (j['id'] ?? j['_id'])?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      category: _poiCategoryFromString(j['category']?.toString()),
      position: Offset(x, y),
      emoji: j['emoji']?.toString() ?? '📍',
      imageUrl: j['imageUrl']?.toString() ?? '',
      zone: j['zone']?.toString() ?? 'Central',
      rating: toDouble(j['rating'], 4.7),
      schedule: j['schedule']?.toString(),
      waitMins: j['waitMins'] == null ? null : toInt(j['waitMins']),
      price: j['price'] == null ? null : toDouble(j['price']),
      featured: j['featured'] == true,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EVENT (unified — replaces the removed /today-event model)
// ═══════════════════════════════════════════════════════════════════════════
class LineupItem {
  final String time, artist, role, style;
  final int minutes;
  final bool headliner;
  const LineupItem({
    required this.time,
    required this.artist,
    required this.role,
    required this.style,
    required this.minutes,
    this.headliner = false,
  });

  factory LineupItem.fromJson(Map<String, dynamic> j) => LineupItem(
    time: j['time']?.toString() ?? '',
    artist: j['artist']?.toString() ?? '',
    role: j['role']?.toString() ?? '',
    style: j['style']?.toString() ?? '',
    minutes: toInt(j['minutes']),
    headliner: j['headliner'] == true,
  );
}

/// Unified Event returned by `/events`, `/events/today`, `/events/upcoming`.
/// `date` is an ISO `YYYY-MM-DD` string; `poi` is optional.
class Event {
  final String id;
  final String tag, artist, venue, time, dateLabel, description;
  final String imageUrl;
  final String date;
  final Poi? poi;
  final int expectedAttendees;
  final bool live;
  final String priceLabel, ageLabel;
  final List<String> includes;
  final List<LineupItem> lineup;
  const Event({
    required this.id,
    required this.tag,
    required this.artist,
    required this.venue,
    required this.time,
    required this.dateLabel,
    required this.description,
    required this.imageUrl,
    required this.date,
    required this.poi,
    required this.expectedAttendees,
    this.live = false,
    required this.priceLabel,
    required this.ageLabel,
    required this.includes,
    required this.lineup,
  });

  factory Event.fromJson(Map<String, dynamic> j) {
    final poiJson = j['poi'];
    final poi = poiJson is Map<String, dynamic>
        ? Poi.fromJson(poiJson)
        : (poiJson is Map
            ? Poi.fromJson(Map<String, dynamic>.from(poiJson))
            : null);
    final includes = (j['includes'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final lineup = (j['lineup'] as List?)
            ?.whereType<Map>()
            .map((e) => LineupItem.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <LineupItem>[];
    return Event(
      id: (j['_id'] ?? j['id'])?.toString() ?? '',
      tag: j['tag']?.toString() ?? '',
      artist: j['artist']?.toString() ?? '',
      venue: j['venue']?.toString() ?? '',
      time: j['time']?.toString() ?? '',
      dateLabel: j['dateLabel']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      imageUrl: j['imageUrl']?.toString() ?? '',
      date: j['date']?.toString() ?? '',
      poi: poi,
      expectedAttendees: toInt(j['expectedAttendees']),
      live: j['live'] == true,
      priceLabel: j['priceLabel']?.toString() ?? '',
      ageLabel: j['ageLabel']?.toString() ?? '',
      includes: includes,
      lineup: lineup,
    );
  }

  /// Human-readable day label. Uses `dateLabel` when present, else formats
  /// `date` (YYYY-MM-DD) into a Spanish "Mié 24 de septiembre" style string.
  String get dayHeader {
    if (dateLabel.isNotEmpty) return dateLabel;
    if (date.isEmpty) return 'Fecha por confirmar';
    try {
      final d = DateTime.parse(date);
      const days = [
        'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom',
      ];
      const months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
      ];
      return '${days[d.weekday - 1]} ${d.day} de ${months[d.month - 1]}';
    } catch (_) {
      return date;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESTAURANTS
// ═══════════════════════════════════════════════════════════════════════════
class Dish {
  final String name, description, imageUrl, emoji;
  final double price;
  final bool popular;
  const Dish({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.emoji = '🍽️',
    this.popular = false,
  });

  factory Dish.fromJson(Map<String, dynamic> j) => Dish(
    name: j['name']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    imageUrl: j['imageUrl']?.toString() ?? '',
    price: toDouble(j['price']),
    emoji: j['emoji']?.toString() ?? '🍽️',
    popular: j['popular'] == true,
  );
}

class Restaurant {
  final String id,
      name,
      tagline,
      description,
      coverUrl,
      logoEmoji,
      zone,
      category;
  final double rating;
  final int reviews, waitMins;
  final String schedule;
  final bool featured;
  final List<Dish> dishes;
  const Restaurant({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.coverUrl,
    required this.logoEmoji,
    required this.zone,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.waitMins,
    required this.schedule,
    this.featured = false,
    required this.dishes,
  });

  factory Restaurant.fromJson(Map<String, dynamic> j) {
    final dishes = (j['dishes'] as List?)
            ?.whereType<Map>()
            .map((e) => Dish.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <Dish>[];
    return Restaurant(
      id: (j['id'] ?? j['_id'])?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      tagline: j['tagline']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      coverUrl: j['coverUrl']?.toString() ?? '',
      logoEmoji: j['logoEmoji']?.toString() ?? '🍽️',
      zone: j['zone']?.toString() ?? '',
      category: j['category']?.toString() ?? '',
      rating: toDouble(j['rating'], 4.5),
      reviews: toInt(j['reviews']),
      waitMins: toInt(j['waitMins']),
      schedule: j['schedule']?.toString() ?? '',
      featured: j['featured'] == true,
      dishes: dishes,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PACKAGES
// ═══════════════════════════════════════════════════════════════════════════
class AppPackage {
  final String id, name, tagline, imageUrl, priceLabel;
  final double? price;
  final int? durationHours;
  final bool featured;
  final int order;
  final List<String> includes;
  const AppPackage({
    required this.id,
    required this.name,
    required this.tagline,
    required this.imageUrl,
    required this.priceLabel,
    required this.price,
    required this.durationHours,
    required this.featured,
    required this.order,
    required this.includes,
  });

  factory AppPackage.fromJson(Map<String, dynamic> j) {
    final includes = (j['includes'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    return AppPackage(
      id: (j['id'] ?? j['_id'])?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      tagline: j['tagline']?.toString() ?? '',
      imageUrl: j['imageUrl']?.toString() ?? '',
      priceLabel: j['priceLabel']?.toString() ?? '',
      price: j['price'] == null ? null : toDouble(j['price']),
      durationHours: j['durationHours'] == null ? null : toInt(j['durationHours']),
      featured: j['featured'] == true,
      order: toInt(j['order']),
      includes: includes,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ATTRACTIONS
// ═══════════════════════════════════════════════════════════════════════════
class Attraction {
  final String id, name, description, imageUrl, emoji;
  final int order;
  final bool featured;
  const Attraction({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.emoji,
    required this.order,
    required this.featured,
  });

  factory Attraction.fromJson(Map<String, dynamic> j) => Attraction(
    id: (j['id'] ?? j['_id'])?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    imageUrl: j['imageUrl']?.toString() ?? '',
    emoji: j['emoji']?.toString() ?? '🎢',
    order: toInt(j['order']),
    featured: j['featured'] == true,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ONBOARDING QUESTIONS
// ═══════════════════════════════════════════════════════════════════════════
class OnboardingOption {
  final String value;
  final String label;
  final bool exclusive;
  const OnboardingOption({
    required this.value,
    required this.label,
    this.exclusive = false,
  });

  factory OnboardingOption.fromJson(Map<String, dynamic> j) => OnboardingOption(
    value: j['value']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
    exclusive: j['exclusive'] == true,
  );
}

class OnboardingQuestion {
  final String id, key, eyebrow, prompt, type;
  final bool required, active;
  final int order;
  final List<OnboardingOption> options;
  const OnboardingQuestion({
    required this.id,
    required this.key,
    required this.eyebrow,
    required this.prompt,
    required this.type,
    required this.required,
    required this.active,
    required this.order,
    required this.options,
  });

  factory OnboardingQuestion.fromJson(Map<String, dynamic> j) {
    final opts = (j['options'] as List?)
            ?.whereType<Map>()
            .map((e) => OnboardingOption.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <OnboardingOption>[];
    return OnboardingQuestion(
      id: (j['id'] ?? j['_id'])?.toString() ?? '',
      key: j['key']?.toString() ?? '',
      eyebrow: j['eyebrow']?.toString() ?? '',
      prompt: j['prompt']?.toString() ?? '',
      type: j['type']?.toString() ?? 'single',
      required: j['required'] != false,
      active: j['active'] != false,
      order: toInt(j['order']),
      options: opts,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTH SESSION
// ═══════════════════════════════════════════════════════════════════════════
class AuthUser {
  final String id, email, displayName, provider;
  final bool onboardingCompleted;
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.provider,
    required this.onboardingCompleted,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: (j['_id'] ?? j['id'])?.toString() ?? '',
    email: j['email']?.toString() ?? '',
    displayName: j['displayName']?.toString() ?? j['name']?.toString() ?? '',
    provider: j['provider']?.toString() ?? 'local',
    onboardingCompleted: j['onboardingCompleted'] == true,
  );
}

class AuthResult {
  final String accessToken;
  final AuthUser user;
  const AuthResult({required this.accessToken, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
    accessToken: j['access_token']?.toString() ?? '',
    user: j['user'] is Map<String, dynamic>
        ? AuthUser.fromJson(Map<String, dynamic>.from(j['user'] as Map))
        : const AuthUser(
            id: '',
            email: '',
            displayName: '',
            provider: 'local',
            onboardingCompleted: false,
          ),
  );
}
