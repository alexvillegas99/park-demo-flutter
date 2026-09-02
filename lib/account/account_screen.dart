import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:park_demo/account/account_session.dart';
import 'package:park_demo/design/brand_theme.dart';

enum AccountLocationStatus { notRequested, allowed, limited, blocked }

abstract interface class AccountPrivacyService {
  Future<AccountLocationStatus> readLocationStatus();

  Future<bool> openSystemSettings();
}

class GeolocatorAccountPrivacyService implements AccountPrivacyService {
  const GeolocatorAccountPrivacyService();

  @override
  Future<AccountLocationStatus> readLocationStatus() async {
    final permission = await Geolocator.checkPermission();
    return switch (permission) {
      LocationPermission.always => AccountLocationStatus.allowed,
      LocationPermission.whileInUse => AccountLocationStatus.limited,
      LocationPermission.deniedForever => AccountLocationStatus.blocked,
      LocationPermission.denied || LocationPermission.unableToDetermine =>
        AccountLocationStatus.notRequested,
    };
  }

  @override
  Future<bool> openSystemSettings() => Geolocator.openAppSettings();
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.session,
    required this.onSignOut,
    required this.onDeleteLocalAccount,
    this.privacyService = const GeolocatorAccountPrivacyService(),
  });

  final AccessSession session;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteLocalAccount;
  final AccountPrivacyService privacyService;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AccountLocationStatus _locationStatus = AccountLocationStatus.notRequested;

  @override
  void initState() {
    super.initState();
    _readLocationStatus();
  }

  Future<void> _readLocationStatus() async {
    final status = await widget.privacyService.readLocationStatus();
    if (mounted) setState(() => _locationStatus = status);
  }

  String get _locationLabel => switch (_locationStatus) {
    AccountLocationStatus.notRequested => 'Ubicación no solicitada',
    AccountLocationStatus.allowed => 'Ubicación permitida',
    AccountLocationStatus.limited => 'Ubicación limitada',
    AccountLocationStatus.blocked => 'Ubicación bloqueada',
  };

  String get _providerLabel => switch (widget.session.provider) {
    AccessProvider.guest => 'Acceso como visitante',
    AccessProvider.local => 'Cuenta local de demostración',
    AccessProvider.googleDemo => 'Google · demostración visual',
  };

  Future<void> _openLocationSettings() async {
    final opened = await widget.privacyService.openSystemSettings();
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir Ajustes en este dispositivo'),
        ),
      );
      return;
    }
    await _readLocationStatus();
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Podrás volver a ingresar cuando quieras.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm-sign-out'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onSignOut();
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = widget.session.isGuest;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 194,
            backgroundColor: AppColors.primaryDk,
            foregroundColor: Colors.white,
            title: const Text(
              'Cuenta y privacidad',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _AccountHero(session: widget.session),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
            sliver: SliverList.list(
              children: [
                _IdentityCard(
                  session: widget.session,
                  providerLabel: _providerLabel,
                ),
                const SizedBox(height: 24),
                const _SectionTitle(
                  eyebrow: 'CONTROL',
                  title: 'Privacidad y permisos',
                ),
                const SizedBox(height: 10),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.location_on_outlined,
                      title: 'Ubicación',
                      subtitle: _locationLabel,
                      trailingLabel:
                          _locationStatus == AccountLocationStatus.blocked ||
                              _locationStatus == AccountLocationStatus.limited
                          ? 'Abrir ajustes'
                          : null,
                      onTap: _openLocationSettings,
                      key: const Key('location-settings'),
                    ),
                    const _SettingsDivider(),
                    const _SettingsRow(
                      icon: Icons.phonelink_lock_outlined,
                      title: 'Datos en este dispositivo',
                      subtitle:
                          'La sesión es local; esta demostración no tiene backend.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionTitle(
                  eyebrow: 'INFORMACIÓN',
                  title: 'Ayuda y documentos',
                ),
                const SizedBox(height: 10),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      key: const Key('privacy-policy-link'),
                      icon: Icons.privacy_tip_outlined,
                      title: 'Política de privacidad',
                      subtitle: 'Qué utiliza y conserva esta versión',
                      onTap: () => _open(const PrivacyPolicyScreen()),
                    ),
                    const _SettingsDivider(),
                    _SettingsRow(
                      key: const Key('terms-link'),
                      icon: Icons.description_outlined,
                      title: 'Términos de uso',
                      subtitle: 'Alcance del mapa y contenido informativo',
                      onTap: () => _open(const TermsOfUseScreen()),
                    ),
                    const _SettingsDivider(),
                    _SettingsRow(
                      key: const Key('support-link'),
                      icon: Icons.help_outline_rounded,
                      title: 'Ayuda y soporte',
                      subtitle: 'Respuestas disponibles sin conexión',
                      onTap: () => _open(const SupportScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionTitle(eyebrow: 'SESIÓN', title: 'Tus controles'),
                const SizedBox(height: 10),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      key: const Key('sign-out-button'),
                      icon: Icons.logout_rounded,
                      title: isGuest
                          ? 'Salir del modo visitante'
                          : 'Cerrar sesión',
                      subtitle: 'Vuelve a la pantalla de acceso',
                      onTap: _confirmSignOut,
                    ),
                    const _SettingsDivider(),
                    _SettingsRow(
                      key: const Key('delete-account-button'),
                      icon: Icons.delete_outline_rounded,
                      iconColor: AppColors.primary,
                      title: isGuest
                          ? 'Borrar datos de esta sesión'
                          : 'Eliminar cuenta local',
                      subtitle:
                          'Requiere confirmación y no afecta el mapa administrativo',
                      danger: true,
                      onTap: () => _open(
                        DeleteLocalAccountScreen(
                          session: widget.session,
                          onConfirm: widget.onDeleteLocalAccount,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Versión de demostración · 2 de septiembre de 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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

class _AccountHero extends StatelessWidget {
  const _AccountHero({required this.session});

  final AccessSession session;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDk, AppColors.primary, Color(0xFF8C2926)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            bottom: -60,
            child: Icon(
              Icons.filter_vintage_rounded,
              size: 210,
              color: AppColors.gold.withValues(alpha: .13),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 22,
            child: Text(
              session.isGuest
                  ? 'Explora con libertad y conserva el control de tus datos.'
                  : 'Tu visita, tus permisos y tus datos en un solo lugar.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.session, required this.providerLabel});

  final AccessSession session;
  final String providerLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              session.displayName.characters.first.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayName,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (session.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    session.email,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Text(
                  providerLabel,
                  style: const TextStyle(
                    color: AppColors.goldDk,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_user_outlined, color: AppColors.green),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: BrandType.institutional.copyWith(
            color: AppColors.goldDk,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 66, color: AppColors.line);
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailingLabel,
    this.iconColor = AppColors.green,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? trailingLabel;
  final Color iconColor;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: iconColor, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: danger ? AppColors.primary : AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 11.5,
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      trailingLabel!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else if (onTap != null)
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

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocumentScreen(
      title: 'Política de privacidad',
      intro:
          'Esta política describe únicamente el comportamiento de la versión de demostración instalada en tu dispositivo.',
      sections: [
        _DocumentSection(
          title: 'Datos de esta versión',
          body:
              'El nombre, correo y respuestas de personalización permanecen en memoria mientras la sesión está abierta. Esta versión no tiene backend, analítica ni publicidad.',
        ),
        _DocumentSection(
          title: 'Ubicación',
          body:
              'La ubicación se solicita al abrir el mapa para mostrar dónde estás. La app no conserva un historial de tus recorridos.',
        ),
        _DocumentSection(
          title: 'Servicios externos',
          body:
              'Cuando eliges Cómo llegar, puedes transferir origen y destino a Apple Maps o Google Maps mediante una acción explícita.',
        ),
        _DocumentSection(
          title: 'Conservación y eliminación',
          body:
              'Puedes cerrar sesión o eliminar los datos locales desde Cuenta. La configuración administrativa del recinto se conserva separada de tu sesión personal.',
        ),
        _DocumentSection(
          title: 'Cambios futuros',
          body:
              'Antes de incorporar cuentas reales, pagos, analítica o sincronización, esta política y las declaraciones de las tiendas deberán actualizarse.',
        ),
      ],
    );
  }
}

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocumentScreen(
      title: 'Términos de uso',
      intro:
          'Condiciones informativas para revisar esta demostración de la experiencia Mushuc Runa.',
      sections: [
        _DocumentSection(
          title: 'Alcance informativo',
          body:
              'Los eventos, horarios, precios y tiempos de espera son datos de demostración y pueden cambiar. Confirma la programación oficial antes de viajar.',
        ),
        _DocumentSection(
          title: 'Ubicación aproximada',
          body:
              'El mapa y las distancias ayudan a orientarte, pero dependen de la precisión del dispositivo y de la calibración física de los puntos.',
        ),
        _DocumentSection(
          title: 'Compras y reservas',
          body:
              'Esta versión no procesa pagos, reservas ni entradas. Ningún contenido mostrado constituye una compra confirmada.',
        ),
        _DocumentSection(
          title: 'Contenido y marca',
          body:
              'Las fotografías, nombres y elementos de marca deben utilizarse con autorización de sus titulares.',
        ),
      ],
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocumentScreen(
      title: 'Ayuda y soporte',
      intro:
          'Respuestas rápidas para utilizar la demostración incluso cuando no tienes conexión.',
      sections: [
        _DocumentSection(
          title: 'Preguntas frecuentes',
          body:
              'Puedes entrar como visitante sin entregar datos. El mapa solicita ubicación solamente al abrirlo. Si rechazas el permiso, todavía puedes explorar y buscar lugares manualmente.',
        ),
        _DocumentSection(
          title: 'Mapa y datos sin conexión',
          body:
              'El mapa base, los puntos guardados y estos documentos viajan con la aplicación. Los cambios del administrador se guardan en este dispositivo.',
        ),
        _DocumentSection(
          title: 'Cerrar o eliminar',
          body:
              'Cerrar sesión vuelve al acceso. Eliminar limpia la identidad y respuestas locales de esta demostración, pero no borra la programación del recinto.',
        ),
        _DocumentSection(
          title: 'Contacto oficial pendiente de confirmación',
          body:
              'Antes del lanzamiento se debe publicar y verificar un canal oficial de soporte y una página web externa para solicitudes de eliminación.',
        ),
      ],
    );
  }
}

class _DocumentSection {
  const _DocumentSection({required this.title, required this.body});

  final String title;
  final String body;
}

class _DocumentScreen extends StatelessWidget {
  const _DocumentScreen({
    required this.title,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String intro;
  final List<_DocumentSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 40),
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 29,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            intro,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          for (final section in sections) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    section.body,
                    style: const TextStyle(color: AppColors.ink, height: 1.48),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 6),
          const Text(
            'Versión de demostración · 2 de septiembre de 2026',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class DeleteLocalAccountScreen extends StatelessWidget {
  const DeleteLocalAccountScreen({
    super.key,
    required this.session,
    required this.onConfirm,
  });

  final AccessSession session;
  final VoidCallback onConfirm;

  Future<void> _confirm(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          'Esta acción elimina los datos locales de esta demostración',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm-delete-account'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDk),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );
    if (accepted == true) onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final title = session.isGuest
        ? 'Borrar datos de esta sesión'
        : 'Eliminar cuenta local';
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_outlined,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 29,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Revisa con calma qué cambiará antes de confirmar.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 15),
            ),
            const SizedBox(height: 24),
            const _DeleteFact(
              icon: Icons.person_remove_outlined,
              text: 'Se elimina la identidad usada en esta sesión.',
            ),
            const _DeleteFact(
              icon: Icons.quiz_outlined,
              text: 'Se limpian tus respuestas de personalización.',
            ),
            const _DeleteFact(
              icon: Icons.logout_rounded,
              text: 'La sesión se cierra y vuelves a la pantalla de acceso.',
            ),
            const _DeleteFact(
              icon: Icons.map_outlined,
              text:
                  'No se elimina la programación administrativa ni los puntos del mapa.',
              positive: true,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('continue-delete-account'),
              onPressed: () => _confirm(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDk,
                minimumSize: const Size.fromHeight(54),
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(title),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.line),
              ),
              child: const Text('Conservar mis datos'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteFact extends StatelessWidget {
  const _DeleteFact({
    required this.icon,
    required this.text,
    this.positive = false,
  });

  final IconData icon;
  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.green : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.ink,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
