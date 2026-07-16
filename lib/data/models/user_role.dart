import 'team.dart';

enum UserRoleType { guest, player, captain, referee, admin }

class UserRole {
  const UserRole({
    required this.type,
    this.email,
    this.team,
    this.refereeName,
  });

  final UserRoleType type;
  final String? email;
  final Team? team;
  final String? refereeName;

  bool get canManageLiveMatch =>
      type == UserRoleType.admin || type == UserRoleType.referee;

  String get label {
    return switch (type) {
      UserRoleType.admin => 'Administrator',
      UserRoleType.referee => 'Sędzia',
      UserRoleType.captain => 'Kapitan',
      UserRoleType.player => 'Zawodnik',
      UserRoleType.guest => 'Gość',
    };
  }
}
