import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? profilePicUrl;
  /// [superadmin] | [athlete] | legacy [coach] | [Head Coach] | [Assistant Coach]
  final String role;
  final String? schoolId;
  final String? teamId; // for athletes - single team
  final List<String> teamIds; // for coaches - all teams they manage
  final String? activeTeamId; // for coaches - currently selected team
  final String? jerseyNumber;
  final String? positionGroup;
  final String? customTag;
  final String? fcmToken;
  final Map<String, dynamic> currentRating;
  final int ovr; // 0-99
  final int? actualOvr;
  final int? ovrDay;
  final int? ovrCap;
  final int? rank;
  final int? previousRank;
  final List<String> badges;
  final bool hasUploadedPic;
  final Map<String, dynamic> currentStreak;
  final int dailyPoints;
  final DateTime? lastPointDate;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  // Scoring engine physical attributes
  final int? grade;
  final int? heightInches;
  final int? weightLbs;
  final String? powerProfile;
  final String? speedProfile;

  // Automated assessment results
  final int? automatedOvr;
  final Map<String, dynamic>? assessmentData;
  /// Final roster-relative OVR computed by the combined 50/50 curve engine.
  /// This is the single source of truth for display + leaderboards.
  final int? finalOvrValue;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.profilePicUrl,
    required this.role,
    this.schoolId,
    this.teamId,
    this.teamIds = const [],
    this.activeTeamId,
    this.jerseyNumber,
    this.positionGroup,
    this.customTag,
    this.fcmToken,
    this.currentRating = const {},
    this.ovr = 0,
    this.actualOvr,
    this.ovrDay,
    this.ovrCap,
    this.rank,
    this.previousRank,
    this.badges = const [],
    this.hasUploadedPic = false,
    this.currentStreak = const {},
    this.dailyPoints = 0,
    this.lastPointDate,
    this.createdAt,
    this.lastActiveAt,
    this.grade,
    this.heightInches,
    this.weightLbs,
    this.powerProfile,
    this.speedProfile,
    this.automatedOvr,
    this.assessmentData,
    this.finalOvrValue,
  });

  /// Final OVR used everywhere in UI.
  ///
  /// New rule: this must reflect the value computed and saved by the combined
  /// curve engine (manual + assessment 50/50, roster-relative).
  ///
  /// Fallback: if the curve value isn't present yet, use the manual OVR.
  int get finalOvr {
    final curve = finalOvrValue;
    if (curve != null) return curve.clamp(0, 99);
    return ((actualOvr != null && actualOvr! > 0) ? actualOvr! : ovr)
        .clamp(0, 99);
  }

  /// OVR always visible to coaches — uses [finalOvr] (curve from objective + subjective).
  int get coachVisibleOvr => finalOvr;

  /// Jersey for UI: null, empty, whitespace-only, or literal `"null"` → `"0"`.
  String get displayJerseyNumber {
    final j = (jerseyNumber ?? '').trim();
    if (j.isEmpty || j.toLowerCase() == 'null') return '0';
    return j;
  }

  /// Values that use coach app routing, invite flow, and admin coach lists.
  static const Set<String> coachRoleValues = {
    'coach',
    'Head Coach',
    'Assistant Coach',
  };

  static bool isCoachRole(String? role) =>
      role != null && coachRoleValues.contains(role);

  /// Settings badge (all caps).
  static String coachRoleBadgeUppercase(String? role) {
    switch (role) {
      case 'Assistant Coach':
        return 'ASSISTANT COACH';
      case 'Head Coach':
        return 'HEAD COACH';
      case 'coach':
      default:
        return 'HEAD COACH';
    }
  }

  /// Feed / announcements (`actorRole`).
  static String coachRoleTitleForFeed(String? role) {
    switch (role) {
      case 'Assistant Coach':
        return 'Assistant Coach';
      case 'Head Coach':
        return 'Head Coach';
      case 'coach':
      default:
        return 'Head Coach';
    }
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? profilePicUrl,
    String? role,
    String? schoolId,
    String? teamId,
    List<String>? teamIds,
    String? activeTeamId,
    String? jerseyNumber,
    String? positionGroup,
    String? customTag,
    String? fcmToken,
    Map<String, dynamic>? currentRating,
    int? ovr,
    int? actualOvr,
    int? ovrDay,
    int? ovrCap,
    int? rank,
    int? previousRank,
    List<String>? badges,
    bool? hasUploadedPic,
    Map<String, dynamic>? currentStreak,
    int? dailyPoints,
    DateTime? lastPointDate,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    int? grade,
    int? heightInches,
    int? weightLbs,
    String? powerProfile,
    String? speedProfile,
    int? automatedOvr,
    Map<String, dynamic>? assessmentData,
    int? finalOvrValue,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      role: role ?? this.role,
      schoolId: schoolId ?? this.schoolId,
      teamId: teamId ?? this.teamId,
      teamIds: teamIds ?? this.teamIds,
      activeTeamId: activeTeamId ?? this.activeTeamId,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      positionGroup: positionGroup ?? this.positionGroup,
      customTag: customTag ?? this.customTag,
      fcmToken: fcmToken ?? this.fcmToken,
      currentRating: currentRating ?? this.currentRating,
      ovr: ovr ?? this.ovr,
      actualOvr: actualOvr ?? this.actualOvr,
      ovrDay: ovrDay ?? this.ovrDay,
      ovrCap: ovrCap ?? this.ovrCap,
      rank: rank ?? this.rank,
      previousRank: previousRank ?? this.previousRank,
      badges: badges ?? this.badges,
      hasUploadedPic: hasUploadedPic ?? this.hasUploadedPic,
      currentStreak: currentStreak ?? this.currentStreak,
      dailyPoints: dailyPoints ?? this.dailyPoints,
      lastPointDate: lastPointDate ?? this.lastPointDate,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      grade: grade ?? this.grade,
      heightInches: heightInches ?? this.heightInches,
      weightLbs: weightLbs ?? this.weightLbs,
      powerProfile: powerProfile ?? this.powerProfile,
      speedProfile: speedProfile ?? this.speedProfile,
      automatedOvr: automatedOvr ?? this.automatedOvr,
      assessmentData: assessmentData ?? this.assessmentData,
      finalOvrValue: finalOvrValue ?? this.finalOvrValue,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profilePicUrl: json['profilePicUrl'],
      role: json['role'] ?? 'athlete',
      schoolId: json['schoolId'],
      teamId: json['teamId'],
      teamIds: json['teamIds'] != null ? List<String>.from(json['teamIds']) : [],
      activeTeamId: json['activeTeamId'],
      jerseyNumber: json['jerseyNumber']?.toString(),
      positionGroup: json['positionGroup'],
      customTag: json['customTag'],
      fcmToken: json['fcmToken'],
      currentRating: json['currentRating'] != null ? Map<String, dynamic>.from(json['currentRating']) : {},
      ovr: json['ovr'] ?? 0,
      actualOvr: json['actualOvr'],
      ovrDay: json['ovrDay'],
      ovrCap: json['ovrCap'],
      rank: json['rank'],
      previousRank: json['previousRank'],
      badges: json['badges'] != null ? List<String>.from(json['badges']) : [],
      hasUploadedPic: json['hasUploadedPic'] ?? false,
      currentStreak: json['currentStreak'] != null ? Map<String, dynamic>.from(json['currentStreak']) : {},
      dailyPoints: (json['dailyPoints'] as num?)?.toInt() ?? 0,
      lastPointDate: json['lastPointDate'] != null ? (json['lastPointDate'] as Timestamp).toDate() : null,
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : null,
      lastActiveAt: json['lastActiveAt'] != null ? (json['lastActiveAt'] as Timestamp).toDate() : null,
      grade: json['grade'] as int?,
      heightInches: json['heightInches'] as int?,
      weightLbs: json['weightLbs'] as int?,
      powerProfile: json['powerProfile'] as String?,
      speedProfile: json['speedProfile'] as String?,
      automatedOvr: json['automatedOvr'] as int?,
      assessmentData: json['assessmentData'] != null
          ? Map<String, dynamic>.from(json['assessmentData'])
          : null,
      finalOvrValue: (json['finalOvr'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'profilePicUrl': profilePicUrl,
      'role': role,
      'schoolId': schoolId,
      'teamId': teamId,
      'teamIds': teamIds,
      'activeTeamId': activeTeamId,
      'jerseyNumber': jerseyNumber,
      'positionGroup': positionGroup,
      'customTag': customTag,
      'fcmToken': fcmToken,
      'currentRating': currentRating,
      'ovr': ovr,
      'actualOvr': actualOvr,
      'ovrDay': ovrDay,
      'ovrCap': ovrCap,
      'rank': rank,
      'previousRank': previousRank,
      'badges': badges,
      'hasUploadedPic': hasUploadedPic,
      'currentStreak': currentStreak,
      'dailyPoints': dailyPoints,
      'lastPointDate': lastPointDate != null ? Timestamp.fromDate(lastPointDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'grade': grade,
      'heightInches': heightInches,
      'weightLbs': weightLbs,
      'powerProfile': powerProfile,
      'speedProfile': speedProfile,
      'automatedOvr': automatedOvr,
      'assessmentData': assessmentData,
      'finalOvr': finalOvrValue,
    };
  }
}