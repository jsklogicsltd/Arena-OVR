# Authentication — Login Screen

**File:** `lib/app/modules/auth/auth_view.dart`
**Controller:** `lib/app/modules/auth/auth_controller.dart`
**Route:** `/auth`

---

## Overview

The Auth screen is the **login entry point** for all users (Coach, Athlete, Super Admin).
It uses Firebase Authentication (email + password).

---

## UI Elements

- Stadium background (`StadiumBackground` widget)
- Arena OVR logo / branding
- **Email** text field
- **Password** text field with toggle visibility
- **Login** button → calls `AuthController.login()`
- Link to **Sign Up** (`/signup`)
- Link to **Forgot Password** (`/forgot-password`)

---

## Login Flow

```
User enters email + password
    ↓
AuthController.login() called
    ↓
FirebaseAuth.instance.signInWithEmailAndPassword()
    ↓
On success: reads users/{uid}.role from Firestore
    ↓
role == 'superadmin' → Get.offAllNamed(Routes.ADMIN)
role == 'coach'      → Get.offAllNamed(Routes.COACH)
role == 'athlete'    → Get.offAllNamed(Routes.PLAYER)
    ↓
On failure: shows error snackbar / dialog
```

---

## Notes

- Full stack is cleared on successful login (`Get.offAllNamed`) — no back path to auth screen
- Error messages shown inline for: wrong password, user not found, network error
- No Google/Apple sign-in — email + password only
