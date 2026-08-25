import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType { product, user }

enum ReportReason {
  scam,
  inappropriateContent,
  misleadingInfo,
  spam,
  harassment,
  other
}

class ReportModel {
  final String id;
  final String reporterId;
  final String targetId; // Product ID or User ID
  final ReportType targetType;
  final ReportReason reason;
  final String description;
  final DateTime timestamp;
  final String status; // 'pending', 'resolved', 'dismissed'
  // Reporting surface: 'web' | 'app'. Legacy reports (no field) read as 'both'.
  final String platform;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.description,
    required this.timestamp,
    this.status = 'pending',
    this.platform = 'both',
    this.resolvedBy,
    this.resolvedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType.name,
      'reason': reason.name,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'status': status,
      'platform': platform,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      targetId: data['targetId'] ?? '',
      targetType: ReportType.values.firstWhere(
          (e) => e.name == data['targetType'],
          orElse: () => ReportType.product),
      reason: ReportReason.values.firstWhere((e) => e.name == data['reason'],
          orElse: () => ReportReason.other),
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      platform: data['platform'] ?? 'both',
      resolvedBy: data['resolvedBy'],
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? targetId,
    ReportType? targetType,
    ReportReason? reason,
    String? description,
    DateTime? timestamp,
    String? status,
    String? resolvedBy,
    DateTime? resolvedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
