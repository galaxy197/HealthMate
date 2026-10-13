class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.heightCm,
    required this.createdAt,
    required this.updatedAt,
    required this.schemaVersion,
  });

  final String uid;
  final String displayName;
  final String email;
  final double? heightCm;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int schemaVersion;
}

class UserProfileDraft {
  const UserProfileDraft({required this.displayName, required this.heightCm});

  final String displayName;
  final double? heightCm;
}
