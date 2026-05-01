import "package:get/get.dart";
import "app_routes.dart";
import "../modules/splash/splash_view.dart";
import "../modules/splash/splash_controller.dart";
import "../modules/auth/auth_view.dart";
import "../modules/auth/auth_controller.dart";
import "../modules/signup/signup_view.dart";
import "../modules/signup/signup_controller.dart";
import "../modules/forgot_password/forgot_password_view.dart";
import "../modules/forgot_password/forgot_password_controller.dart";
import "../modules/invite_code/invite_code_view.dart";
import "../modules/invite_code/invite_code_controller.dart";
import "../modules/admin/admin_dashboard_view.dart";
import "../modules/admin/create_school_view.dart";
import "../modules/admin/school_details_view.dart";
import "../modules/admin/admin_settings_view.dart";
import "../modules/admin/admin_controller.dart";
import "../modules/coach/coach_view.dart";
import "../modules/coach/coach_controller.dart";
import "../modules/player/player_view.dart";
import "../modules/player/player_controller.dart";
import "../modules/player/views/athlete_profile_view.dart";
import "../modules/leaderboard/leaderboard_view.dart";
import "../modules/leaderboard/leaderboard_controller.dart";
import "../modules/feed/feed_view.dart";
import "../modules/feed/feed_controller.dart";
import "../modules/notifications/notifications_view.dart";
import "../modules/notifications/notifications_controller.dart";
import "../modules/badges/badges_view.dart";
import "../modules/badges/badges_controller.dart";
import "../modules/settings/settings_view.dart";
import "../modules/settings/settings_controller.dart";
import "../modules/settings/faq_view.dart";
import "../modules/coach/views/create_team_view.dart";
import "../modules/coach/views/team_settings_view.dart";
import "../modules/coach/views/season_view.dart";
import "../modules/coach/views/coach_settings_view.dart";

class AppPages {
  static final pages = [
    GetPage(name: Routes.SPLASH, page: () => const SplashView(), binding: BindingsBuilder(() { Get.lazyPut<SplashController>(() => SplashController()); })),
    GetPage(name: Routes.AUTH, page: () => const AuthView(), binding: BindingsBuilder(() { Get.lazyPut<AuthController>(() => AuthController()); })),
    GetPage(name: Routes.SIGNUP, page: () => const SignupView(), binding: BindingsBuilder(() { Get.lazyPut<SignupController>(() => SignupController()); })),
    GetPage(name: Routes.FORGOT_PASSWORD, page: () => const ForgotPasswordView(), binding: BindingsBuilder(() { Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController()); })),
    GetPage(name: Routes.INVITE_CODE, page: () => const InviteCodeView(), binding: BindingsBuilder(() { Get.lazyPut<InviteCodeController>(() => InviteCodeController()); })),
    GetPage(name: Routes.ADMIN, page: () => const AdminDashboardView(), binding: BindingsBuilder(() { Get.lazyPut<AdminController>(() => AdminController()); })),
    GetPage(name: Routes.CREATE_SCHOOL, page: () => const CreateSchoolView(), binding: BindingsBuilder(() { Get.lazyPut<AdminController>(() => AdminController()); })),
    GetPage(name: Routes.SCHOOL_DETAILS, page: () => const SchoolDetailsView()),
    GetPage(name: Routes.ADMIN_SETTINGS, page: () => const AdminSettingsView(), binding: BindingsBuilder(() { Get.lazyPut<AdminController>(() => AdminController()); })),
    GetPage(name: Routes.COACH, page: () => const CoachView(), binding: BindingsBuilder(() {
      Get.put<CoachController>(CoachController(), permanent: true);
      Get.lazyPut<FeedController>(() => FeedController());
    })),
    GetPage(name: Routes.PLAYER, page: () => const PlayerView(), binding: BindingsBuilder(() {
      Get.put<PlayerController>(PlayerController(), permanent: true);
      Get.lazyPut<FeedController>(() => FeedController());
      Get.lazyPut<NotificationsController>(() => NotificationsController());
    })),
    GetPage(name: Routes.ATHLETE_PROFILE, page: () => const AthleteProfileView(isOwnProfile: false)),
    GetPage(name: Routes.LEADERBOARD, page: () => const LeaderboardView(), binding: BindingsBuilder(() { Get.lazyPut<LeaderboardController>(() => LeaderboardController()); })),
    GetPage(name: Routes.FEED, page: () => const FeedView(), binding: BindingsBuilder(() { Get.lazyPut<FeedController>(() => FeedController()); })),
    GetPage(name: Routes.NOTIFICATIONS, page: () => const NotificationsView(), binding: BindingsBuilder(() { Get.lazyPut<NotificationsController>(() => NotificationsController()); })),
    GetPage(name: Routes.BADGES, page: () => const BadgesView(), binding: BindingsBuilder(() { Get.lazyPut<BadgesController>(() => BadgesController()); })),
    GetPage(name: Routes.SETTINGS, page: () => const SettingsView(), binding: BindingsBuilder(() { Get.lazyPut<SettingsController>(() => SettingsController()); })),
    GetPage(name: Routes.FAQ, page: () => const FaqView()),
    GetPage(
      name: Routes.CREATE_TEAM,
      page: () => const CreateTeamView(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<CoachController>()) {
          Get.put<CoachController>(CoachController(), permanent: true);
        }
      }),
    ),
    GetPage(name: Routes.TEAM_SETTINGS, page: () => const TeamSettingsView()),
    GetPage(name: Routes.SEASON_HQ, page: () => const SeasonView()),
    GetPage(name: Routes.COACH_SETTINGS, page: () => const CoachSettingsView()),
  ];
}