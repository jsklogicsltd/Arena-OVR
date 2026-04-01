import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? profilePicUrl;
  final String role; // superadmin/coach/athlete
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
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

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
    this.createdAt,
    this.lastActiveAt,
  });

  /// OVR always visible to coaches — uses actualOvr on Day 1 when displayed ovr is 0.
  int get coachVisibleOvr => (actualOvr != null && actualOvr! > 0) ? actualOvr! : ovr;

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
    DateTime? createdAt,
    DateTime? lastActiveAt,
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
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
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
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : null,
      lastActiveAt: json['lastActiveAt'] != null ? (json['lastActiveAt'] as Timestamp).toDate() : null,
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
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }
}