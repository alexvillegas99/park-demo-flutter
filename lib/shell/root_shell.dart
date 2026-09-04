import 'package:flutter/material.dart';

import '../account/account_screen.dart';
import '../account/account_session.dart';
import '../design/brand_theme.dart';
import '../screens/food_screen.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/packages_screen.dart';

class RootShell extends StatefulWidget {
  final AccessSession session;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteLocalAccount;
  final Widget Function(bool active)? mapScreenBuilder;

  const RootShell({
    super.key,
    required this.session,
    required this.onSignOut,
    required this.onDeleteLocalAccount,
    this.mapScreenBuilder,
  });
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;
  late final List<Widget?> _screens;

  @override
  void initState() {
    super.initState();
    _screens = <Widget?>[
      _screenFor(0),
      _buildMapScreen(active: false),
      null,
      null,
    ];
  }

  void _selectTab(int tab) {
    _screens[tab] ??= _screenFor(tab);
    _screens[1] = _buildMapScreen(active: tab == 1);
    setState(() => _tab = tab);
  }

  Widget _buildMapScreen({required bool active}) {
    return widget.mapScreenBuilder?.call(active) ?? MapScreen(active: active);
  }

  void _openRuni() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: .48),
      builder: (_) => const _RuniSheet(),
    );
  }

  void _openAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountScreen(
          session: widget.session,
          onSignOut: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            widget.onSignOut();
          },
          onDeleteLocalAccount: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            widget.onDeleteLocalAccount();
          },
        ),
      ),
    );
  }

  Widget _screenFor(int tab) => switch (tab) {
    0 => HomeScreen(
      displayName: widget.session.displayName,
      onOpenPackages: () => _selectTab(2),
      onOpenRuni: _openRuni,
      onOpenAccount: _openAccount,
    ),
    1 => const MapScreen(),
    2 => const PackagesScreen(),
    _ => const FoodScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _tab,
        children: _screens
            .map((screen) => screen ?? const SizedBox.shrink())
            .toList(growable: false),
      ),
      bottomNavigationBar: _BottomNav(
        index: _tab,
        onChange: _selectTab,
        onRuni: _openRuni,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChange;
  final VoidCallback onRuni;
  const _BottomNav({
    required this.index,
    required this.onChange,
    required this.onRuni,
  });
  @override
  Widget build(BuildContext context) {
    final items = const [
      (icon: Icons.home_rounded, label: 'Inicio'),
      (icon: Icons.map_rounded, label: 'Mapa'),
      (icon: Icons.confirmation_number_rounded, label: 'Paquetes'),
      (icon: Icons.restaurant_rounded, label: 'Comida'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .97),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.line, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .18),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBtn(
              icon: items[0].icon,
              label: items[0].label,
              active: index == 0,
              onTap: () => onChange(0),
              inkOff: AppColors.inkSoft,
            ),
            _NavBtn(
              icon: items[1].icon,
              label: items[1].label,
              active: index == 1,
              onTap: () => onChange(1),
              inkOff: AppColors.inkSoft,
            ),
            Transform.translate(
              offset: const Offset(0, -18),
              child: Semantics(
                button: true,
                label: 'Abrir Runi',
                child: InkWell(
                  key: const Key('runi-nav-button'),
                  customBorder: const CircleBorder(),
                  onTap: onRuni,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.goldDk, AppColors.gold],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldDk.withValues(alpha: .45),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primaryDeep,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
            _NavBtn(
              icon: items[2].icon,
              label: items[2].label,
              active: index == 2,
              onTap: () => onChange(2),
              inkOff: AppColors.inkSoft,
            ),
            _NavBtn(
              icon: items[3].icon,
              label: items[3].label,
              active: index == 3,
              onTap: () => onChange(3),
              inkOff: AppColors.inkSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color inkOff;
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.inkOff,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minWidth: 58),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? AppColors.primary : inkOff, size: 21),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: active ? AppColors.primary : inkOff,
                fontWeight: FontWeight.w900,
                fontSize: 9.5,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuniSheet extends StatelessWidget {
  const _RuniSheet();

  @override
  Widget build(BuildContext context) {
    const itinerary =
        <({String time, String title, String note, IconData icon})>[
      (
        time: '10:00',
        title: 'Parque de Dinosaurios',
        note: 'Empieza antes de que aumente la fila',
        icon: Icons.cruelty_free_rounded,
      ),
      (
        time: '11:30',
        title: 'Paseo en Tren',
        note: 'Recorre el complejo en familia',
        icon: Icons.train_rounded,
      ),
      (
        time: '13:00',
        title: 'Cocina Mushuc Runa',
        note: 'Almuerzo especial del paquete',
        icon: Icons.restaurant_rounded,
      ),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8DCC5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.coral],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
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
                        'Runi',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'TU GUÍA INTELIGENTE',
                        style: TextStyle(
                          color: AppColors.goldDk,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF5EDDC),
                    foregroundColor: AppColors.inkSoft,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: AppColors.line),
              ),
              child: const Text(
                'Armé un plan para tu familia según las filas de hoy y el clima soleado. ¡Aprovechen la mañana en las atracciones al aire libre!',
                style: TextStyle(
                  color: Color(0xFF4A362C),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tu recorrido recomendado',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (int index = 0; index < itinerary.length; index++)
              _RuniStep(
                step: itinerary[index],
                showLine: index != itinerary.length - 1,
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EDDC),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Text(
                      'Pregúntale algo a Runi…',
                      style: TextStyle(
                        color: Color(0xFFA08C74),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: AppColors.gold,
                    size: 19,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuniStep extends StatelessWidget {
  final ({String time, String title, String note, IconData icon}) step;
  final bool showLine;

  const _RuniStep({required this.step, required this.showLine});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Icon(step.icon, color: AppColors.primary, size: 18),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.time,
                    style: const TextStyle(
                      color: AppColors.goldDk,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    step.note,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
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
}
