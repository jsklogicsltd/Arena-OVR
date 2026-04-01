# Arena OVR 99 - Application Architecture Overview

> 📖 **Full App Context:** For the most comprehensive overview (roles, routes, all data models,
> navigation flows, design system, known bugs), see **[app_overview.md](app_overview.md)**.
> That file is purpose-built for Cursor/AI context.

This is the primary Architecture markdown file for the **Arena OVR 99** Flutter application.

## 🎯 High-Level Overview
Arena OVR 99 is a sports and training platform designed with a high-end, dynamic UI reflecting a premium "gaming" aesthetic. 
The application makes heavy use of **Glassmorphism**, smooth chained entrance animations, and rich gradients.

## 🛠️ Tech Stack & Dependencies
- **UI Framework:** Flutter / Dart
- **Design Paradigm:** Material 3 customized with Glassmorphism (blur filters with white tint)
- **State Management:** GetX (Controllers, Bindings, Obx, Route Management)
- **Database / Backend:** Firebase (Authentication, Firestore Database, Storage)
- **Animations:** `flutter_animate` (for entry states and view transitions)
- **Typography:** Google Fonts (`Space Grotesk`, `Bebas Neue`, `Inter`)
- **Assets:** Raster images alongside Vector Graphics (`flutter_svg`)
- **Input Forms:** `pin_code_fields` (for 6-character OTP style team joins)

## 🏗️ Folder Structure (MVC approach via GetX)
```text
lib/
├── app/
│   ├── core/
│   │   ├── constants/    (Colors, Asset paths)
│   │   ├── theme/        (App-wide styling rules)
│   │   └── widgets/      (Reusable global UI: GlassCard, ArenaButton, etc.)
│   ├── data/
│   │   ├── models/       (Object blueprints)
│   │   ├── providers/    (Firebase/API initialization logic)
│   │   └── repositories/ (Data abstraction layer)
│   ├── modules/          (Screen-specific Controllers and Views)
│   │   ├── admin/
│   │   ├── auth/
│   │   ├── forgot_password/
│   │   ├── invite_code/
│   │   ├── signup/
│   │   ├── splash/
│   │   └── ...
│   └── routes/           (AppPages array & Named Routes constants)
├── main.dart             (Entrypoint)
```

## 📱 Screen & Module Documentation
Comprehensive details on the specific UI and functional constraints of each module are maintained separately in the `docs/screens/` directory:
- [Admin Flows](screens/admin_super.md)
- [Authentication](screens/auth.md)
- [Coach Flow](screens/coach.md)
- [Player Flow](screens/player.md)
- [Signup](screens/signup.md)
- [Splash](screens/splash.md)
- [Invite Code](screens/invite_code.md)
- [Forgot Password](screens/forgot_password.md)
- [Settings](screens/settings.md)
- [Leaderboard](screens/leaderboard.md)
- [Feed](screens/feed.md)
- [Badges](screens/badges.md)
- [Notifications](screens/notifications.md)

## 🔒 Authentication & Roles
Arena uses a conditional role-based system powered by Firebase.
During registration, the DB is queried. If a Global Superadmin exists, the `ADMIN` login route is hidden.
Available roles:
- `superadmin`
- `coach` (Requires a `schoolId` during onboarding payload via InviteCode route)
- `athlete` / `player` (Requires a `teamId` and `schoolId` payload via InviteCode route)

## 🎬 Universal Design Language
- **Colors:** Deep Blues/Blacks (`#020815`), Vivid Cyan (`#00A1FF`), Gold (`#FFB800`)
- **Gradients:** Action buttons use an icy gradient. Loading bars use `Cyan -> Teal -> Gold`.
- **Animations:** Long duration (1200ms+), heavily relying on soft `easeOutQuint` and `elasticOut` curves.
- **Components:** Elements do not sit on solid colored boxes. They sit in rounded frosted glass (`GlassCard`), featuring a 70% dark opacity overlay blending into stadium background images.

## 🏛️ Admin Module Logic
The core platform architecture branches out into `AdminController` resolving from the SuperAdmin role login.
- **Data Binding:** `admin_controller.dart` maintains an open stream to `SchoolRepository.getSchoolsStream()`. This updates the dashboard counters locally with reactive `Rx` extensions dynamically.
- **Code Gen:** Uses a local standard `dart:math` alphanumeric generator within `code_generator.dart` ensuring new School additions quickly procure uniquely identifiable 6-digit hashes.
- **Views**: The admin space splits to three primary views utilizing `GetView<AdminController>` mappings alongside stateless architecture (`AdminDashboardView`, `CreateSchoolView`, and `AdminSettingsView`).
