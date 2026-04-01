# Forgot Password Screen

**File:** `lib/app/modules/forgot_password/forgot_password_view.dart`
**Controller:** `lib/app/modules/forgot_password/forgot_password_controller.dart`
**Route:** `/forgot-password`

---

## Overview

A simple utility screen that allows users to **reset their password via email**.

---

## UI Layout

- Stadium background
- Screen header: **FORGOT PASSWORD**
- Brief instructions: *"Enter your email address and we'll send you a link to reset your password."*
- **Email** text field
- **Send Reset Link** button
- Back link to Login (`/auth`)

---

## Flow

```
User enters email address → taps Send Reset Link
    ↓
ForgotPasswordController.sendPasswordReset(email) called
    ↓
FirebaseAuth.instance.sendPasswordResetEmail(email: email)
    ↓
On success:
  - Shows success message: "Reset link sent! Check your inbox."
  - User navigates back to /auth

On failure:
  - Shows error: e.g., "No account found with that email."
```

---

## Notes

- Reset email is sent by Firebase — contains a link to the Firebase password reset page
- No sensitive data is stored or processed locally
- After resetting, user returns to the Login screen and signs in with the new password
