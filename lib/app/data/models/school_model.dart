import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolModel {
  final String id;
  final String name;
  final String email;
  final String inviteCode;
  final bool isActive;
  final DateTime? expiryDate;
  final int athleteCount;
  final int coachCount;
  final DateTime? createdAt;
  final String? logoUrl;

  SchoolModel({
    required this.id,
    required this.name,
    required this.email,
    required this.inviteCode,
    this.isActive = true,
    this.expiryDate,
    this.athleteCount = 0,
    this.coachCount = 0,
    this.createdAt,
    this.logoUrl,
  });

  SchoolModel copyWith({
    String? id,
    String? name,
    String? email,
    String? inviteCode,
    bool? isActive,
    DateTime? expiryDate,
    int? athleteCount,
    int? coachCount,
    DateTime? createdAt,
    String? logoUrl,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      inviteCode: inviteCode ?? this.inviteCode,
      isActive: isActive ?? this.isActive,
      expiryDate: expiryDate ?? this.expiryDate,
      athleteCount: athleteCount ?? this.athleteCount,
      coachCount: coachCount ?? this.coachCount,
      createdAt: createdAt ?? this.createdAt,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
      isActive: json['isActive'] ?? true,
      expiryDate: json['expiryDate'] != null ? (json['expiryDate'] as Timestamp).toDate() : null,
      athleteCount: json['athleteCount'] ?? 0,
      coachCount: json['coachCount'] ?? 0,
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : null,
      logoUrl: json['logoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'inviteCode': inviteCode,
      'isActive': isActive,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'athleteCount': athleteCount,
      'coachCount': coachCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'logoUrl': logoUrl,
    };
  }
}