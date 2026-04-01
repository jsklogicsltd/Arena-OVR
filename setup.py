import os

base_dir = '/Users/apple/Flutter_Apps/arena_ovr/lib'

dirs = [
    'app/core/constants',
    'app/core/theme',
    'app/core/utils',
    'app/core/widgets',
    'app/data/models',
    'app/data/providers',
    'app/data/repositories',
    'app/routes',
]

modules = [
    'splash', 'auth', 'invite_code', 'admin', 'coach', 'player',
    'leaderboard', 'feed', 'notifications', 'badges', 'settings'
]
for m in modules:
    dirs.append(f'app/modules/{m}')

for d in dirs:
    os.makedirs(os.path.join(base_dir, d), exist_ok=True)

files = {
    'app/core/constants/app_colors.dart': 'class AppColors {}',
    'app/core/constants/app_strings.dart': 'class AppStrings {}',
    'app/core/constants/app_assets.dart': 'class AppAssets {}',
    'app/core/theme/app_theme.dart': 'import "package:flutter/material.dart";\\n\\nclass AppTheme {\\n  static ThemeData get darkTheme => ThemeData.dark();\\n}',
    'app/core/utils/validators.dart': 'class Validators {}',
    'app/core/utils/helpers.dart': 'class Helpers {}',
    'app/core/widgets/stadium_background.dart': 'import "package:flutter/material.dart";\\nclass StadiumBackground extends StatelessWidget {\\n  const StadiumBackground({super.key});\\n  @override\\n  Widget build(BuildContext context) => const SizedBox();\\n}',
    'app/core/widgets/glass_card.dart': 'import "package:flutter/material.dart";\\nclass GlassCard extends StatelessWidget {\\n  const GlassCard({super.key});\\n  @override\\n  Widget build(BuildContext context) => const SizedBox();\\n}',
    'app/core/widgets/arena_button.dart': 'import "package:flutter/material.dart";\\nclass ArenaButton extends StatelessWidget {\\n  const ArenaButton({super.key});\\n  @override\\n  Widget build(BuildContext context) => const SizedBox();\\n}',
    'app/core/widgets/ovr_text.dart': 'import "package:flutter/material.dart";\\nclass OvrText extends StatelessWidget {\\n  const OvrText({super.key});\\n  @override\\n  Widget build(BuildContext context) => const SizedBox();\\n}',
    'app/core/widgets/tier_border.dart': 'import "package:flutter/material.dart";\\nclass TierBorder extends StatelessWidget {\\n  const TierBorder({super.key});\\n  @override\\n  Widget build(BuildContext context) => const SizedBox();\\n}',
    'app/core/widgets/shimmer_loading.dart': 'import "package:flutter/material.dart";\\nclass ShimmerLoading extends StatelessWidget {\\n  const ShimmerLoading({super.key});\\n  @override\\n  Widget build(BuildContext context) => const SizedBox();\\n}',
    'app/core/widgets/bottom_nav_bar.dart': 'import "package:flutter/material.dart";\\nclass BottomNavBar extends StatelessWidget {\\n  const BottomNavBar({super.key});\\n  @override\\n  Widget build(BuildContext context) => const SizedBox();\\n}',
    'app/core/widgets/glass_text_field.dart': 'import "package:flutter/material.dart";\\nclass GlassTextField extends StatelessWidget {\\n  const GlassTextField({super.key});\\n  @override\\n  Widget build(BuildContext context) => const SizedBox();\\n}',
    'app/data/models/user_model.dart': 'class UserModel {}',
    'app/data/models/school_model.dart': 'class SchoolModel {}',
    'app/data/models/team_model.dart': 'class TeamModel {}',
    'app/data/models/transaction_model.dart': 'class TransactionModel {}',
    'app/data/models/feed_model.dart': 'class FeedModel {}',
    'app/data/models/notification_model.dart': 'class NotificationModel {}',
    'app/data/models/season_model.dart': 'class SeasonModel {}',
    'app/data/providers/firebase_provider.dart': 'class FirebaseProvider {}',
    'app/data/repositories/auth_repository.dart': 'class AuthRepository {}',
    'app/data/repositories/school_repository.dart': 'class SchoolRepository {}',
    'app/data/repositories/team_repository.dart': 'class TeamRepository {}',
    'app/data/repositories/rating_repository.dart': 'class RatingRepository {}',
    'app/data/repositories/feed_repository.dart': 'class FeedRepository {}',
    'app/data/repositories/notification_repository.dart': 'class NotificationRepository {}',
    'app/routes/app_routes.dart': 'abstract class Routes {\\n' + '  static const SPLASH = "/splash";\\n  static const AUTH = "/auth";\\n  static const INVITE_CODE = "/invite-code";\\n  static const ADMIN = "/admin";\\n  static const COACH = "/coach";\\n  static const PLAYER = "/player";\\n  static const LEADERBOARD = "/leaderboard";\\n  static const FEED = "/feed";\\n  static const NOTIFICATIONS = "/notifications";\\n  static const BADGES = "/badges";\\n  static const SETTINGS = "/settings";\\n}',
}

for m in modules:
    class_prefix = "".join([part.capitalize() for part in m.split("_")])
    cname = class_prefix + 'Controller'
    vname = class_prefix + 'View'
    files[f'app/modules/{m}/{m}_controller.dart'] = f'import "package:get/get.dart";\\nclass {cname} extends GetxController {{}}'
    files[f'app/modules/{m}/{m}_view.dart'] = f"""import "package:flutter/material.dart";
import "package:get/get.dart";
import "{m}_controller.dart";

class {vname} extends GetView<{cname}> {{
  const {vname}({{Key? key}}) : super(key: key);
  @override
  Widget build(BuildContext context) {{
    return const Scaffold(
      body: Center(child: Text("{vname}")),
    );
  }}
}}"""

for fpath, content in files.items():
    with open(os.path.join(base_dir, fpath), 'w') as f:
        f.write(content)

app_pages = """import "package:get/get.dart";
import "app_routes.dart";
"""
for m in modules:
    class_prefix = "".join([part.capitalize() for part in m.split("_")])
    app_pages += f'import "../modules/{m}/{m}_view.dart";\\n'
    app_pages += f'import "../modules/{m}/{m}_controller.dart";\\n'

app_pages += """
class AppPages {
  static final pages = [
"""
for m in modules:
    route_name = m.upper().replace("-", "_")
    class_prefix = "".join([part.capitalize() for part in m.split("_")])
    app_pages += f'    GetPage(name: Routes.{route_name}, page: () => const {class_prefix}View(), binding: BindingsBuilder(() {{ Get.lazyPut<{class_prefix}Controller>(() => {class_prefix}Controller()); }})),\\n'

app_pages += '  ];\\n}'

with open(os.path.join(base_dir, 'app/routes/app_pages.dart'), 'w') as f:
    f.write(app_pages)

main_dart = """import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // We are deliberately catching Firebase core without options to allow running 
    // a blank screen as requested without google-services.json
    // await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }
  runApp(
    GetMaterialApp(
      title: "Arena OVR",
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: Routes.SPLASH,
      getPages: AppPages.pages,
    ),
  );
}
"""
with open(os.path.join(base_dir, 'main.dart'), 'w') as f:
    f.write(main_dart)
