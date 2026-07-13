# Students API

## Overview

The Students API manages students that belong to the authenticated tutor.  
All endpoints below require `Authorization: Bearer {token}`.

## Endpoints

### List All Students

**Endpoint:** `GET /api/students`

**Query Parameters:**
- `status` (optional): `0` or `1` (default is `1`)
- `search` (optional): searches by `name` and `phone`
- `sort_by` (optional): `created_at`, `name`, `status` (default `created_at`)
- `sort_direction` (optional): `asc` or `desc` (default `desc`)
- `per_page` (optional): `1..100` (default `15`)

**Response:**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [],
    "per_page": 15,
    "total": 0
  }
}
```

---

### Create Student

**Endpoint:** `POST /api/students`

**Required Fields:**
- `name` (string, max 255)

**Optional Fields:**
- `phone` (string, max 20)
- `birthday` (date, format: YYYY-MM-DD)
- `lesson_cost` (numeric, min: 0)
- `notes` (string)
- `color` (string, max 7, hex color code)
- `status` (integer, 0 or 1, default: 1)

---

### Get Student

**Endpoint:** `GET /api/students/{id}`

Returns `student` and `summary` (lessons_total, lessons_completed, lessons_cancelled, last_lesson_date).

---

### Update Student

**Endpoint:** `PUT /api/students/{id}` or `PATCH /api/students/{id}`

All fields optional: `name`, `phone`, `birthday`, `lesson_cost`, `notes`, `color`, `status`.

---

### Delete Student

**Endpoint:** `DELETE /api/students/{id}`

Soft delete — sets `status` to 0.

---

### Upload Profile Picture

Upload or replace a student's profile picture.

**Endpoint:** `POST /api/students/{id}/profile-picture`

**Content-Type:** `multipart/form-data`

**Body:**
- `profile_picture` (required image: jpeg, jpg, png, webp, max 5MB)

**Response:**
```json
{
  "success": true,
  "message": "Profile picture uploaded successfully",
  "data": {
    "id": 1,
    "profile_picture": "students/profile-pictures/abc.jpg",
    "profile_picture_url": "http://127.0.0.1:8000/storage/students/profile-pictures/abc.jpg"
  }
}
```

Student list/detail payloads may include `profile_picture` and `profile_picture_url`.

---

### Remove Profile Picture

**Endpoint:** `DELETE /api/students/{id}/profile-picture`

**Response:**
```json
{
  "success": true,
  "message": "Profile picture removed successfully",
  "data": {
    "id": 1,
    "profile_picture": null,
    "profile_picture_url": null
  }
}
```

---

### Student Balance Summary

**Endpoint:** `GET /api/students/{id}/balance`

Returns paid / prepaid / unpaid lesson totals and cashflow.

**Response fields:** `student_id`, `student_name`, `currency`, `total_amount`, `paid_amount`, `prepaid_amount`, `unpaid_amount`, `settled_amount`, `cash_collected`, `cash_refunded`, `cash_net`.

See Payments API for full payment and analytics endpoints.
