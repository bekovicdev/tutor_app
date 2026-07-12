# Tutor App

Bu proje, ozel ogretmenler icin planlama ve takip uygulamasidir.

## Common API Information

### Base URL

`/api` varsayilan API prefix'idir.  
Versionlanmis route'lar ayni endpoint yapisiyla `/api/v1` altinda da kullanilabilir.

### Authentication

Public endpoint'ler (token gerekmez):

- `POST /api/register`
- `POST /api/login`
- `GET /api/auth/{provider}/redirect`
- `GET /api/auth/{provider}/callback`

Protected endpoint'ler Sanctum bearer token gerektirir:

```text
Authorization: Bearer {token}
```

### Response Patterns

Basarili response'lar her zaman su alani icerir:

```json
{
  "success": true
}
```

Bir cok response `message` ve/veya `data` da icerir.

Validation/business error response'lari genellikle:

```json
{
  "success": false,
  "errors": {
    "field": ["Validation message"]
  }
}
```

veya:

```json
{
  "success": false,
  "message": "Business rule message"
}
```

### Common Status Codes

- `200 OK`: Basarili
- `201 Created`: Kayit olusturuldu
- `401 Unauthorized`: Gecersiz giris bilgileri / eksik auth
- `403 Forbidden`: Kullanici dogrulanmis ama yetkisi yok (ornek: pasif hesap)
- `404 Not Found`: Kaynak mevcut scope icinde bulunamadi
- `422 Unprocessable Entity`: Validation veya business rule hatasi
- `503 Service Unavailable`: OAuth provider config eksik

### Ownership and Access Rules

- Tutor scope'undaki kaynaklar (`students`, `groups`, `lessons`, `student-notes`) sadece authenticated tutor tarafindan erisilebilir.
- Admin API endpoint'leri hem `auth:sanctum` hem de `admin` middleware'i ile korunur.

### Domain Rules

- Lesson olusturulurken yalnizca bir tane baglanti verilir: ya `student_id` ya da `group_id` (ikisi birden veya hicbiri olamaz).
- Student notes sadece group lesson'lar icin kullanilabilir.
- Tutor/admin API'lerinde student/group/user silme islemleri hard delete degil, deactivation (`status = 0`) olarak uygulanir.

## API Docs

- Auth API: `docs/login-auth-api.md`
- Groups API: `docs/groups-api.md`
