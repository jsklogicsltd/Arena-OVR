import os

base_dir = '/Users/apple/Flutter_Apps/arena_ovr/lib'

files = {
    'app/core/constants/app_colors.dart': """import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0E1A);
  static const Color backgroundEnd = Color(0xFF141B2D);
  static const Color primary = Color(0xFF00A3FF);
  static const Color accent = Color(0xFFFFB800);
  static const Color positive = Color(0xFF00FF88);
  static const Color negative = Color(0xFFFF3B5C);
  static const Color cardSurface = Color(0x0FFFFFFF);
  static const Color cardBorder = Color(0x19FFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8899AA);

  static const Color tierBronze = Color(0xFFCD7F32);
  static const Color tierSilver = Color(0xFFC0C0C0);
  static const Color tierGold = Color(0xFFFFB800);
  static const Color tierPurple = Color(0xFF9B30FF);
  static const Color tierDiamond = Color(0xFF00FFFF);

  static Color getTierColor(int? ovr) {
    if (ovr == null) return textSecondary;
    if (ovr < 30) return tierBronze;
    if (ovr < 60) return tierSilver;
    if (ovr < 80) return tierGold;
    if (ovr < 95) return tierPurple;
    return tierDiamond;
  }
}
""",

    'app/core/theme/theme_controller.dart': """import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

class ThemeController extends GetxController {
  final Rx<Color> _teamPrimaryColor = AppColors.primary.obs;
  final Rx<Color> _teamSecondaryColor = AppColors.accent.obs;

  Color get primaryColor => _teamPrimaryColor.value;
  Color get secondaryColor => _teamSecondaryColor.value;

  LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryColor, primaryColor.withOpacity(0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Color get accentGlow => secondaryColor.withOpacity(0.5);
  
  Color get activeTabGlow => primaryColor.withOpacity(0.6);
  Color get cardBorderGlow => primaryColor.withOpacity(0.3);

  void setTeamColors(Color primary, Color secondary) {
    _teamPrimaryColor.value = primary;
    _teamSecondaryColor.value = secondary;
  }

  void resetToDefault() {
    _teamPrimaryColor.value = AppColors.primary;
    _teamSecondaryColor.value = AppColors.accent;
  }
}
""",

    'app/core/theme/app_theme.dart': """import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
        displayMedium: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
        displaySmall: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
        headlineSmall: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.cardSurface,
      ),
    );
  }
}
""",

    'app/core/widgets/stadium_background.dart': """import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StadiumBackground extends StatelessWidget {
  final Widget child;
  const StadiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, AppColors.backgroundEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.blue.withOpacity(0.05),
                    Colors.transparent
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.blue.withOpacity(0.05),
                    Colors.transparent
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.background.withOpacity(0.0),
                    AppColors.background.withOpacity(0.8),
                    AppColors.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
""",

    'app/core/widgets/glass_card.dart': """import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../theme/theme_controller.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool withGlow;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.withGlow = false,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeController = Get.find<ThemeController>();
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.cardBorder, width: 1),
            boxShadow: withGlow
                ? [
                    BoxShadow(
                      color: themeController.cardBorderGlow,
                      blurRadius: 10,
                      spreadRadius: -2,
                    )
                  ]
                : null,
          ),
          child: child,
        ),
      );
    });
  }
}
""",

    'app/core/widgets/arena_button.dart': """import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';
import '../constants/app_colors.dart';

class ArenaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const ArenaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeController = Get.find<ThemeController>();
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: themeController.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: themeController.primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onPressed: isLoading ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.textPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        label.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
""",

    'app/core/widgets/ovr_text.dart': """import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class OvrText extends StatefulWidget {
  final int? ovr;
  final double fontSize;

  const OvrText({super.key, required this.ovr, this.fontSize = 48});

  @override
  State<OvrText> createState() => _OvrTextState();
}

class _OvrTextState extends State<OvrText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ovr == null) {
      return FadeTransition(
        opacity: _animation,
        child: Text(
          '???',
          style: GoogleFonts.bebasNeue(
            fontSize: widget.fontSize,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Text(
      widget.ovr.toString(),
      style: GoogleFonts.bebasNeue(
        fontSize: widget.fontSize,
        color: AppColors.getTierColor(widget.ovr),
      ),
    );
  }
}
""",

    'app/core/widgets/tier_border.dart': """import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TierBorder extends StatelessWidget {
  final int? ovr;
  final Widget child;
  final bool withGlow;
  final double borderRadius;
  final double borderWidth;

  const TierBorder({
    super.key,
    required this.ovr,
    required this.child,
    this.withGlow = false,
    this.borderRadius = 50.0,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getTierColor(ovr);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color, width: borderWidth),
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: -2,
                )
              ]
            : null,
      ),
      child: child,
    );
  }
}
""",

    'app/core/widgets/shimmer_loading.dart': """import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardSurface,
      highlightColor: AppColors.cardBorder,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
""",

    'app/core/widgets/bottom_nav_bar.dart': """import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';
import '../constants/app_colors.dart';

class ArenaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ArenaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeController = Get.find<ThemeController>();
      return Container(
        padding: const EdgeInsets.only(bottom: 24, top: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundEnd,
          border: const Border(top: BorderSide(color: AppColors.cardBorder)),
          boxShadow: [
            BoxShadow(
              color: AppColors.backgroundEnd.withOpacity(0.8),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTab(Icons.home_outlined, 0, themeController),
            _buildTab(Icons.bar_chart_outlined, 1, themeController),
            _buildCenterTab(Icons.play_arrow_outlined, 2, themeController),
            _buildTab(Icons.military_tech_outlined, 3, themeController),
            _buildTab(Icons.person_outline, 4, themeController),
          ],
        ),
      );
    });
  }

  Widget _buildTab(IconData icon, int index, ThemeController themeController) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isActive
            ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeController.activeTabGlow,
                    blurRadius: 15,
                    spreadRadius: -5,
                  )
                ],
              )
            : null,
        child: Icon(
          icon,
          color: isActive ? themeController.primaryColor : AppColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCenterTab(IconData icon, int index, ThemeController themeController) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: themeController.primaryGradient,
          border: Border.all(
            color: themeController.secondaryColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: themeController.secondaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 32,
        ),
      ),
    );
  }
}
""",

    'app/core/widgets/glass_text_field.dart': """import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';
import '../constants/app_colors.dart';

class GlassTextField extends StatefulWidget {
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;

  const GlassTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  bool _obscureText = true;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeController = Get.find<ThemeController>();
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFocused ? themeController.primaryColor : AppColors.cardBorder,
            width: 1,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: themeController.primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: _obscureText,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: Icon(
              widget.prefixIcon,
              color: _isFocused ? themeController.primaryColor : AppColors.textSecondary,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    });
  }
}
""",

    'app/modules/splash/splash_view.dart': """import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/stadium_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/arena_button.dart';
import '../../core/widgets/ovr_text.dart';
import '../../core/widgets/tier_border.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/bottom_nav_bar.dart';
import '../../core/widgets/glass_text_field.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return StadiumBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const OvrText(ovr: null),
              const SizedBox(height: 16),
              const OvrText(ovr: 96),
              const SizedBox(height: 24),
              TierBorder(
                ovr: 96,
                withGlow: true,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.person, size: 64, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                withGlow: true,
                child: Column(
                  children: [
                    const Text('Testing Glass Card', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    const GlassTextField(
                      hintText: 'Enter Email',
                      prefixIcon: Icons.email,
                    ),
                    const SizedBox(height: 16),
                    const ShimmerLoading(width: double.infinity, height: 20),
                    const SizedBox(height: 16),
                    ArenaButton(
                      label: 'Click Me',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ArenaBottomNavBar(
                currentIndex: 2,
                onTap: (index) {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
""",

    'app/modules/splash/splash_controller.dart': """import 'package:get/get.dart';
class SplashController extends GetxController {}
""",
}

for path, content in files.items():
    with open(os.path.join(base_dir, path), 'w') as f:
        f.write(content)
