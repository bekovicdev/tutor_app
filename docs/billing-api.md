# Billing API

## Free plan quotas

| Resource | Limit |
|----------|--------|
| Active students (`status=1`) | 4 |
| Groups | 4 |
| Schedule lessons (`source` null/empty/`schedule`, not cancelled) | 24 |
| Journal lessons (`source=journal`, not cancelled) | 24 |

Premium (`is_premium=true` and `premium_end_at` null or in the future) has no quotas.

Moving a schedule lesson to journal (`source=journal`) counts against the journal quota.

## User fields

| Field | Type | Notes |
|-------|------|--------|
| `is_premium` | bool | Entitlement flag |
| `premium_start_at` | timestamp nullable | First/latest premium start |
| `premium_end_at` | timestamp nullable | Expiration; null = open-ended while active |

Returned on `GET /api/me` and billing status.

## Endpoints

### Status

`GET /api/billing/status` (Sanctum)

```json
{
  "success": true,
  "data": {
    "is_premium": false,
    "premium_start_at": null,
    "premium_end_at": null,
    "students_used": 2,
    "students_limit": 4,
    "schedule_lessons_used": 5,
    "schedule_lessons_limit": 24,
    "journal_lessons_used": 3,
    "journal_lessons_limit": 24
  }
}
```

### Sync (after App Store / RevenueCat purchase)

`POST /api/billing/sync` (Sanctum)

```json
{
  "is_premium": true,
  "premium_start_at": "2026-07-14T10:00:00Z",
  "premium_end_at": "2026-08-14T10:00:00Z"
}
```

### RevenueCat webhook

`POST /api/billing/revenuecat`

Authorization: `Bearer {REVENUECAT_WEBHOOK_SECRET}`

Maps `event.app_user_id` (tutor user id) to the user and sets `is_premium` / dates.

## Quota errors

Student/lesson create (and schedule→journal update) return **402**:

```json
{
  "success": false,
  "message": "Free plan allows up to 4 active students. Upgrade to Premium.",
  "code": "quota_students",
  "data": { "...billing status..." }
}
```

Codes: `quota_students`, `quota_groups`, `quota_schedule_lessons`, `quota_journal_lessons`.

Group create returns the same **402** shape with `"code": "quota_groups"`.

## App Store / RevenueCat setup

Products (same subscription group):

- `tutor_premium_weekly`
- `tutor_premium_monthly`
- `tutor_premium_yearly`

Entitlement id: `premium`

Flutter build defines:

```bash
--dart-define=REVENUECAT_IOS_API_KEY=appl_xxx
--dart-define=REVENUECAT_ANDROID_API_KEY=goog_xxx
```

API `.env`:

```env
REVENUECAT_WEBHOOK_SECRET=your-secret
```

After pulling migrations:

```bash
php artisan migrate
```
