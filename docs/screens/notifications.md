# Notifications Screen

**File:** `lib/app/modules/notifications/notifications_view.dart`
**Controller:** `lib/app/modules/notifications/notifications_controller.dart`
**Route:** `/notifications`

---

## Overview

The Notifications screen is the **in-app push notification inbox**. It shows a list of all
notifications received by the user, such as when a coach awards them points or announces something.

---

## UI Layout

- Stadium background
- Screen header: **NOTIFICATIONS**
- Notification list (reverse chronological)
- Each notification card:
  - Icon representing the notification type
  - Title (bold)
  - Body text
  - Timestamp (relative time, e.g. "2 minutes ago")
  - Unread indicator (dot or highlight)
- Empty state message if no notifications

---

## NotificationModel — `lib/app/data/models/notification_model.dart`
Stored in Firestore: `notifications/{docId}`

| Field | Description |
|---|---|
| `id` | Firestore doc ID |
| `userId` | Target user UID |
| `title` | Notification title |
| `body` | Notification body text |
| `type` | Notification type (e.g., `rating_award`, `badge`, `announcement`) |
| `isRead` | Whether user has read this notification |
| `createdAt` | Timestamp |

---

## Push Notifications

- Uses `firebase_messaging` + `flutter_local_notifications`
- FCM token stored in `users/{uid}.fcmToken`
- Token is refreshed at login and stored back to Firestore
- Background notifications are handled via Firebase Cloud Functions (server-side send)

---

## Notes

- `isRead` is updated when the notification is tapped or the screen is visited
- Notification badge count (unread count) may be shown on the bell icon in the player dashboard
