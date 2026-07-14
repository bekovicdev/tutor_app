# Tutor App

Bu proje, ozel ogretmenler icin planlama ve takip uygulamasidir.

## Common API Information

### Base URL

`/api` is the default API prefix.  
Versioned routes are also available under `/api/v1` with the same endpoint structure.

### Authentication

Public endpoints (no token required):

- `POST /api/register`
- `POST /api/login`
- `GET /api/auth/{provider}/redirect`
- `GET /api/auth/{provider}/callback`

Protected endpoints require Sanctum bearer token:

```text
Authorization: Bearer {token}
```

### Response Patterns

Success responses always include:

```json
{
  "success": true
}
```

Many responses also include `message` and/or `data`.

Validation/business errors commonly return:

```json
{
  "success": false,
  "errors": {
    "field": ["Validation message"]
  }
}
```

or:

```json
{
  "success": false,
  "message": "Business rule message"
}
```

### Common Status Codes

- `200 OK`: Success
- `201 Created`: Resource created
- `401 Unauthorized`: Invalid credentials / missing auth
- `403 Forbidden`: Authenticated but not allowed (example: inactive account)
- `404 Not Found`: Resource does not exist for current scope
- `422 Unprocessable Entity`: Validation or business rule error
- `503 Service Unavailable`: Missing OAuth provider config

### Ownership & Access Rules

- Tutor-scoped resources (`students`, `groups`, `lessons`, `payments`, `student-notes`) are restricted to the authenticated tutor.
- Admin API endpoints are protected by both `auth:sanctum` and `admin` middleware.

### Domain Rules

- A lesson must belong to either one `student_id` or one `group_id` at creation time (not both, not neither).
- Student notes are only available for group lessons.
- Deleting students/groups/users in tutor/admin APIs is implemented as deactivation (`status = 0`) rather than hard delete.
- Lesson `payment_status` is one of `unpaid`, `paid`, `prepaid`. Settled statuses (`paid`, `prepaid`) keep `is_paid_for=true` for backward compatibility.
- Financial analytics exclude cancelled and free lessons from billable totals.

## API Docs

- Auth API: `docs/login-auth-api.md`
- Notifications API: `docs/notifications-api.md`
- Billing API: `docs/billing-api.md`
- Students API: `docs/students-api.md`
- Groups API: `docs/groups-api.md`
- Lessons API: `docs/lessons-api.md`
- Payments API: `docs/payments-api.md`
