import 'package:uuid/uuid.dart';

class GroupModel {
  final String id;
  final String name;
  final List<String> members;
  final Map<String, String> memberNames;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  GroupModel({
    required this.id,
    required this.name,
    required this.members,
    required this.memberNames,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.description,
    this.imageUrl,
    this.isActive = true,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory GroupModel.fromMap(Map<String, dynamic> data) {
    try {
      return GroupModel(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        members: data['members'] != null 
            ? List<String>.from(data['members']) 
            : <String>[],
        memberNames: data['memberNames'] != null 
            ? Map<String, String>.from(data['memberNames']) 
            : <String, String>{},
        createdBy: data['createdBy'] ?? '',
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
        description: data['description'],
        imageUrl: data['imageUrl'],
        isActive: data['isActive'] ?? true,
      );
    } catch (e) {
      throw Exception('Error parsing GroupModel: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'members': members,
      'memberNames': memberNames,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    List<String>? members,
    Map<String, String>? memberNames,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      memberNames: memberNames ?? this.memberNames,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  static GroupModel create({
    required String name,
    required List<String> members,
    required Map<String, String> memberNames,
    required String createdBy,
    String? description,
    String? imageUrl,
  }) {
    return GroupModel(
      id: const Uuid().v4(),
      name: name,
      members: members,
      memberNames: memberNames,
      createdBy: createdBy,
      description: description,
      imageUrl: imageUrl,
    );
  }

  bool isMember(String userId) {
    return members.contains(userId);
  }

  String getMemberName(String userId) {
    return memberNames[userId] ?? 'Unknown User';
  }

  int get memberCount => members.length;

  bool get hasMultipleMembers => members.length > 1;
}
