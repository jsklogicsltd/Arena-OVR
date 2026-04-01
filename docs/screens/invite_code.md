# Invite Code Screen

**File:** `lib/app/modules/invite_code/invite_code_view.dart`
**Controller:** `lib/app/modules/invite_code/invite_code_controller.dart`
**Route:** `/invite-code`

---

## Overview

After signup, every user must submit an **invite code** to be linked to their school or team.
The screen text adapts based on the user's role.

---

## Role-Based Behaviour

| Role | Code Type | Provided By | Links To |
|---|---|---|---|
| **Coach** | School Invite Code | Super Admin | Links `users/{uid}.schoolId` |
| **Athlete** | Team Code | Coach | Links `users/{uid}.teamId` |

---

## UI Elements

- Stadium background
- Title: **"Enter Your Access Code"**
- Subtitle text changes based on role:
  - Coach: *"Your Super Admin has provided you with a unique access code."*
  - Athlete: *"Your Coach has provided you with a unique team code."*
- Code input field (uppercase, numeric or alphanumeric)
- **Submit** button
- Small note: "Contact your coach / super admin if you don't have a code"

---

## Invite Code Flow

```
User enters code → Submit pressed
    ↓
InviteCodeController validates code
    ↓
Coach: checks schools collection for matching schoolInviteCode
       → on match: sets users/{uid}.schoolId = school.id
       → navigates to /coach

Athlete: checks teams collection for matching teamCode
       → on match: sets users/{uid}.teamId = team.id
       → navigates to /player
    ↓
On invalid code: shows error message inline
```

---

## Notes

- Once successfully linked, the user goes directly to their dashboard
- The invite code is stored on the `SchoolModel` (for coach) or `TeamModel.teamCode` (for athlete)
- Coaches do NOT see this screen again after first login
