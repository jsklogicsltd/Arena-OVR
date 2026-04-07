import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String schoolId;
  final String? schoolName;
  final String? schoolInviteCode;
  final String name;
  final String teamCode;
  /// Sport or program label (e.g. FOOTBALL, Multi-Sport). Optional for legacy docs.
  final String? sport;
  final bool isActive;
  final List<String> positionGroups; // OFFENSE/DEFENSE/...
  final List<String> customTags; // e.g. Seniors, JV
  final String primaryColor;
  final String secondaryColor;
  final String? logoUrl;
  final String? currentSeasonId;
  final int totalRatingsThisSeason;
  final int averageOvr;
  final DateTime? createdAt;
  final String createdBy;

  TeamModel({
    required this.id,
    required this.schoolId,
    this.schoolName,
    this.schoolInviteCode,
    required this.name,
    required this.teamCode,
    this.sport,
    this.isActive = true,
    this.positionGroups = const ['OFFENSE', 'DEFENSE', 'SPECIAL TEAMS'],
    this.customTags = const [],
    required this.primaryColor,
    required this.secondaryColor,
    this.logoUrl,
    this.currentSeasonId,
    this.totalRatingsThisSeason = 0,
    this.averageOvr = 0,
    this.createdAt,
    required this.createdBy,
  });

  TeamModel copyWith({
    String? id,
    String? schoolId,
    String? schoolName,
    String? schoolInviteCode,
    String? name,
    String? teamCode,
    String? sport,
    bool? isActive,
    List<String>? positionGroups,
    List<String>? customTags,
    String? primaryColor,
    String? secondaryColor,
    String? logoUrl,
    String? currentSeasonId,
    int? totalRatingsThisSeason,
    int? averageOvr,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return TeamModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      schoolInviteCode: schoolInviteCode ?? this.schoolInviteCode,
      name: name ?? this.name,
      teamCode: teamCode ?? this.teamCode,
      sport: sport ?? this.sport,
      isActive: isActive ?? this.isActive,
      positionGroups: positionGroups ?? this.positionGroups,
      customTags: customTags ?? this.customTags,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      logoUrl: logoUrl ?? this.logoUrl,
      currentSeasonId: currentSeasonId ?? this.currentSeasonId,
      totalRatingsThisSeason: totalRatingsThisSeason ?? this.totalRatingsThisSeason,
      averageOvr: averageOvr ?? this.averageOvr,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] ?? '',
      schoolId: json['schoolId'] ?? '',
      schoolName: json['schoolName'],
      schoolInviteCode: json['schoolInviteCode'],
      name: json['name'] ?? '',
      teamCode: json['teamCode'] ?? '',
      sport: json['sport'] as String?,
      isActive: json['isActive'] ?? true,
      positionGroups: json['positionGroups'] != null
          ? List<String>.from(json['positionGroups'])
          : const ['OFFENSE', 'DEFENSE', 'SPECIAL TEAMS'],
      customTags:
          json['customTags'] != null ? List<String>.from(json['customTags']) : const [],
      primaryColor: json['primaryColor'] ?? '',
      secondaryColor: json['secondaryColor'] ?? '',
      logoUrl: json['logoUrl'],
      currentSeasonId: json['currentSeasonId'],
      totalRatingsThisSeason: json['totalRatingsThisSeason'] ?? 0,
      averageOvr: json['averageOvr'] ?? 0,
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : null,
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'schoolInviteCode': schoolInviteCode,
      'name': name,
      'teamCode': teamCode,
      if (sport != null && sport!.isNotEmpty) 'sport': sport,
      'isActive': isActive,
      'positionGroups': positionGroups,
      'customTags': customTags,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'logoUrl': logoUrl,
      'currentSeasonId': currentSeasonId,
      'totalRatingsThisSeason': totalRatingsThisSeason,
      'averageOvr': averageOvr,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'createdBy': createdBy,
    };
  }
}