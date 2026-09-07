enum AppUserRole { patient, therapist }

class AppUser {
  final String id;
  final String email;
  final String password;
  final String displayName;
  final AppUserRole role;
  final String? patientId;

  const AppUser({
    required this.id,
    required this.email,
    required this.password,
    required this.displayName,
    required this.role,
    this.patientId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'displayName': displayName,
        'role': role.name,
        'patientId': patientId,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'V-HAB User',
      role: AppUserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => AppUserRole.patient,
      ),
      patientId: json['patientId'] as String?,
    );
  }
}