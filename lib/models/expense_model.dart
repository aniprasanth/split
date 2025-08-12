import 'package:uuid/uuid.dart';

class ExpenseModel {
  final String id;
  final String groupId;
  final String payer;
  final String payerName;
  final double amount;
  final String description;
  final DateTime date;
  final Map<String, double> split;
  final String? category;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? deletedGroupId;
  final String? deletedGroupName;
  final bool isDeleted;
  final SplitType splitType;
  final Map<String, double>? customRatios;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.payer,
    required this.payerName,
    required this.amount,
    required this.description,
    required this.date,
    required this.split,
    this.category,
    this.imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.deletedGroupId,
    this.deletedGroupName,
    this.isDeleted = false,
    this.splitType = SplitType.equal,
    this.customRatios,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory ExpenseModel.fromMap(Map<String, dynamic> data) {
    try {
      return ExpenseModel(
        id: data['id'] ?? '',
        groupId: data['groupId'] ?? '',
        payer: data['payer'] ?? '',
        payerName: data['payerName'] ?? 'Unknown',
        amount: (data['amount'] ?? 0).toDouble(),
        description: data['description'] ?? '',
        date: data['date'] is String 
            ? DateTime.parse(data['date']) 
            : data['date'] is DateTime
                ? data['date']
                : data['date']?.toDate() ?? DateTime.now(),
        split: data['split'] != null 
            ? Map<String, double>.from(data['split']) 
            : <String, double>{},
        category: data['category'],
        imageUrl: data['imageUrl'],
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
        deletedAt: data['deletedAt'] is String 
            ? DateTime.parse(data['deletedAt']) 
            : data['deletedAt'] is DateTime
                ? data['deletedAt']
                : data['deletedAt']?.toDate(),
        deletedGroupId: data['deletedGroupId'],
        deletedGroupName: data['deletedGroupName'],
        isDeleted: data['isDeleted'] ?? false,
        splitType: SplitType.values[data['splitType'] ?? 0],
        customRatios: data['customRatios'] != null 
            ? Map<String, double>.from(data['customRatios'])
            : null,
      );
    } catch (e) {
      throw Exception('Error parsing ExpenseModel: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'payer': payer,
      'payerName': payerName,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'split': split,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedGroupId': deletedGroupId,
      'deletedGroupName': deletedGroupName,
      'isDeleted': isDeleted,
      'splitType': splitType.index,
      'customRatios': customRatios,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? groupId,
    String? payer,
    String? payerName,
    double? amount,
    String? description,
    DateTime? date,
    Map<String, double>? split,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedGroupId,
    String? deletedGroupName,
    bool? isDeleted,
    SplitType? splitType,
    Map<String, double>? customRatios,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      payer: payer ?? this.payer,
      payerName: payerName ?? this.payerName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      split: split ?? this.split,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      deletedGroupId: deletedGroupId ?? this.deletedGroupId,
      deletedGroupName: deletedGroupName ?? this.deletedGroupName,
      isDeleted: isDeleted ?? this.isDeleted,
      splitType: splitType ?? this.splitType,
      customRatios: customRatios ?? this.customRatios,
    );
  }

  static ExpenseModel create({
    required String groupId,
    required String payer,
    required String payerName,
    required double amount,
    required String description,
    required Map<String, double> split,
    DateTime? date,
    String? category,
    String? imageUrl,
    SplitType splitType = SplitType.equal,
    Map<String, double>? customRatios,
  }) {
    return ExpenseModel(
      id: const Uuid().v4(),
      groupId: groupId,
      payer: payer,
      payerName: payerName,
      amount: amount,
      description: description,
      date: date ?? DateTime.now(),
      split: split,
      category: category,
      imageUrl: imageUrl,
      splitType: splitType,
      customRatios: customRatios,
    );
  }

  double getAmountForUser(String userId) {
    return split[userId] ?? 0.0;
  }

  bool isUserInvolved(String userId) {
    return payer == userId || split.containsKey(userId);
  }
}