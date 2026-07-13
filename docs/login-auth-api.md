# Login & Auth API

## Overview

This document covers authentication flows for the tutor app API and admin web panel:

- Tutor app registration
- Tutor app email/password login
- Google and Apple OAuth login
- Authenticated session endpoints (`me`, `logout`)
- Admin panel web login

## API Endpoints (Tutor App)

### Register

Create a new tutor user account and return a Sanctum token.

**Endpoint:** `POST /api/register`

Required fields:

- `name` (string)
- `email` (valid email, unique)
- `password` (string, min 8, confirmed)

Optional fields:

- `phone` (string, max 20)
- `individual_lesson_cost` (numeric, min 0)
- `group_lesson_cost` (numeric, min 0)
- `fcm_token` (string)

### Login (Email/Password)

Authenticate a tutor user and receive a Sanctum token.

**Endpoint:** `POST /api/login`

Required fields:

- `email` (valid email)
- `password` (string)

### OAuth Redirect URL (Google / Apple)

Returns the provider authorization URL for mobile/web frontend.

**Endpoint:** `GET /api/auth/{provider}/redirect`

Path parameter:

- `provider` (required): `google` or `apple`

Notes:

- Missing OAuth env vars: `503`
- Unsupported provider: `422`

### OAuth Callback (Google / Apple)

Completes OAuth login, links/creates local user, returns app token in JSON mode.

**Endpoint:** `GET /api/auth/{provider}/callback`

Path parameter:

- `provider` (required): `google` or `apple`

Notes:

- Provider mismatch on account: `422`
- Inactive user: `422`
- Mobile redirect target can be configured as `app://auth-callback?token=...`

### Current User

Get profile for the authenticated user.

**Endpoint:** `GET /api/me`

Includes `individual_lesson_cost` and `group_lesson_cost` when set.

### Update Profile

**Endpoint:** `PUT /api/user`

Optional fields: `name`, `email`, `phone`, `individual_lesson_cost`, `group_lesson_cost`, `fcm_token`, `status`.

Settings default lesson fees are saved here (not only on device).

### Logout

Invalidate current token for authenticated user.

**Endpoint:** `POST /api/logout`

## Web Endpoints (Admin Panel)

### Show Admin Login Form

**Endpoint:** `GET /admin/login`

### Admin Login Submit

**Endpoint:** `POST /admin/login`

Form fields:

- `email` (required, email)
- `password` (required)
- `remember` (optional, boolean)

### Admin Logout

**Endpoint:** `POST /admin/logout`
