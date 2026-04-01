# Settings Screen

**File:** `lib/app/modules/settings/settings_view.dart`
**Controller:** `lib/app/modules/settings/settings_controller.dart`
**Route:** `/settings`

---

## Overview

The Settings screen provides **general app settings** accessible to both coaches and athletes.
It handles account preferences, notification toggles, and logout.

---

## UI Layout

- Stadium background
- Screen header: **SETTINGS**
- Sections:
  - **Account** — Edit name, profile picture, change password
  - **Notifications** — Toggle push notifications on/off
  - **Privacy** — Data/privacy preferences
  - **About** — App version, terms, privacy policy links
  - **Logout** button (red, prominent)

---

## Logout Flow

```
Logout button pressed
    ↓
Confirmation dialog shown
    ↓
User confirms
    ↓
SettingsController.logout():
  - If coach: Get.delete<CoachController>(force: true)   ← cleans permanent controller
  - FirebaseAuth.instance.signOut()
  - Get.offAllNamed(Routes.AUTH)
```

> ⚠️ **Important:** `CoachController` is permanent — it MUST be manually deleted via
> `Get.delete<CoachController>(force: true)` on logout, otherwise the next login session
> will reuse stale coach state.

---

## Notes

- This screen is separate from `CoachSettingsView` (which is Tab 4 of the coach shell)
- `CoachSettingsView` (`/coach-settings`) is a role-specific view with team/season info
- `SettingsView` (`/settings`) is the generic settings screen linked from the player dashboard
- Profile picture change: uses `image_picker` → uploads to Firebase Storage → updates `profilePicUrl` in Firestore
