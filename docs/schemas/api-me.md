# GET /api/me

## Success Response (200 OK)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "account_type": "professional",
  "active_role": "professional",
  "can_switch_roles": true,
  "verification_status": "approved",
  "avatar_url": "https://storage.supabase.co/avatars/user-123.jpg",
  "professional_profile": {
    "services": ["plumbing", "electrical", "hvac"],
    "identity_status": "verified",
    "payouts_enabled": true,
    "payouts_status": "active"
  },
  "documents": [
    {
      "doc_type": "license",
      "doc_subtype": "plumbing",
      "status": "approved",
      "expires_at": "2025-12-31",
      "reason": null
    },
    {
      "doc_type": "insurance",
      "doc_subtype": "general_liability",
      "status": "pending",
      "expires_at": null,
      "reason": "Under review"
    }
  ],
  "trade_compliance": [
    {
      "trade": "plumbing",
      "compliant": true,
      "reason": null
    },
    {
      "trade": "electrical",
      "compliant": false,
      "reason": "Missing required license"
    }
  ]
}
```

## Error Response (401 Unauthorized)

```json
{
  "error": "Unauthorized"
}
```

## Error Response (404 Not Found)

```json
{
  "error": "User not found"
}
```

