import 'package:uuid/uuid.dart';

enum SettlementStatus {
  pending,
  completed,
  cancelled
}

class SettlementModel {
  final String id;
  final String fromUser;
  final String fromUserName;
  final String toUser;
  final String toUserName;
  final double amount;
  final String groupId;
  final String groupName;
  final DateTime date;
  final SettlementStatus status;
  final String? paymentMethod;
  final String? transactionId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? deletedGroupId;
  final String? deletedGroupName;
  final bool isDeleted;
  final DateTime? cancelledAt;
  final String? cancelledReason;
  final String? relatedExpenseId;

  SettlementModel({
    required this.id,
    required this.fromUser,
    required this.fromUserName,
    required this.toUser,
    required this.toUserName,
    required this.amount,
    required this.groupId,
    required this.groupName,
    required this.date,
    this.status = SettlementStatus.pending,
    this.paymentMethod,
    this.transactionId,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.deletedGroupId,
    this.deletedGroupName,
    this.isDeleted = false,
    this.cancelledAt,
    this.cancelledReason,
    this.relatedExpenseId,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory SettlementModel.fromMap(Map<String, dynamic> data) {
    try {
      return SettlementModel(
        id: data['id'] ?? '',
        fromUser: data['fromUser'] ?? '',
        fromUserName: data['fromUserName'] ?? 'Unknown',
        toUser: data['toUser'] ?? '',
        toUserName: data['toUserName'] ?? 'Unknown',
        amount: (data['amount'] ?? 0).toDouble(),
        groupId: data['groupId'] ?? '',
        groupName: data['groupName'] ?? '',
        date: data['date'] is String 
            ? DateTime.parse(data['date']) 
            : data['date'] is DateTime
                ? data['date']
                : data['date']?.toDate() ?? DateTime.now(),
        status: _parseStatus(data['status']),
        paymentMethod: data['paymentMethod'],
        transactionId: data['transactionId'],
        notes: data['notes'],
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
        cancelledAt: data['cancelledAt'] is String 
            ? DateTime.parse(data['cancelledAt']) 
            : data['cancelledAt'] is DateTime
                ? data['cancelledAt']
                : data['cancelledAt']?.toDate(),
        cancelledReason: data['cancelledReason'],
        relatedExpenseId: data['relatedExpenseId'],
      );
    } catch (e) {
      throw Exception('Error parsing SettlementModel: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUser': fromUser,
      'fromUserName': fromUserName,
      'toUser': toUser,
      'toUserName': toUserName,
      'amount': amount,
      'groupId': groupId,
      'groupName': groupName,
      'date': date.toIso8601String(),
      'status': status.name,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedGroupId': deletedGroupId,
      'deletedGroupName': deletedGroupName,
      'isDeleted': isDeleted,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelledReason': cancelledReason,
      'relatedExpenseId': relatedExpenseId,
    };
  }

  static SettlementStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'pending':
          return SettlementStatus.pending;
        case 'completed':
          return SettlementStatus.completed;
        case 'cancelled':
          return SettlementStatus.cancelled;
        default:
          return SettlementStatus.pending;
      }
    }
    return SettlementStatus.pending;
  }

  SettlementModel copyWith({
    String? id,
    String? fromUser,
    String? fromUserName,
    String? toUser,
    String? toUserName,
    double? amount,
    String? groupId,
    String? groupName,
    DateTime? date,
    SettlementStatus? status,
    String? paymentMethod,
    String? transactionId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedGroupId,
    String? deletedGroupName,
    bool? isDeleted,
    DateTime? cancelledAt,
    String? cancelledReason,
    String? relatedExpenseId,
  }) {
    return SettlementModel(
      id: id ?? this.id,
      fromUser: fromUser ?? this.fromUser,
      fromUserName: fromUserName ?? this.fromUserName,
      toUser: toUser ?? this.toUser,
      toUserName: toUserName ?? this.toUserName,
      amount: amount ?? this.amount,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      date: date ?? this.date,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      deletedGroupId: deletedGroupId ?? this.deletedGroupId,
      deletedGroupName: deletedGroupName ?? this.deletedGroupName,
      isDeleted: isDeleted ?? this.isDeleted,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      relatedExpenseId: relatedExpenseId ?? this.relatedExpenseId,
    );
  }

  static SettlementModel create({
    required String fromUser,
    required String fromUserName,
    required String toUser,
    required String toUserName,
    required double amount,
    required String groupId,
    required String groupName,
    DateTime? date,
    String? paymentMethod,
    String? notes,
  }) {
    return SettlementModel(
      id: const Uuid().v4(),
      fromUser: fromUser,
      fromUserName: fromUserName,
      toUser: toUser,
      toUserName: toUserName,
      amount: amount,
      groupId: groupId,
      groupName: groupName,
      date: date ?? DateTime.now(),
      paymentMethod: paymentMethod,
      notes: notes,
    );
  }

  // Fixed getter methods with proper syntax
  bool get isPending => status == SettlementStatus.pending;
  bool get isCompleted => status == SettlementStatus.completed;
  bool get isCancelled => status == SettlementStatus.cancelled;

  bool involves(String userId) {
    return fromUser == userId || toUser == userId;
  }
}

