enum AccessProvider { guest, local, googleDemo }

enum AccessRole { visitor, admin }

class VisitorProfile {
  const VisitorProfile({
    this.visitReasons = const <String>{},
    this.visitFrequency,
    this.recommendationReasons = const <String>{},
  });

  final Set<String> visitReasons;
  final String? visitFrequency;
  final Set<String> recommendationReasons;

  bool get isEmpty =>
      visitReasons.isEmpty &&
      visitFrequency == null &&
      recommendationReasons.isEmpty;
}

class AccessSession {
  const AccessSession({
    required this.displayName,
    required this.email,
    required this.provider,
    this.profile = const VisitorProfile(),
    this.role = AccessRole.visitor,
  });

  const AccessSession.guest()
    : displayName = 'Visitante',
      email = '',
      provider = AccessProvider.guest,
      profile = const VisitorProfile(),
      role = AccessRole.visitor;

  final String displayName;
  final String email;
  final AccessProvider provider;
  final VisitorProfile profile;
  final AccessRole role;

  bool get isGuest => provider == AccessProvider.guest;
  bool get isAdmin => role == AccessRole.admin;
}
