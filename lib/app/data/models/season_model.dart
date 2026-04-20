import 'package:cloud_firestore/cloud_firestore.dart';

class SeasonModel {
  final String id;
  final String teamId;
  final String schoolId;
  final int seasonNumber;
  final DateTime? startDate;
  final DateTime? endDate;
  final int seasonLengthDays; // min 7
  final int startingOvrBaseline; // min 0, max 90
  final bool isActive;
  final DateTime? revealDate;
  final DateTime? createdAt;

  SeasonModel({
    required this.id,
    required this.teamId,
    required this.schoolId,
    required this.seasonNumber,
    this.startDate,
    this.endDate,
    this.seasonLengthDays = 15,
    this.startingOvrBaseline = 50,
    this.isActive = true,
    this.revealDate,
    this.createdAt,
  });

  SeasonModel copyWith({
    String? id,
    String? teamId,
    String? schoolId,
    int? seasonNumber,
    DateTime? startDate,
    DateTime? endDate,
    int? seasonLengthDays,
    int? startingOvrBaseline,
    bool? isActive,
    DateTime? revealDate,
    DateTime? createdAt,
  }) {
    return SeasonModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      schoolId: schoolId ?? this.schoolId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      seasonLengthDays: seasonLengthDays ?? this.seasonLengthDays,
      startingOvrBaseline: startingOvrBaseline ?? this.startingOvrBaseline,
      isActive: isActive ?? this.isActive,
      revealDate: revealDate ?? this.revealDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id'] ?? '',
      teamId: json['teamId'] ?? '',
      schoolId: json['schoolId'] ?? '',
      seasonNumber: json['seasonNumber'] ?? 1,
      startDate: json['startDate'] != null ? (json['startDate'] as Timestamp).toDate() : null,
      endDate: json['endDate'] != null ? (json['endDate'] as Timestamp).toDate() : null,
      seasonLengthDays: ((json['seasonLengthDays'] ?? 15) as num).toInt().clamp(7, 365),
      startingOvrBaseline: ((json['startingOvrBaseline'] ?? 50) as num).toInt().clamp(0, 90),
      isActive: json['isActive'] ?? true,
      revealDate: json['revealDate'] != null ? (json['revealDate'] as Timestamp).toDate() : null,
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'schoolId': schoolId,
      'seasonNumber': seasonNumber,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'seasonLengthDays': seasonLengthDays,
      'startingOvrBaseline': startingOvrBaseline,
      'isActive': isActive,
      'revealDate': revealDate != null ? Timestamp.fromDate(revealDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}