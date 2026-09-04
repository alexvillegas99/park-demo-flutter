import 'dart:async';

import 'package:flutter/material.dart';
import 'package:park_demo/account/account_session.dart';
import 'package:park_demo/api/api_client.dart';
import 'package:park_demo/api/data_store.dart';
import 'package:park_demo/design/brand_theme.dart';

enum AccessStage { login, register, onboarding, app }

class AccessGate extends StatefulWidget {
  const AccessGate({super.key, required this.appBuilder});

  final Widget Function(
    AccessSession session,
    VoidCallback onSignOut,
    VoidCallback onDeleteLocalAccount,
  )
  appBuilder;

  @override
  State<AccessGate> createState() => _AccessGateState();
}

class _AccessGateState extends State<AccessGate> {
  // Credenciales demo pre-cargadas para revisión de App Store / Play Store.
  static const String _demoEmail = 'avillegas7510@gmail.com';
  static const String _demoPassword = '12345678';

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController(text: _demoEmail);
  final _loginPassword = TextEditingController(text: _demoPassword);
  final _registerName = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  final _registerConfirm = TextEditingController();

  AccessStage _stage = AccessStage.login;
  AccessStage _onboardingOrigin = AccessStage.login;
  String _displayName = 'Visitante';
  String _pendingEmail = '';
  AccessProvider _pendingProvider = AccessProvider.local;
  AccessSession? _session;
  String? _accessNotice;
  String? _accessError;
  bool _busy = false;
  int _question = 0;
  final Set<String> _visitReasons = <String>{};
  String? _visitFrequency;
  final Set<String> _recommendationReasons = <String>{};

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _registerName.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    _registerConfirm.dispose();
    super.dispose();
  }

  void _openRegister() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _accessNotice = null;
      _stage = AccessStage.register;
    });
  }

  void _startGoogleOnboarding() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _displayName = 'Visitante';
      _pendingEmail = '';
      _pendingProvider = AccessProvider.googleDemo;
      _accessNotice = null;
      _onboardingOrigin = AccessStage.login;
      _resetAnswers();
      _stage = AccessStage.onboarding;
    });
  }

  Future<void> _submitLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    if (_busy) return;
    setState(() {
      _busy = true;
      _accessError = null;
      _accessNotice = null;
    });
    try {
      final result = await ApiClient.instance.appLogin(
        email: _loginEmail.text.trim(),
        password: _loginPassword.text,
      );
      // Kick off data fetch in the background — the app boots even if it fails.
      unawaited(DataStore.instance.refresh());
      if (!mounted) return;
      final resolvedName = result.user.displayName.isNotEmpty
          ? _firstName(result.user.displayName)
          : _nameFromEmail(result.user.email.isNotEmpty
              ? result.user.email
              : _loginEmail.text);
      setState(() {
        _displayName = resolvedName;
        _session = AccessSession(
          displayName: _displayName,
          email: result.user.email.isNotEmpty
              ? result.user.email
              : _loginEmail.text.trim(),
          provider: AccessProvider.local,
        );
        _busy = false;
        _stage = AccessStage.app;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _accessError = _friendlyError(e);
      });
    }
  }

  Future<void> _continueAsGuest() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_busy) return;
    setState(() {
      _busy = true;
      _accessError = null;
    });
    try {
      await ApiClient.instance.guest(displayName: 'Visitante');
    } catch (_) {
      // Sesión anónima local si la API no responde — no bloqueamos el ingreso.
    }
    unawaited(DataStore.instance.refresh());
    if (!mounted) return;
    setState(() {
      _session = const AccessSession.guest();
      _displayName = _session!.displayName;
      _accessNotice = null;
      _busy = false;
      _stage = AccessStage.app;
    });
  }

  Future<void> _submitRegister() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;
    if (_busy) return;
    setState(() {
      _busy = true;
      _accessError = null;
    });
    try {
      final result = await ApiClient.instance.register(
        email: _registerEmail.text.trim(),
        password: _registerPassword.text,
        displayName: _registerName.text.trim(),
      );
      unawaited(DataStore.instance.refresh());
      if (!mounted) return;
      setState(() {
        _displayName = result.user.displayName.isNotEmpty
            ? _firstName(result.user.displayName)
            : _firstName(_registerName.text);
        _pendingEmail = result.user.email.isNotEmpty
            ? result.user.email
            : _registerEmail.text.trim();
        _pendingProvider = AccessProvider.local;
        _accessNotice = null;
        _busy = false;
        _onboardingOrigin = AccessStage.register;
        _resetAnswers();
        _stage = AccessStage.onboarding;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _accessError = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 401) return 'Credenciales inválidas';
      if (e.statusCode == 409) return 'Ese correo ya está registrado';
      return e.message;
    }
    return 'No pudimos conectarnos. Intenta de nuevo.';
  }

  void _resetAnswers() {
    _question = 0;
    _visitReasons.clear();
    _visitFrequency = null;
    _recommendationReasons.clear();
  }

  String _firstName(String value) {
    final cleaned = value.trim().split(RegExp(r'\s+')).first;
    if (cleaned.isEmpty) return 'Visitante';
    return '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
  }

  String _nameFromEmail(String value) {
    final local = value.trim().split('@').first;
    final readable = local.replaceAll(RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ]+'), ' ');
    return _firstName(readable);
  }

  bool get _canContinue => switch (_question) {
    0 => _visitReasons.isNotEmpty,
    1 => _visitFrequency != null,
    _ => _recommendationReasons.isNotEmpty,
  };

  void _toggleVisitReason(String value) {
    setState(() {
      if (value == 'Todo') {
        if (_visitReasons.contains(value)) {
          _visitReasons.clear();
        } else {
          _visitReasons
            ..clear()
            ..add(value);
        }
        return;
      }
      _visitReasons.remove('Todo');
      _visitReasons.contains(value)
          ? _visitReasons.remove(value)
          : _visitReasons.add(value);
    });
  }

  void _toggleRecommendation(String value) {
    setState(() {
      _recommendationReasons.contains(value)
          ? _recommendationReasons.remove(value)
          : _recommendationReasons.add(value);
    });
  }

  void _continueOnboarding() {
    if (!_canContinue) return;
    if (_question < 2) {
      setState(() => _question += 1);
      return;
    }
    setState(() {
      _session = AccessSession(
        displayName: _displayName,
        email: _pendingEmail,
        provider: _pendingProvider,
      );
      _stage = AccessStage.app;
    });
  }

  void _clearSession({required bool deleted}) {
    FocusManager.instance.primaryFocus?.unfocus();
    _loginEmail.clear();
    _loginPassword.clear();
    _registerName.clear();
    _registerEmail.clear();
    _registerPassword.clear();
    _registerConfirm.clear();
    unawaited(ApiClient.instance.signOut());
    setState(() {
      _session = null;
      _displayName = 'Visitante';
      _pendingEmail = '';
      _pendingProvider = AccessProvider.local;
      _resetAnswers();
      _accessNotice = deleted
          ? 'Cuenta y datos locales eliminados'
          : 'Sesión cerrada correctamente';
      _accessError = null;
      _busy = false;
      _stage = AccessStage.login;
    });
  }

  void _backFromOnboarding() {
    if (_question > 0) {
      setState(() => _question -= 1);
      return;
    }
    setState(() => _stage = _onboardingOrigin);
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == AccessStage.app) {
      return widget.appBuilder(
        _session ?? const AccessSession.guest(),
        () => _clearSession(deleted: false),
        () => _clearSession(deleted: true),
      );
    }

    final current = switch (_stage) {
      AccessStage.login => _LoginView(
        key: const ValueKey('login-view'),
        formKey: _loginFormKey,
        emailController: _loginEmail,
        passwordController: _loginPassword,
        onGoogle: _startGoogleOnboarding,
        onLogin: _submitLogin,
        onGuest: _continueAsGuest,
        onCreateAccount: _openRegister,
        notice: _accessNotice,
        errorMessage: _accessError,
        busy: _busy,
      ),
      AccessStage.register => _RegisterView(
        key: const ValueKey('register-view'),
        formKey: _registerFormKey,
        nameController: _registerName,
        emailController: _registerEmail,
        passwordController: _registerPassword,
        confirmController: _registerConfirm,
        onBack: () => setState(() {
          _stage = AccessStage.login;
          _accessError = null;
        }),
        onSubmit: _submitRegister,
        errorMessage: _accessError,
        busy: _busy,
      ),
      AccessStage.onboarding => _OnboardingView(
        key: const ValueKey('onboarding-view'),
        question: _question,
        visitReasons: _visitReasons,
        visitFrequency: _visitFrequency,
        recommendationReasons: _recommendationReasons,
        canContinue: _canContinue,
        onVisitReason: _toggleVisitReason,
        onVisitFrequency: (value) {
          setState(() => _visitFrequency = value);
        },
        onRecommendation: _toggleRecommendation,
        onBack: _backFromOnboarding,
        onContinue: _continueOnboarding,
      ),
      AccessStage.app => const SizedBox.shrink(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(.035, .015),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: current,
    );
  }
}

class _AccessColors {
  static const wine = AppColors.primary;
  static const wineDeep = AppColors.primaryDk;
  static const gold = AppColors.gold;
  static const goldDeep = AppColors.goldDk;
  static const ivory = AppColors.surface;
  static const ink = AppColors.ink;
  static const muted = AppColors.inkSoft;
  static const line = AppColors.line;
}

class _FullHeightAccessLayout extends StatelessWidget {
  const _FullHeightAccessLayout({
    required this.sheetKey,
    required this.header,
    required this.sheet,
    required this.headerFraction,
    required this.minHeaderHeight,
    required this.maxHeaderHeight,
  });

  final Key sheetKey;
  final Widget header;
  final Widget sheet;
  final double headerFraction;
  final double minHeaderHeight;
  final double maxHeaderHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final headerHeight = (constraints.maxHeight * headerFraction)
            .clamp(minHeaderHeight, maxHeaderHeight)
            .toDouble();
        const sheetOverlap = 32.0;
        final sheetTop = headerHeight - sheetOverlap;
        final minSheetHeight = constraints.maxHeight > sheetTop
            ? constraints.maxHeight - sheetTop
            : 0.0;

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 560 : 680),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: headerHeight,
                    child: header,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: sheetTop),
                    child: _AccessSheet(
                      key: sheetKey,
                      minHeight: minSheetHeight,
                      wide: wide,
                      child: sheet,
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

class _AccessSheet extends StatelessWidget {
  const _AccessSheet({
    super.key,
    required this.minHeight,
    required this.wide,
    required this.child,
  });

  final double minHeight;
  final bool wide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.fromLTRB(24, 34, 24, 18 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: wide
            ? BorderRadius.circular(34)
            : const BorderRadius.vertical(top: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: _AccessColors.wineDeep.withValues(alpha: .13),
            blurRadius: 30,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: IntrinsicHeight(child: child),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onGoogle,
    required this.onLogin,
    required this.onGuest,
    required this.onCreateAccount,
    required this.notice,
    required this.errorMessage,
    required this.busy,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onGoogle;
  final VoidCallback onLogin;
  final VoidCallback onGuest;
  final VoidCallback onCreateAccount;
  final String? notice;
  final String? errorMessage;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AccessColors.ivory,
      body: _FullHeightAccessLayout(
        sheetKey: const Key('login-full-sheet'),
        headerFraction: .37,
        minHeaderHeight: 310,
        maxHeaderHeight: 365,
        header: const _WelcomeHero(),
        sheet: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (notice != null) ...[
                Container(
                  key: const Key('access-notice'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.green,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          notice!,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (errorMessage != null) ...[
                Container(
                  key: const Key('access-error'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: _AccessColors.wine.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _AccessColors.wine.withValues(alpha: .3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: _AccessColors.wine,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: _AccessColors.wine,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'Tu aventura comienza aquí',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _AccessColors.ink,
                  fontSize: 27,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.75,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Accede para descubrir shows, rutas y experiencias hechas para ti.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _AccessColors.muted,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              // Login con Google deshabilitado temporalmente (pendiente configurar
              // OAuth para App Store / Play Store). Descomenta cuando esté listo.
              // OutlinedButton(
              //   key: const Key('google-access'),
              //   onPressed: onGoogle,
              //   style: OutlinedButton.styleFrom(
              //     foregroundColor: _AccessColors.ink,
              //     side: const BorderSide(color: _AccessColors.line, width: 1.5),
              //     minimumSize: const Size.fromHeight(54),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(17),
              //     ),
              //   ),
              //   child: const Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       _GoogleMark(),
              //       SizedBox(width: 11),
              //       Flexible(
              //         child: Text(
              //           'Continuar con Google',
              //           maxLines: 1,
              //           overflow: TextOverflow.ellipsis,
              //           style: TextStyle(fontWeight: FontWeight.w800),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const _OrDivider(),
              _AccessField(
                key: const Key('login-email'),
                controller: emailController,
                label: 'Correo',
                hint: 'nombre@correo.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              const SizedBox(height: 12),
              _AccessField(
                key: const Key('login-password'),
                controller: passwordController,
                label: 'Contraseña',
                hint: 'Mínimo 6 caracteres',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
                validator: _passwordValidator,
                onFieldSubmitted: (_) => onLogin(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('login-submit'),
                onPressed: busy ? null : onLogin,
                style: _primaryButtonStyle(),
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Iniciar sesión'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('create-account'),
                onPressed: onCreateAccount,
                style: TextButton.styleFrom(
                  foregroundColor: _AccessColors.wine,
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text.rich(
                  TextSpan(
                    text: '¿Primera vez? ',
                    children: [
                      TextSpan(
                        text: 'Crear una cuenta',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('guest-access'),
                onPressed: busy ? null : onGuest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _AccessColors.wine,
                  side: BorderSide(
                    color: _AccessColors.wine.withValues(alpha: .28),
                  ),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.explore_outlined, size: 20),
                label: const Text(
                  'Continuar como visitante',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              const Expanded(child: _LoginSupportPanel()),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(38)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.045, end: 1),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Image.asset(
              'assets/attractions/resbaladera-gigante.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -.1),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _AccessColors.ink.withValues(alpha: .10),
                  _AccessColors.ink.withValues(alpha: .18),
                  _AccessColors.wineDeep.withValues(alpha: .32),
                  _AccessColors.ink.withValues(alpha: .68),
                ],
                stops: const [0, .38, .7, 1],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.paddingOf(context).top + 18,
              24,
              56,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 17,
                        color: _AccessColors.wine,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'MUSHUC RUNA',
                        style: TextStyle(
                          color: _AccessColors.wine,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'COMPLEJO INTERCULTURAL Y DEPORTIVO',
                  style: BrandType.institutional.copyWith(
                    color: _AccessColors.gold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vive algo\nextraordinario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    height: .95,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.15,
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

class _RegisterView extends StatelessWidget {
  const _RegisterView({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.onBack,
    required this.onSubmit,
    required this.errorMessage,
    required this.busy,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final String? errorMessage;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AccessColors.ivory,
      body: _FullHeightAccessLayout(
        sheetKey: const Key('register-full-sheet'),
        headerFraction: .29,
        minHeaderHeight: 245,
        maxHeaderHeight: 280,
        header: _RegisterHero(onBack: onBack),
        sheet: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Crea tu cuenta',
                style: TextStyle(
                  color: _AccessColors.ink,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.9,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cuéntanos quién eres y prepararemos una experiencia más cercana para tu visita.',
                style: TextStyle(
                  color: _AccessColors.muted,
                  height: 1.38,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: _AccessColors.goldDeep,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Después personalizarás tu experiencia en 3 pasos rápidos.',
                        style: TextStyle(
                          color: _AccessColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AccessField(
                key: const Key('register-name'),
                controller: nameController,
                label: 'Nombre',
                hint: '¿Cómo te llamas?',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Escribe tu nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              _AccessField(
                key: const Key('register-email'),
                controller: emailController,
                label: 'Correo',
                hint: 'nombre@correo.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              const SizedBox(height: 12),
              _AccessField(
                key: const Key('register-password'),
                controller: passwordController,
                label: 'Contraseña',
                hint: 'Mínimo 6 caracteres',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
                validator: _passwordValidator,
              ),
              const SizedBox(height: 12),
              _AccessField(
                key: const Key('register-confirm'),
                controller: confirmController,
                label: 'Confirmar contraseña',
                hint: 'Repite tu contraseña',
                icon: Icons.verified_user_outlined,
                obscureText: true,
                validator: (value) {
                  if (value != passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return _passwordValidator(value);
                },
                onFieldSubmitted: (_) => onSubmit(),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  key: const Key('register-error'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: _AccessColors.wine.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _AccessColors.wine.withValues(alpha: .3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: _AccessColors.wine,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: _AccessColors.wine,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                key: const Key('register-submit'),
                onPressed: busy ? null : onSubmit,
                style: _primaryButtonStyle(),
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Crear cuenta y continuar'),
              ),
              const Spacer(),
              const SizedBox(height: 18),
              const _DemoNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterHero extends StatelessWidget {
  const _RegisterHero({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: _AccessColors.ivory),
        Positioned(
          right: -72,
          top: -88,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              color: _AccessColors.wine.withValues(alpha: .07),
              shape: BoxShape.circle,
              border: Border.all(
                color: _AccessColors.gold.withValues(alpha: .24),
              ),
            ),
          ),
        ),
        Positioned(
          right: 24,
          bottom: 62,
          child: Icon(
            Icons.filter_vintage_rounded,
            size: 72,
            color: _AccessColors.gold.withValues(alpha: .15),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 10,
            20,
            52,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _RoundBackButton(onPressed: onBack),
                  const Spacer(),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: _AccessColors.wine,
                      shape: BoxShape.circle,
                      border: Border.all(color: _AccessColors.gold, width: 1.4),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'COMPLEJO INTERCULTURAL Y DEPORTIVO',
                style: BrandType.institutional.copyWith(
                  color: _AccessColors.goldDeep,
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Mushuc Runa',
                style: BrandType.wordmark.copyWith(
                  color: _AccessColors.wine,
                  fontSize: 28,
                  height: .95,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView({
    super.key,
    required this.question,
    required this.visitReasons,
    required this.visitFrequency,
    required this.recommendationReasons,
    required this.canContinue,
    required this.onVisitReason,
    required this.onVisitFrequency,
    required this.onRecommendation,
    required this.onBack,
    required this.onContinue,
  });

  final int question;
  final Set<String> visitReasons;
  final String? visitFrequency;
  final Set<String> recommendationReasons;
  final bool canContinue;
  final ValueChanged<String> onVisitReason;
  final ValueChanged<String> onVisitFrequency;
  final ValueChanged<String> onRecommendation;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  static const _visitOptions = <({String label, IconData icon})>[
    (label: 'Shows', icon: Icons.theater_comedy_outlined),
    (label: 'Conciertos', icon: Icons.mic_external_on_outlined),
    (label: 'Granja', icon: Icons.pets_outlined),
    (label: 'Atracciones', icon: Icons.attractions_outlined),
    (label: 'Todo', icon: Icons.auto_awesome_outlined),
  ];
  static const _frequencyOptions = <({String label, IconData icon})>[
    (label: 'Primera vez', icon: Icons.waving_hand_outlined),
    (label: '1 vez', icon: Icons.looks_one_outlined),
    (label: '2 veces', icon: Icons.looks_two_outlined),
    (label: '3 veces', icon: Icons.looks_3_outlined),
    (label: 'Más de 3', icon: Icons.favorite_outline_rounded),
  ];
  static const _recommendationOptions = <({String label, IconData icon})>[
    (label: 'Diversión familiar', icon: Icons.family_restroom_outlined),
    (label: 'Espectáculos', icon: Icons.celebration_outlined),
    (label: 'Organización', icon: Icons.event_available_outlined),
    (label: 'Atención', icon: Icons.volunteer_activism_outlined),
    (label: 'Variedad', icon: Icons.dashboard_customize_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AccessColors.wine,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final topInset = MediaQuery.paddingOf(context).top;
          final maxSheetTop = constraints.maxHeight * .3;
          final sheetTop = (topInset + 176)
              .clamp(176.0, maxSheetTop)
              .toDouble();
          final horizontalInset = constraints.maxWidth > 680
              ? (constraints.maxWidth - 560) / 2
              : 0.0;

          return Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: _AccessColors.wine)),
              Positioned(
                top: topInset + 10,
                left: 18 + horizontalInset,
                right: 18 + horizontalInset,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _RoundBackButton(
                          key: const Key('onboarding-back'),
                          onPressed: onBack,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: (question + 1) / 3,
                              backgroundColor: Colors.white.withValues(
                                alpha: .2,
                              ),
                              color: _AccessColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Text(
                          '${question + 1} de 3',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 210),
                      child: _OnboardingStepHeader(
                        key: ValueKey('step-header-$question'),
                        icon: _stepIcon,
                        eyebrow: _stepEyebrow,
                        subtitle: question == 2
                            ? 'Último paso de tu perfil'
                            : 'Personaliza tu experiencia',
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: sheetTop,
                bottom: 0,
                left: horizontalInset,
                right: horizontalInset,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    fit: StackFit.expand,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey('question-$question'),
                    child: _questionBody(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String get _stepEyebrow => switch (question) {
    0 => 'TU VISITA',
    1 => 'TU HISTORIA',
    _ => 'TU RECOMENDACIÓN',
  };

  IconData get _stepIcon => switch (question) {
    0 => Icons.explore_outlined,
    1 => Icons.calendar_month_outlined,
    _ => Icons.favorite_border_rounded,
  };

  Widget _questionBody() {
    if (question == 0) {
      return _QuestionCard(
        eyebrow: 'TU VISITA',
        title: '¿Qué te trae a Mushuc Runa?',
        description:
            'Elige una o varias opciones para destacar lo que más te interesa.',
        icon: Icons.explore_outlined,
        canContinue: canContinue,
        onContinue: onContinue,
        child: _OptionGrid(
          options: _visitOptions,
          isSelected: visitReasons.contains,
          onTap: onVisitReason,
        ),
      );
    }
    if (question == 1) {
      return _QuestionCard(
        eyebrow: 'TU HISTORIA',
        title: '¿Cuántas veces nos has visitado?',
        description:
            'Así sabremos si debemos presentarte el complejo o mostrarte novedades.',
        icon: Icons.calendar_month_outlined,
        canContinue: canContinue,
        onContinue: onContinue,
        child: _OptionGrid(
          options: _frequencyOptions,
          isSelected: (value) => visitFrequency == value,
          onTap: onVisitFrequency,
        ),
      );
    }
    return _QuestionCard(
      eyebrow: 'TU RECOMENDACIÓN',
      title: '¿Qué te haría recomendar nuestra experiencia?',
      description:
          'Selecciona aquello que convertiría tu visita en un recuerdo especial.',
      icon: Icons.favorite_border_rounded,
      canContinue: canContinue,
      onContinue: onContinue,
      isLast: true,
      child: _OptionGrid(
        options: _recommendationOptions,
        isSelected: recommendationReasons.contains,
        onTap: onRecommendation,
      ),
    );
  }
}

class _OnboardingStepHeader extends StatelessWidget {
  const _OnboardingStepHeader({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.subtitle,
  });

  final IconData icon;
  final String eyebrow;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 51,
          height: 51,
          decoration: BoxDecoration(
            color: _AccessColors.gold.withValues(alpha: .17),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _AccessColors.gold.withValues(alpha: .45),
            ),
          ),
          child: Icon(icon, color: _AccessColors.gold, size: 25),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: BrandType.institutional.copyWith(
                  color: _AccessColors.gold,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.auto_awesome_rounded,
          color: _AccessColors.gold,
          size: 21,
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.canContinue,
    required this.onContinue,
    required this.child,
    this.isLast = false,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final bool canContinue;
  final VoidCallback onContinue;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      key: const Key('onboarding-full-sheet'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: _AccessColors.wineDeep.withValues(alpha: .2),
            blurRadius: 28,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        child: SizedBox.expand(
          key: const Key('onboarding-question-card'),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _AccessColors.gold.withValues(alpha: .18),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              icon,
                              color: _AccessColors.goldDeep,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              eyebrow,
                              style: BrandType.institutional.copyWith(
                                color: _AccessColors.wine,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _AccessColors.gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      Text(
                        title,
                        style: const TextStyle(
                          color: _AccessColors.ink,
                          fontSize: 27,
                          height: 1.02,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.75,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        description,
                        style: const TextStyle(
                          color: _AccessColors.muted,
                          height: 1.38,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 19),
                      child,
                    ],
                  ),
                ),
              ),
              Container(
                color: _AccessColors.ivory,
                padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + bottomInset),
                child: FilledButton.icon(
                  key: Key(isLast ? 'onboarding-finish' : 'onboarding-next'),
                  onPressed: canContinue ? onContinue : null,
                  style: _primaryButtonStyle(),
                  icon: Icon(
                    isLast
                        ? Icons.check_circle_outline_rounded
                        : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                  label: Text(isLast ? 'Terminar' : 'Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.options,
    required this.isSelected,
    required this.onTap,
  });

  final List<({String label, IconData icon})> options;
  final bool Function(String value) isSelected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final halfWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < options.length; index++)
              SizedBox(
                width: index == options.length - 1 && options.length.isOdd
                    ? constraints.maxWidth
                    : halfWidth,
                child: _OnboardingOptionCard(
                  label: options[index].label,
                  icon: options[index].icon,
                  selected: isSelected(options[index].label),
                  onTap: () => onTap(options[index].label),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OnboardingOptionCard extends StatelessWidget {
  const _OnboardingOptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: Key('onboarding-option-$label'),
      button: true,
      selected: selected,
      label: label,
      child: AnimatedScale(
        scale: selected ? 1 : .985,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Material(
          color: selected ? _AccessColors.wine : _AccessColors.ivory,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 92,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? _AccessColors.gold : _AccessColors.line,
                  width: selected ? 2 : 1.4,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _AccessColors.wine.withValues(alpha: .2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: selected
                          ? _AccessColors.gold.withValues(alpha: .18)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: selected
                          ? _AccessColors.gold
                          : _AccessColors.goldDeep,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : _AccessColors.ink,
                        height: 1.05,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey('selected'),
                            color: _AccessColors.gold,
                            size: 19,
                          )
                        : const SizedBox(key: ValueKey('idle'), width: 2),
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

class _AccessField extends StatelessWidget {
  const _AccessField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      autocorrect: !obscureText,
      enableSuggestions: !obscureText,
      style: const TextStyle(
        color: _AccessColors.ink,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 21),
        filled: true,
        fillColor: _AccessColors.ivory.withValues(alpha: .62),
        labelStyle: const TextStyle(
          color: _AccessColors.muted,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: _AccessColors.muted.withValues(alpha: .65),
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: _AccessColors.goldDeep,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _AccessColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _AccessColors.line, width: 1.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _AccessColors.wine, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _AccessColors.wine, width: 1.3),
        ),
      ),
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _AccessColors.wine,
        side: const BorderSide(color: _AccessColors.line),
        minimumSize: const Size(46, 46),
      ),
      tooltip: 'Volver',
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 17),
      child: Row(
        children: [
          Expanded(child: Divider(color: _AccessColors.line)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 11),
            child: Text(
              'O INGRESA CON TU CORREO',
              style: TextStyle(
                color: _AccessColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
          ),
          Expanded(child: Divider(color: _AccessColors.line)),
        ],
      ),
    );
  }
}

class _LoginSupportPanel extends StatelessWidget {
  const _LoginSupportPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('login-support-panel'),
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _AccessColors.ivory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AccessColors.line),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -9,
            top: -16,
            child: Icon(
              Icons.filter_vintage_rounded,
              size: 66,
              color: _AccessColors.gold.withValues(alpha: .12),
            ),
          ),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SupportMark(),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Todo listo para explorar',
                      style: TextStyle(
                        color: _AccessColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Mapa, shows y atracciones en un solo lugar',
                      style: TextStyle(
                        color: _AccessColors.muted,
                        fontSize: 10.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 7),
                    _DemoNote(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupportMark extends StatelessWidget {
  const _SupportMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _AccessColors.gold, width: 1.5),
      ),
      child: const Icon(
        Icons.explore_outlined,
        color: _AccessColors.wine,
        size: 21,
      ),
    );
  }
}

class _DemoNote extends StatelessWidget {
  const _DemoNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, size: 12, color: _AccessColors.wine),
        SizedBox(width: 5),
        Flexible(
          child: Text(
            'Demostración visual · no guardamos tus datos',
            style: TextStyle(
              color: _AccessColors.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Escribe un correo válido';
  }
  return null;
}

String? _passwordValidator(String? value) {
  if ((value ?? '').length < 6) return 'Usa al menos 6 caracteres';
  return null;
}

ButtonStyle _primaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: _AccessColors.wine,
    foregroundColor: Colors.white,
    disabledBackgroundColor: _AccessColors.line,
    disabledForegroundColor: _AccessColors.muted,
    minimumSize: const Size.fromHeight(54),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
  );
}
