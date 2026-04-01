import 'package:cloud_firestore/cloud_firestore.dart';

class FeedModel {
  final String id;
  final String teamId;
  final String schoolId;
  final String type;
  final String? actorId;
  final String? targetId;
  final String actorName;
  final String targetName;
  final String content;
  final String? category;
  /// Challenge / subcategory for RATING items (e.g. "Strength Improvement").
  final String? subcategory;
  final int? value;
  final bool isPinned;
  final DateTime? createdAt;
  final String? actorProfileUrl;
  final String? actorRole;

  FeedModel({
    required this.id,
    required this.teamId,
    required this.schoolId,
    required this.type,
    this.actorId,
    this.targetId,
    required this.actorName,
    required this.targetName,
    required this.content,
    this.category,
    this.subcategory,
    this.value,
    this.isPinned = false,
    this.createdAt,
    this.actorProfileUrl,
    this.actorRole,
  });

  FeedModel copyWith({
    String? id,
    String? teamId,
    String? schoolId,
    String? type,
    String? actorId,
    String? targetId,
    String? actorName,
    String? targetName,
    String? content,
    String? category,
    String? subcategory,
    int? value,
    bool? isPinned,
    DateTime? createdAt,
    String? actorProfileUrl,
    String? actorRole,
  }) {
    return FeedModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      schoolId: schoolId ?? this.schoolId,
      type: type ?? this.type,
      actorId: actorId ?? this.actorId,
      targetId: targetId ?? this.targetId,
      actorName: actorName ?? this.actorName,
      targetName: targetName ?? this.targetName,
      content: content ?? this.content,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      value: value ?? this.value,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      actorProfileUrl: actorProfileUrl ?? this.actorProfileUrl,
      actorRole: actorRole ?? this.actorRole,
    );
  }

  /// Short label when [targetName] is a Firebase uid instead of a person's name.
  String get targetDisplayLabel {
    final t = targetName.trim();
    if (t.isEmpty) {
      return 'an athlete';
    }
    if (t.length >= 18 && !RegExp(r'\s').hasMatch(t)) {
      return 'an athlete';
    }
    return t;
  }

  /// One line: points, pillar category, and challenge when present.
  String get ratingPointsDescription {
    final t = type.toUpperCase();
    if (t != 'RATING' && t != 'POINTS') {
      return content;
    }
    final v = value;
    final cat = (category ?? '').trim();
    final sub = (subcategory ?? '').trim();
    final parts = <String>[];
    if (v != null) {
      parts.add(v > 0 ? '+$v POINTS' : '$v POINTS');
    }
    if (cat.isNotEmpty) {
      parts.add('in ${cat.toUpperCase()}');
    }
    if (sub.isNotEmpty) {
      parts.add('· $sub');
    }
    if (parts.isEmpty) {
      return content;
    }
    return parts.join(' ');
  }

  factory FeedModel.fromJson(Map<String, dynamic> json) {
    return FeedModel(
      id: json['id'] ?? '',
      teamId: json['teamId'] ?? '',
      schoolId: json['schoolId'] ?? '',
      type: json['type'] ?? '',
      actorId: json['actorId'],
      targetId: json['targetId'],
      actorName: json['actorName'] ?? '',
      targetName: json['targetName'] ?? '',
      content: json['content'] ?? '',
      category: json['category'],
      subcategory: json['subcategory'] as String?,
      value: json['value'],
      isPinned: json['isPinned'] ?? false,
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : null,
      actorProfileUrl: json['actorProfileUrl'],
      actorRole: json['actorRole'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'schoolId': schoolId,
      'type': type,
      'actorId': actorId,
      'targetId': targetId,
      'actorName': actorName,
      'targetName': targetName,
      'content': content,
      'category': category,
      if (subcategory != null && subcategory!.isNotEmpty) 'subcategory': subcategory,
      'value': value,
      'isPinned': isPinned,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'actorProfileUrl': actorProfileUrl,
      'actorRole': actorRole,
    };
  }
}