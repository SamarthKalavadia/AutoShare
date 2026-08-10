import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReportModel extends Equatable {
  final String reportId;
  final String reporterUid;
  final String reportedUid;
  final String reason;
  final DateTime createdAt;

  const ReportModel({
    required this.reportId,
    required this.reporterUid,
    required this.reportedUid,
    required this.reason,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        reportId,
        reporterUid,
        reportedUid,
        reason,
        createdAt,
      ];

  ReportModel copyWith({
    String? reportId,
    String? reporterUid,
    String? reportedUid,
    String? reason,
    DateTime? createdAt,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      reporterUid: reporterUid ?? this.reporterUid,
      reportedUid: reportedUid ?? this.reportedUid,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      reportId: id,
      reporterUid: map['reporterUid'] as String? ?? '',
      reportedUid: map['reportedUid'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
