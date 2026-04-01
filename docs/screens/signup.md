# Signup Screen

**File:** `lib/app/modules/signup/signup_view.dart`
**Controller:** `lib/app/modules/signup/signup_controller.dart`
**Route:** `/signup`

---

## Overview

The Signup screen allows a new user to **register as either a Coach or an Athlete**.
Super Admin accounts are NOT created via this screen — they are provisioned out-of-band.

---

## UI Elements

- Stadium background
- Name field
- Email field
- Password field
- Confirm Password field
- **Role selector** — toggle between Coach / Athlete
- Sign Up button
- Link back to Login (`/auth`)

---

## Signup Flow

```
User fills form + selects role (Coach or Athlete)
    ↓
SignupController.signup() called
    ↓
FirebaseAuth.instance.createUserWithEmailAndPassword()
    ↓
Creates Firestore users/{uid} document with:
  - name, email, role
  - teamIds: [] (empty for coach)
  - teamId: null (for athlete)
  - badges: []
  - ovr: 0
  - hasUploadedPic: false
    ↓
Navigates to → /invite-code
```

---

## Notes

- The `role` field set here drives all future routing decisions
- After signup, the user MUST enter an invite code (`/invite-code`) to be linked to a school/team
- Coaches enter a **school invite code** (provided by Super Admin)
- Athletes enter a **team code** (provided by their Coach)
