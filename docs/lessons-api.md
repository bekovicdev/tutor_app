# Lessons API

## Overview

The Lessons API manages lessons for the authenticated tutor.  
All endpoints below require `Authorization: Bearer {token}`.

**Important:** A lesson must be either for a student (individual) OR a group, never both. This is validated at the application level.

### Source (`schedule` vs `journal`)

Lessons are scoped to a UI surface via `source`:

| Value | Meaning |
|-------|---------|
| `schedule` | Recurring/plan slots shown only on Schedule |
| `journal` | Regular lesson records shown only on Journal (default) |

Schedule and Journal stay independent: each page only lists and creates lessons for its own `source`.

---

## Endpoints

### List All Lessons

**Endpoint:** `GET /api/lessons`

**Query Parameters:**
- `status` (optional): scheduled, completed, cancelled
- `start_date` / `end_date` (optional): YYYY-MM-DD
- `type` (optional): individual or group
- `payment_status` (optional): `unpaid`, `paid`, or `prepaid`
- `is_paid_for` (optional): `true` / `false` (legacy; prefer `payment_status`)
- `source` (optional): `schedule` or `journal`
- `search` (optional): title and notes
- `sort_by` (optional): date, start_at, created_at, status (default date)
- `sort_direction` (optional): asc or desc (default desc)

**Example:** `GET /api/lessons?source=journal&payment_status=unpaid`

### Create Lesson

**Endpoint:** `POST /api/lessons`

Required: `date`, `start_at`, `duration_minutes`, and either `student_id` or `group_id`.

**Optional Fields:**
- `title`, `is_free`, `price`, `status`, `notes`
- `source` (`schedule` \| `journal`, default `journal`)
- `payment_status` (`unpaid` \| `paid` \| `prepaid`, default `unpaid`)
- `is_paid_for` (boolean, legacy — prefer `payment_status`)

See also [Payments API](./payments-api.md) for marking lessons paid/prepaid and analytics.

### Get Lesson

**Endpoint:** `GET /api/lessons/{id}`

### Update Lesson

**Endpoint:** `PUT /api/lessons/{id}` or `PATCH /api/lessons/{id}`

Optional: `student_id`, `group_id`, `title`, `date`, `start_at`, `duration_minutes`, `is_free`, `is_paid_for`, `price`, `status`, `notes`, `source`, `payment_status`.

Cannot provide both `student_id` and `group_id` in the same update.

### Delete Lesson

**Endpoint:** `DELETE /api/lessons/{id}`

Permanently deletes the lesson and associated student notes.

### Mark Lesson Payment Status

**Endpoint:** `POST /api/lessons/{lessonId}/payment`

Preferred way to settle a single lesson. See [Payments API](./payments-api.md).

### Calendar Range View

**Endpoint:** `GET /api/calendar`

Required query: `start_date`, `end_date` (YYYY-MM-DD).  
Optional: `source` (`schedule` \| `journal`).

See also Payments API for marking lessons paid/prepaid and analytics.
