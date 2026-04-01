/// Client challenge (subcategory) labels grouped under parent OVR categories.
class ChallengeCatalog {
  ChallengeCatalog._();

  static const List<String> parentCategories = [
    'Performance',
    'Classroom',
    'Program',
    'Standard',
  ];

  static const List<String> performance = [
    'Strength Improvement',
    'Speed / Agility Improvement',
    'Competition Winner',
    'Strong Practice Performance',
    'Testing Improvement',
  ];

  static const List<String> standard = [
    'Elite Effort',
    'Positive Attitude',
    'Coachability',
    'Team-First Behavior',
    'Bounced Back From Mistake',
  ];

  static const List<String> program = [
    'Voluntary Workout',
    'Team Support',
    'Community Service',
    'Program Representation',
    'Encouraged Teammates',
    'Extra Work for Team',
  ];

  static const List<String> classroom = [
    'Assignment Completed',
    'Teacher Recognition',
    'Classroom Conduct',
    'Academic Improvement',
    'GPA 3.5+',
    'GPA 3.0+',
    'Zero – Missing Assignment',
  ];

  static List<String> challengesFor(String parentCategory) {
    switch (parentCategory) {
      case 'Performance':
        return performance;
      case 'Standard':
        return standard;
      case 'Program':
        return program;
      case 'Classroom':
        return classroom;
      default:
        return const [];
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
