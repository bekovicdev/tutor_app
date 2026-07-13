# Payments API

## Overview

The Payments API tracks lesson settlement and cashflow for the authenticated tutor.

Lessons are classified by `payment_status`:

| Status | Meaning |
|--------|---------|
| `unpaid` | Ders ücreti henüz alınmadı (alacak) |
| `paid` | Ders ücreti ödendi |
| `prepaid` | Ders ücreti önceden ödendi |

`is_paid_for` is kept for backward compatibility:
- `paid` / `prepaid` → `is_paid_for = true`
- `unpaid` → `is_paid_for = false`

Payment records (`payments` table) store actual cash movements (`lesson`, `prepaid`, `refund`).

All endpoints require `Authorization: Bearer {token}`.

---

## Concepts

### Lesson settlement vs cashflow

- **Lesson-based**: amounts derived from lesson `price` + `payment_status` (what should be collected).
- **Cash-based**: amounts from `payments.paid_at` (what actually entered/left the till).

### Payment kinds

| Kind | Use |
|------|-----|
| `lesson` | Payment applied to a given/settled lesson |
| `prepaid` | Advance payment (with or without a linked lesson) |
| `refund` | Money returned |

### Payment methods

`cash`, `transfer`, `card`, `other` (optional).

---

## Endpoints

### List Payments

**Endpoint:** `GET /api/payments`

**Query Parameters:**
- `kind` (optional): `lesson` \| `prepaid` \| `refund`
- `method` (optional): `cash` \| `transfer` \| `card` \| `other`
- `student_id`, `group_id`, `lesson_id` (optional)
- `from`, `to` (optional, `YYYY-MM-DD`, filters `paid_at`)
- `sort_by` (optional): `paid_at`, `amount`, `created_at` (default `paid_at`)
- `sort_direction` (optional): `asc` \| `desc` (default `desc`)
- `per_page` (optional): 1–100 (default 20)

---

### Record Payment

**Endpoint:** `POST /api/payments`

**Rules:**
- `amount` required, `> 0`
- Provide at least one of `lesson_id`, `student_id`, `group_id`
- If `lesson_id` is set and `apply_to_lesson` is true (default):
  - `kind=lesson` → lesson becomes `paid`
  - `kind=prepaid` → lesson becomes `prepaid`
  - `kind=refund` does not auto-change lesson status

---

### Get Payment

**Endpoint:** `GET /api/payments/{id}`

### Delete Payment

**Endpoint:** `DELETE /api/payments/{id}`

If the payment was linked to a lesson and no other `lesson`/`prepaid` payments remain on that lesson, the lesson returns to `unpaid`.

---

### Mark Lesson Payment Status

**Endpoint:** `POST /api/lessons/{lessonId}/payment`

**Fields:**
- `payment_status` (required): `unpaid` \| `paid` \| `prepaid`
- `amount` (optional): defaults to lesson `price` when recording a payment
- `method`, `paid_at`, `notes` (optional)
- `record_payment` (optional): defaults to `true` when status is settled (`paid`/`prepaid`), `false` for `unpaid`

Free lessons (`is_free=true`) cannot be marked.

---

## Analytics

- `GET /api/payments/analytics/overview` — period overview (lessons, cashflow, receivables, earned)
- `GET /api/payments/analytics/monthly?months=12` — lesson-based + cash-based monthly series
- `GET /api/payments/analytics/receivables` — unpaid billable lessons
- `GET /api/payments/analytics/prepaid` — prepaid lessons + unallocated prepaid credits

---

## Related Endpoints

- `GET /api/lessons?payment_status=unpaid`
- `GET /api/students/{id}/balance`
- `GET /api/reports/monthly-revenue?month=2026-07` (legacy; prefer analytics/monthly)

---

## Domain Notes

- Cancelled and free lessons are excluded from billable analytics.
- Deleting a payment may reopen the linked lesson as unpaid.
- Currency is currently fixed as `TRY` in API responses.
