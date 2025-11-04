# POST /api/pro-docs/submit

## Request Body

```json
{
  "file_url": "https://storage.supabase.co/pro-docs/user-id/license/plumbing/abc123.pdf",
  "doc_type": "license",
  "doc_subtype": "plumbing",
  "number": "PL-12345",
  "issuer": "State Board of Plumbing",
  "issued_at": "2023-01-15",
  "expires_at": "2025-01-15"
}
```

## Success Response (200 OK)

```json
{
  "id": "aa0e8400-e29b-41d4-a716-446655440000",
  "status": "pending",
  "message": "Document submitted successfully"
}
```

## Error Response (400 Bad Request)

```json
{
  "error": "file_url and doc_type are required"
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
  "error": "Only professionals can submit documents"
}
```

## Error Response (500 Internal Server Error)

```json
{
  "error": "Failed to save document",
  "details": "Database constraint violation"
}
```

