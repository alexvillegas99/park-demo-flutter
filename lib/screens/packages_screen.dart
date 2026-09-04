import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart' show kWhatsAppPhone;
import '../api/data_store.dart';
import '../api/models.dart' as api;
import '../design/brand_theme.dart';
import '../widgets/page_eyebrow.dart';

/// Launches WhatsApp with a Spanish reservation message pre-filled. The
/// storefront app never processes payments locally — WhatsApp is the intended
/// handoff for reservations.
Future<void> _openWhatsAppReservation(
  BuildContext context, {
  required String packageName,
  required String packagePrice,
}) async {
  final priceFragment = packagePrice.isNotEmpty ? ' ($packagePrice)' : '';
  final message =
      'Hola, quiero reservar el paquete "$packageName"$priceFragment para la Feria Mushuc Runa.';
  final uri = Uri.parse(
    'https://wa.me/$kWhatsAppPhone?text=${Uri.encodeComponent(message)}',
  );
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No pudimos abrir WhatsApp en este dispositivo.'),
      ),
    );
  }
}

/// Reusable WhatsApp reservation CTA. Uses brand primary as background and a
/// WhatsApp-green accent circle around the icon.
class _WhatsAppReserveButton extends StatelessWidget {
  const _WhatsAppReserveButton({
    required this.packageName,
    required this.packagePrice,
    this.expanded = false,
  });

  final String packageName;
  final String packagePrice;
  final bool expanded;

  static const Color _whatsAppGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: () => _openWhatsAppReservation(
        context,
        packageName: packageName,
        packagePrice: packagePrice,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _WhatsAppMark(background: _whatsAppGreen),
          SizedBox(width: 10),
          Text(
            'Reservar por WhatsApp',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
    return Semantics(button: true, label: 'Reservar por WhatsApp', child: button);
  }
}

class _WhatsAppMark extends StatelessWidget {
  final Color background;
  const _WhatsAppMark({required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: const Icon(Icons.chat_rounded, color: Colors.white, size: 13),
    );
  }
}

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  static const _fallbackPackages =
      <
        ({
          String name,
          String tagline,
          String badge,
          String adult,
          String child,
          String normal,
          Color color,
          List<String> benefits,
        })
      >[
        (
          name: 'Tuki Tuki',
          tagline: 'LA EXPERIENCIA COMPLETA',
          badge: 'MÁS VENDIDO',
          adult: r'$25',
          child: r'$15',
          normal: r'$40',
          color: AppColors.primary,
          benefits: [
            'Parque de dinosaurios',
            'Resbaladera Gigante',
            'Piscinas y Paseo en Tren',
            'Mushuc Park y Cabalgata',
            'Asado de búfalo',
            'Parqueadero e ingreso',
          ],
        ),
        (
          name: 'Tuki Punlla',
          tagline: 'UN DÍA EN FAMILIA',
          badge: '',
          adult: r'$15',
          child: r'$8',
          normal: r'$25',
          color: AppColors.goldDk,
          benefits: [
            'Parque de dinosaurios',
            'Resbaladera Gigante',
            'Piscinas y Paseo en Tren',
            'Mushuc Park y Cabalgata',
            'Almuerzo especial',
            'Parqueadero e ingreso',
          ],
        ),
        (
          name: 'All Day 2x1',
          tagline: 'SOLO SÁBADOS',
          badge: 'PROMO',
          adult: r'2x$25',
          child: r'2x$15',
          normal: r'$50',
          color: AppColors.coral,
          benefits: [
            'Dos entradas por el precio de una',
            'Dinosaurios y Resbaladera',
            'Piscinas y Paseo en Tren',
            'Cabalgata y Mushuc Park',
            'Parqueadero e ingreso',
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: DataStore.instance.notifier,
      builder: (context, _, __) {
        final apiPackages = DataStore.instance.packages;
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
                    icon: Icons.confirmation_number_rounded,
                    label: 'PLANEA TU VISITA',
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Paquetes y entradas',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.7,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Un solo pago, diversión todo el día',
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (apiPackages.isNotEmpty)
                    ...apiPackages.map(
                      (pkg) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ApiPackageCard(package: pkg),
                      ),
                    )
                  else
                    ...(_fallbackPackages.map(
                      (pkg) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _StaticPackageCard(package: pkg),
                      ),
                    )),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF6E7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFEFD9A8),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.goldDk,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Los precios son referenciales. La compra se realiza en boletería.',
                            style: TextStyle(
                              color: Color(0xFF8A5A12),
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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

class _ApiPackageCard extends StatelessWidget {
  final api.AppPackage package;
  const _ApiPackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    final priceLabel = package.priceLabel.isNotEmpty
        ? package.priceLabel
        : (package.price != null ? '\$${package.price!.toStringAsFixed(0)}' : '');
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.line, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDk],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: .7),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_activity_rounded,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (package.tagline.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          package.tagline.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (package.featured)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                for (final benefit in package.includes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryDk,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefit,
                            style: const TextStyle(
                              color: Color(0xFF4A362C),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (priceLabel.isNotEmpty) ...[
                  const Divider(color: AppColors.line, height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PRECIO',
                              style: TextStyle(
                                color: AppColors.goldDk,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                              ),
                            ),
                            Text(
                              priceLabel,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 22,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (package.durationHours != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'DURACIÓN',
                              style: TextStyle(
                                color: AppColors.goldDk,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                              ),
                            ),
                            Text(
                              '${package.durationHours}h',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: _WhatsAppReserveButton(
                    packageName: package.name,
                    packagePrice: priceLabel,
                    expanded: true,
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

class _StaticPackageCard extends StatelessWidget {
  final ({
    String name,
    String tagline,
    String badge,
    String adult,
    String child,
    String normal,
    Color color,
    List<String> benefits,
  })
  package;

  const _StaticPackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.line, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [package.color.withValues(alpha: .82), package.color],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: .7),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_activity_rounded,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.tagline,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (package.badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      package.badge,
                      style: const TextStyle(
                        color: AppColors.primaryDeep,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                for (final benefit in package.benefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryDk,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefit,
                            style: const TextStyle(
                              color: Color(0xFF4A362C),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(color: AppColors.line, height: 22),
                Row(
                  children: [
                    _PackagePrice(label: 'ADULTOS', value: package.adult),
                    const SizedBox(width: 20),
                    _PackagePrice(label: 'NIÑOS', value: package.child),
                    const Spacer(),
                    Text(
                      'Normal ${package.normal}',
                      style: const TextStyle(
                        color: Color(0xFFB0A08C),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: _WhatsAppReserveButton(
                    packageName: package.name,
                    packagePrice: package.adult,
                    expanded: true,
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

class _PackagePrice extends StatelessWidget {
  final String label;
  final String value;

  const _PackagePrice({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.goldDk,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
