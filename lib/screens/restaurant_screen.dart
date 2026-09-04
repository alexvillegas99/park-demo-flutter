import 'package:flutter/material.dart';

import '../api/models.dart';
import '../design/brand_theme.dart';

/// Restaurant profile screen — read-only view of the restaurant identity plus
/// its menu. No ordering, no cart, no payment. This is by product design: the
/// storefront app never places orders on the user's behalf.
class RestaurantScreen extends StatelessWidget {
  final Restaurant rest;
  const RestaurantScreen({super.key, required this.rest});

  @override
  Widget build(BuildContext context) {
    final r = rest;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.ink,
                    size: 20,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (r.coverUrl.isNotEmpty)
                    Image.network(
                      r.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _emojiCover(r.logoEmoji),
                    )
                  else
                    _emojiCover(r.logoEmoji),
                  const DecoratedBox(
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
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              r.logoEmoji,
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (r.category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white38),
                                  ),
                                  child: Text(
                                    r.category.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                r.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (r.tagline.isNotEmpty)
                    Text(
                      r.tagline,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.location_on_rounded,
                          label: 'Ubicación',
                          value: r.zone.isNotEmpty ? r.zone : '—',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.access_time_rounded,
                          label: 'Horario',
                          value: r.schedule.isNotEmpty ? r.schedule : '—',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (r.description.isNotEmpty) ...[
                    const Text(
                      'Sobre el local',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.description,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    children: [
                      const Text(
                        'Nuestros platos',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${r.dishes.length} en carta',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (r.dishes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.no_meals_outlined,
                            color: AppColors.inkSoft,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'La carta aún no se ha publicado.',
                              style: TextStyle(
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...r.dishes.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DishCard(dish: d),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emojiCover(String emoji) => ColoredBox(
        color: AppColors.primary,
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 96),
          ),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
                  label,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  final Dish dish;
  const _DishCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: dish.imageUrl.isNotEmpty
                      ? Image.network(
                          dish.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              if (dish.popular)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '★ Top',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dish.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (dish.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    dish.description,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (dish.price > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ref. \$${dish.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
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

  Widget _placeholder() => ColoredBox(
        color: AppColors.primary.withValues(alpha: .15),
        child: Center(
          child: Text(
            dish.emoji,
            style: const TextStyle(fontSize: 38),
          ),
        ),
      );
}
