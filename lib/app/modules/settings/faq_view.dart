import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/stadium_background.dart';

class FaqView extends StatelessWidget {
  const FaqView({super.key});
  static final Uri _supportUri = Uri.parse(
    'https://www.coachrandyjackson.com/contact-us',
  );

  static const List<Map<String, String>> _athleteFaqs = [
    {
      'q': 'Why did my OVR change?',
      'a':
          'Your OVR updates when coaches add points for performance and behavior-good or bad.',
    },
    {
      'q': 'How do I raise my OVR?',
      'a':
          'Earn points daily through effort, performance, being a great teammate, and doing things right off the field.',
    },
    {
      'q': 'What are coaches actually scoring me on?',
      'a':
          'Four areas: Athlete, Student, Teammate, Citizen-it\'s not just how you play.',
    },
    {
      'q': 'How fast does my OVR update?',
      'a':
          'Instantly-once a coach enters points, your OVR reflects it right away.',
    },
    {
      'q': 'Why is someone ranked above me?',
      'a':
          'They\'ve earned more total points across performance and behavior-check the leaderboard and breakdown.',
    },
    {
      'q': 'Can I see how I earned my points?',
      'a':
          'Yes-your profile shows what you\'ve been awarded and where you\'re gaining or losing.',
    },
    {
      'q': 'Is this just for sports performance?',
      'a':
          'No, OVR measures the total athletic performance, including school, attitude, and how you treat others.',
    },
    {
      'q': 'Do all coaches score the same way?',
      'a':
          'Coaches follow the same system, and each position coach handles their group to keep it consistent.',
    },
    {
      'q': 'What happens if I don\'t like my score?',
      'a':
          'OVR reflects what\'s been earned-focus on stacking positive actions daily to move up.',
    },
    {
      'q': 'How often are we scored?',
      'a': 'Regularly-after practices, workouts, games, and school updates.',
    },
  ];

  static const List<Map<String, String>> _coachFaqs = [
    {
      'q':
          'How do I make this part of our routine without it feeling like \'one more thing\'?',
      'a':
          'Tie it to what you already do-post-practice. It becomes a 3-5 minute habit, not a new system.',
    },
    {
      'q': 'What happens after the first few weeks-does this keep its value?',
      'a':
          'Yes-because rankings, movement, and competition keep updating. It stays fresh if you stay consistent.',
    },
    {
      'q': 'Do I lose control of my program if everything is visible?',
      'a':
          'No-you gain clarity. You still control what\'s rewarded-OVR just makes it visible.',
    },
    {
      'q': 'How is OVR calculated?',
      'a':
          'It combines objective results with subjective scoring across Athlete, Student, Teammate, and Citizen.',
    },
    {
      'q': 'How do I keep scoring consistent across my staff?',
      'a':
          'Set clear standards-OVR gives the structure, your staff applies it.',
    },
    {
      'q': 'Can I score multiple players at once?',
      'a':
          'Yes-you can assign points to an entire position group in one action.',
    },
    {
      'q': 'Do I have to post results anywhere?',
      'a':
          'No-the app is the board. Players see their OVR and rankings instantly.',
    },
    {
      'q': 'What if I miss a day?',
      'a':
          'No problem-just pick back up. The system is flexible and keeps rolling.',
    },
    {
      'q': 'Can I see how a player earned their score?',
      'a':
          'Yes-each player has a breakdown so you and they can see where points came from.',
    },
    {
      'q': 'Will my staff actually use this?',
      'a':
          'If it takes time, they won\'t. That\'s why it\'s built to be fast, simple, and shared.',
    },
    {
      'q': 'What happens to an athlete\'s score when a new season begins?',
      'a':
          'Behavior resets-performance stays. Subjective scores go back to zero so every player gets a fresh start. Objective numbers stay until you update them with new testing.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: StadiumBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'FAQ',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF00A3FF).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tabs: const [
                    Tab(text: 'For Athletes'),
                    Tab(text: 'For Coaches'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  children: [
                    _FaqList(items: _athleteFaqs),
                    _FaqList(items: _coachFaqs),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final launchedInApp = await launchUrl(
                        _supportUri,
                        mode: LaunchMode.inAppBrowserView,
                      );
                      if (launchedInApp) return;

                      final launchedExternal = await launchUrl(
                        _supportUri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!launchedExternal) {
                        Get.snackbar(
                          'Support',
                          'Unable to open support link right now.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                    child: const Text('Contact Support'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqList extends StatelessWidget {
  final List<Map<String, String>> items;

  const _FaqList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            iconColor: const Color(0xFF00A3FF),
            collapsedIconColor: Colors.white70,
            title: Text(
              item['q'] ?? '',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item['a'] ?? '',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
