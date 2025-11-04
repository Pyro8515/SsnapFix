# POST /api/pro-docs/presign

## Request Body

```json
{
  "doc_type": "license",
  "doc_subtype": "plumbing",
  "file_name": "plumbing_license.pdf"
}
```

## Success Response (200 OK)

```json
{
  "url": "https://storage.supabase.co/pro-docs/user-id/license/plumbing/abc123.pdf?token=xyz",
  "path": "pro-docs/550e8400-e29b-41d4-a716-446655440000/license/plumbing/abc123.pdf",
  "fields": {}
}
```

## Error Response (400 Bad Request)

```json
{
  "error": "doc_type and file_name are required"
}
```

## Error Response (401 Unauthorized)

```json
{
  "error": "Unauthorized"
}
```

## Error Response (403 Forbidden)

```json
{
  "error": "Only professionals can upload documents"
}
```

## Error Response (500 Internal Server Error)

```json
{
  "error": "Failed to create signed URL",
  "details": "Storage bucket not configured",
  "path": "pro-docs/user-id/license/plumbing/abc123.pdf"
}
```

