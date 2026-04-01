# Super Admin Dashboard

**Files:** `lib/app/modules/admin/`
**Controller:** `lib/app/modules/admin/admin_controller.dart`
**Routes:** `/admin`, `/create-school`, `/school-details`, `/admin-settings`

---

## Overview

The Super Admin is the highest-privilege role. They manage the platform at the school level.
Super Admin accounts are NOT created via the public signup flow — they are provisioned manually.

---

## Screens

### Admin Dashboard (`/admin`)
**File:** `admin_dashboard_view.dart`

- Lists all schools created on the platform
- Quick stats: total schools, total coaches, total athletes
- Button: **Create School** → `/create-school`
- Tap any school → `/school-details`

### Create School (`/create-school`)
**File:** `create_school_view.dart`

- Creates a new `School` document in Firestore
- Fields: school name, location, mascot, colors
- **Generates a unique `schoolInviteCode`** (this is given to coaches)
- On success → back to `/admin`

### School Details (`/school-details`)
**File:** `school_details_view.dart`

- View all details for a specific school
- See all coaches registered under the school
- Copy or regenerate the `schoolInviteCode`
- Deactivate/delete school

### Admin Settings (`/admin-settings`)
**File:** `admin_settings_view.dart`

- Super Admin profile settings
- Platform-level configuration

---

## Firestore — School Structure

```
schools/{schoolId}
  - name: String
  - location: String
  - mascot: String?
  - primaryColor: String
  - secondaryColor: String
  - schoolInviteCode: String     ← shared with coaches at signup
  - createdAt: Timestamp
  - createdBy: String (super admin uid)
```

---

## Notes

- The `schoolInviteCode` is what a coach enters on the Invite Code screen after signup
- Only the Super Admin can create schools — coaches cannot
- The admin module shares `AdminController` across all admin routes
