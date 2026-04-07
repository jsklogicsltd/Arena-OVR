/// Client challenge (subcategory) labels grouped under parent OVR categories.
class ChallengeCatalog {
  ChallengeCatalog._();

  static const List<String> parentCategories = [
    'Athlete',
    'Student',
    'Teammate',
    'Citizen',
  ];

  static const List<String> athlete = [
    'Strength Improvement',
    'Speed / Agility Improvement',
    'Competition Winner',
    'Strong Practice Performance',
    'Testing Improvement',
  ];

  static const List<String> citizen = [
    'Elite Effort',
    'Positive Attitude',
    'Coachability',
    'Team-First Behavior',
    'Bounced Back From Mistake',
  ];

  static const List<String> teammate = [
    'Voluntary Workout',
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
    'Academic Improvement',
    'GPA 3.5+',
    'GPA 3.0+',
    'Zero – Missing Assignment',
  ];

  static List<String> challengesFor(String parentCategory) {
    switch (parentCategory) {
      case 'Athlete':
        return athlete;
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
