enum AccessProvider { guest, local, googleDemo }

class AccessSession {
  const AccessSession({
    required this.displayName,
    required this.email,
    required this.provider,
  });

  const AccessSession.guest()
    : displayName = 'Visitante',
      email = '',
      provider = AccessProvider.guest;

  final String displayName;
  final String email;
  final AccessProvider provider;

  bool get isGuest => provider == AccessProvider.guest;
}
