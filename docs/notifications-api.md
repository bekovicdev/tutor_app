# Notifications API

## Overview

Tutor-facing push notifications via Firebase Cloud Messaging (FCM HTTP v1).

| Type | When | Body (example) |
|------|------|----------------|
| `lesson_reminder` | ~60 minutes before a `scheduled` lesson | Yaklaşan ders — Ali 14:00 |
| `overdue_debt` | Daily 10:00 Europe/Istanbul | N öğrencinin 7+ gündür ödenmemiş toplam X TL borcu var |

Recipients: authenticated tutors (`users.fcm_token`) with `notifications_enabled=true`.

## App → API: token & preference

### Login

`POST /api/login` optional `fcm_token` — stored when notifications are enabled.

### Register

`POST /api/register` optional `fcm_token`.

### Update profile

`PUT /api/user`

| Field | Notes |
|-------|--------|
| `fcm_token` | Device token; send `null` to clear |
| `notifications_enabled` | boolean; when `false`, API also clears `fcm_token` |

`GET /api/me` returns `notifications_enabled`.

## Server config

`.env`:

```env
FIREBASE_CREDENTIALS=/absolute/path/to/firebase-service-account.json
FIREBASE_PROJECT_ID=  # optional; read from JSON if empty
```

Service account needs Firebase Cloud Messaging permission.

## Scheduler

In `routes/console.php`:

- `notifications:lesson-reminders` — every 5 minutes
- `notifications:overdue-debts` — daily at 10:00 `Europe/Istanbul`

Run in production:

```bash
* * * * * cd /path/to/tutor_api && php artisan schedule:run >> /dev/null 2>&1
```

Manual:

```bash
php artisan notifications:lesson-reminders
php artisan notifications:overdue-debts
```

## Deduplication

- Lesson reminders: `lessons.reminder_sent_at` set after a successful send.
- Overdue debts: `notification_logs` row (`type=overdue_debt`, `dedupe_key=YYYY-MM-DD`) once per tutor per day.

## FCM payload

```json
{
  "notification": { "title": "...", "body": "..." },
  "data": {
    "type": "lesson_reminder|overdue_debt",
    "lesson_id": "123"
  }
}
```

## Client notes

- Settings toggle syncs `notifications_enabled` + token via `PUT /api/user`.
- Foreground banners use `flutter_local_notifications` (channel `tutor_alerts`).
- Real devices need Firebase app config (`google-services.json` / `GoogleService-Info.plist`).
