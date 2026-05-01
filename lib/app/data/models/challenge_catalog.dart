/// Client challenge (subcategory) labels grouped under parent OVR categories.
class ChallengeCatalog {
  ChallengeCatalog._();

  /// Firestore canonical key retained for backward compatibility.
  /// UI now displays this as "Competitor".
  static const String competitorKey = 'Athlete';

  static const List<String> parentCategories = [
    competitorKey,
    'Student',
    'Teammate',
    'Citizen',
  ];

  static const List<String> competitor = [
    'Overcomes Mistake Quickly (Next Play Mentality)',
    'Full-Speed Effort (No Loafs)',
    'Finishes Every Rep (No Quit)',
    'Positive Body Language Under Pressure',
    'Wins One-on-One Matchups',
    'Second sport - Always Competes',
    'Positive Response to Coaching',
    'Extra Work (Self-Driven)',
    'Executes Under Fatigue',
  ];

  static const List<String> citizen = [
    'High Trust',
    'Supports other school events',
    'Recognized publicly for character',
    'Helps a classmate or someone in need',
    'Represents program with class at all times',
    'Does the right thing when no one is watching',
    'Honest in situations (owns mistakes)',
    'Trusted by coaches and staff',
    'Promotes teammates/team online',
    'Participates in community service',
  ];

  static const List<String> teammate = [
    'Voluntary Workout',
    'Missed workout',
    'Team Support',
    'Community Service',
    'Program Representation',
    'Encouraged Teammates',
    'Extra Work for Team',
  ];

  static const List<String> student = [
    'Assignment Completed',
    'Teacher Recognition',
    'Classroom Conduct',
    'In school suspension',
    'Academic Improvement',
    'GPA 3.5+',
    'GPA 3.0+',
    'Zero – Missing Assignment',
  ];

  static List<String> challengesFor(String parentCategory) {
    switch (parentCategory) {
      case 'Athlete':
      case 'Competitor':
      case 'Performance':
        return competitor;
      case 'Citizen':
        return citizen;
      case 'Teammate':
        return teammate;
      case 'Student':
        return student;
      default:
        return const [];
    }
  }

  static String displayLabelForCategory(String key) {
    switch (key) {
      case 'Athlete':
      case 'Performance':
      case 'Competitor':
        return 'Competitor';
      default:
        return key;
    }
  }

  static String shortLabelForCategory(String key) {
    switch (key) {
      case 'Athlete':
      case 'Performance':
      case 'Competitor':
        return 'Comp';
      case 'Student':
        return 'Stu';
      case 'Teammate':
        return 'Tm';
      case 'Citizen':
        return 'Cit';
      default:
        return key;
    }
  }
}

/// One line item for bulk award (parent category + challenge + signed points).
class CategoryAwardInput {
  final String category;
  final String subcategory;
  final int value;

  const CategoryAwardInput({
    required this.category,
    required this.subcategory,
    required this.value,
  });
}
