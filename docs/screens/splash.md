# Splash Screen

**File:** `lib/app/modules/splash/splash_view.dart`
**Controller:** `lib/app/modules/splash/splash_controller.dart`
**Route:** `/splash`

---

## Overview

The Splash screen is the **app entry point**. It checks Firebase Auth state and Firestore role,
then routes directly to the correct dashboard without showing any UI interaction required.

---

## Flow

```
App launches → SplashView shown (animated logo / branding)
    ↓
SplashController.onInit() called
    ↓
Checks FirebaseAuth.instance.currentUser
    ↓
If NO user → Get.offAllNamed(Routes.AUTH)     (Login screen)
    ↓
If user exists → reads users/{uid}.role from Firestore
    ↓
role == 'superadmin' → Get.offAllNamed(Routes.ADMIN)
role == 'coach'      → Get.offAllNamed(Routes.COACH)
role == 'athlete'    → Get.offAllNamed(Routes.PLAYER)
role unknown/null    → Get.offAllNamed(Routes.AUTH)
```

---

## UI

- Stadium background with dimmed overlay
- Arena OVR 99 logo with fade-in animation
- Loading indicator (minimal, brief)

---

## Notes

- This screen should complete within 2–3 seconds
- No user input required — fully automatic routing
- The Splash screen is always the initial route (defined as first entry in `AppPages.pages`)
