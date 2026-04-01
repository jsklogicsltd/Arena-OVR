import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String athleteId;
  final String coachId;
  final String teamId;
  final String schoolId;
  final String seasonId;
  final String category;
  /// Challenge / subcategory label (e.g. "Strength Improvement"). OVR buckets use [category].
  final String? subcategory;
  final int value;
  final String? note;
  final String type;
  final DateTime? createdAt;
  final bool isArchived;

  TransactionModel({
    required this.id,
    required this.athleteId,
    required this.coachId,
    required this.teamId,
    required this.schoolId,
    required this.seasonId,
    required this.category,
    this.subcategory,
    required this.value,
    this.note,
    required this.type,
    this.createdAt,
    this.isArchived = false,
  });

  TransactionModel copyWith({
    String? id,
    String? athleteId,
    String? coachId,
    String? teamId,
    String? schoolId,
    String? seasonId,
    String? category,
    String? subcategory,
    int? value,
    String? note,
    String? type,
    DateTime? createdAt,
    bool? isArchived,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      athleteId: athleteId ?? this.athleteId,
      coachId: coachId ?? this.coachId,
      teamId: teamId ?? this.teamId,
      schoolId: schoolId ?? this.schoolId,
      seasonId: seasonId ?? this.seasonId,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      value: value ?? this.value,
      note: note ?? this.note,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      athleteId: json['athleteId'] ?? '',
      coachId: json['coachId'] ?? '',
      teamId: json['teamId'] ?? '',
      schoolId: json['schoolId'] ?? '',
      seasonId: json['seasonId'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'] as String?,
      value: json['value'] ?? 0,
      note: json['note'],
      type: json['type'] ?? '',
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : null,
      isArchived: json['isArchived'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'athleteId': athleteId,
      'coachId': coachId,
      'teamId': teamId,
      'schoolId': schoolId,
      'seasonId': seasonId,
      'category': category,
      if (subcategory != null && subcategory!.isNotEmpty) 'subcategory': subcategory,
      'value': value,
      'note': note,
      'type': type,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'isArchived': isArchived,
    };
  }
}