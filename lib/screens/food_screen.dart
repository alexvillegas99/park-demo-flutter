import 'package:flutter/material.dart';

import '../api/data_store.dart';
import '../api/models.dart';
import '../design/brand_theme.dart';
import '../widgets/page_eyebrow.dart';
import 'restaurant_screen.dart';

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: DataStore.instance.notifier,
      builder: (context, _, __) {
        final restaurants = DataStore.instance.restaurants;
        return ColoredBox(
          color: AppColors.surface,
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 138),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageEyebrow(
                    icon: Icons.restaurant_rounded,
                    label: 'GASTRONOMÍA',
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Sabores del complejo',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.7,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    restaurants.isEmpty
                        ? 'Descubre nuestros restaurantes'
                        : '${restaurants.length} restaurantes · Cocina tradicional y moderna',
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDeep, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.room_service_rounded,
                          color: AppColors.gold,
                          size: 30,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RECOMENDACIÓN DE RUNI',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Almuerza antes de las 13h para encontrar menos fila.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (restaurants.isEmpty)
                    const _EmptyRestaurants()
                  else
                    ...restaurants.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RestaurantCard(rest: r),
                      ),
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

class _EmptyRestaurants extends StatelessWidget {
  const _EmptyRestaurants();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            color: AppColors.goldDk,
            size: 36,
          ),
          SizedBox(height: 10),
          Text(
            'Cargando restaurantes…',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Pronto verás los sabores del complejo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Restaurant list card — informational only, no ordering CTAs.
/// Tap opens the restaurant profile (dishes browser, no purchase).
class _RestaurantCard extends StatelessWidget {
  final Restaurant rest;
  const _RestaurantCard({required this.rest});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ver perfil de ${rest.name}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RestaurantScreen(rest: rest),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: .08),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: rest.coverUrl.isNotEmpty
                        ? Image.network(
                            rest.coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _emojiPlaceholder(rest.logoEmoji),
                          )
                        : _emojiPlaceholder(rest.logoEmoji),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rest.category.isNotEmpty)
                        Text(
                          rest.category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.goldDk,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        rest.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (rest.tagline.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          rest.tagline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 11.5,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.restaurant_menu,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${rest.dishes.length} platos',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (rest.zone.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.inkSoft,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                rest.zone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
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

  Widget _emojiPlaceholder(String emoji) => ColoredBox(
        color: AppColors.primarySoft,
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 40)),
        ),
      );
}
