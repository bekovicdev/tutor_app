# Groups API

## Overview

The Groups API manages groups for the authenticated tutor.  
All endpoints below require `Authorization: Bearer {token}`.

## Endpoints

### List All Groups

Get a list of all groups for the authenticated tutor.

**Endpoint:** `GET /api/groups`

**Query Parameters:**
- `status` (optional): `0` or `1` (default is `1`)
- `member_status` (optional): filter relation data by pivot `status`
- `search` (optional): searches by `name`
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

### Create Group

Create a new group.

**Endpoint:** `POST /api/groups`

**Request Body:**
```json
{
  "name": "Beginner Group",
  "color": "#33FF57",
  "status": 1,
  "lesson_cost": 400
}
```

**Required Fields:**
- `name` (string, max 255)

**Optional Fields:**
- `color` (string, max 7, hex color code)
- `status` (integer, 0 or 1, default: 1)
- `lesson_cost` (numeric, min: 0)

**Response:**
```json
{
  "success": true,
  "message": "Group created successfully",
  "data": {}
}
```

---

### Get Group

Get a specific group by ID.

**Endpoint:** `GET /api/groups/{id}`

**Response:**
```json
{
  "success": true,
  "data": {}
}
```

---

### Update Group

Update a group's information.

**Endpoint:** `PUT /api/groups/{id}` or `PATCH /api/groups/{id}`

**Request Body:**
```json
{
  "name": "Advanced Group",
  "color": "#5733FF",
  "lesson_cost": 450
}
```

**Optional Fields:**
- `name` (string, max 255)
- `color` (string, max 7, hex color code)
- `status` (integer, 0 or 1)
- `lesson_cost` (numeric, min: 0)

**Response:**
```json
{
  "success": true,
  "message": "Group updated successfully",
  "data": {}
}
```

---

### Delete Group

Soft delete a group (sets status to 0).

**Endpoint:** `DELETE /api/groups/{id}`

**Response:**
```json
{
  "success": true,
  "message": "Group deleted successfully"
}
```

**Note:** This operation sets the group's status to 0 (inactive) rather than permanently deleting the record.
