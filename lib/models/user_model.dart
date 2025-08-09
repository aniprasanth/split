class SplitzyUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> preferences;

  SplitzyUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
    Map<String, dynamic>? preferences,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    preferences = preferences ?? <String, dynamic>{};

  factory SplitzyUser.fromMap(Map<String, dynamic> data) {
    try {
      return SplitzyUser(
        uid: data['uid'] ?? '',
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        photoUrl: data['photoUrl'],
        phoneNumber: data['phoneNumber'],
        createdAt: data['createdAt'] is String 
            ? DateTime.parse(data['createdAt']) 
            : data['createdAt'] is DateTime
                ? data['createdAt']
                : data['createdAt']?.toDate() ?? DateTime.now(),
        updatedAt: data['updatedAt'] is String 
            ? DateTime.parse(data['updatedAt']) 
            : data['updatedAt'] is DateTime
                ? data['updatedAt']
                : data['updatedAt']?.toDate() ?? DateTime.now(),
        isActive: data['isActive'] ?? true,
        preferences: data['preferences'] != null 
            ? Map<String, dynamic>.from(data['preferences'])
            : <String, dynamic>{},
      );
    } catch (e) {
      throw Exception('Error parsing SplitzyUser: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'preferences': preferences,
    };
  }

  SplitzyUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? preferences,
  }) {
    return SplitzyUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
    );
  }

  String get displayName => name.isNotEmpty ? name : email.split('@')[0];
  
  String get initials {
    if (name.isEmpty) return email.substring(0, 1).toUpperCase();
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  T? getPreference<T>(String key, {T? defaultValue}) {
    return preferences[key] as T? ?? defaultValue;
  }

  SplitzyUser setPreference(String key, dynamic value) {
    final newPreferences = Map<String, dynamic>.from(preferences);
    newPreferences[key] = value;
    return copyWith(preferences: newPreferences);
  }
}
