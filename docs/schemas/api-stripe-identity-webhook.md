# POST /api/stripe/identity/webhook

## Request Body (Stripe Webhook Event)

```json
{
  "id": "evt_1234567890abcdef",
  "type": "identity.verification_session.verified",
  "data": {
    "object": {
      "id": "vs_1234567890abcdef",
      "type": "document",
      "status": "verified",
      "client_secret": "vs_1234567890abcdef_secret_abc123",
      "url": "https://verify.stripe.com/start/vs_1234567890abcdef",
      "metadata": {
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "auth_user_id": "auth_user_123"
      }
    }
  },
  "created": 1705324800,
  "livemode": false
}
```

## Success Response (200 OK)

```json
{
  "received": true
}
```

## Success Response (200 OK) - Already Processed

```json
{
  "message": "Event already processed"
}
```

## Error Response (400 Bad Request)

```json
{
  "error": "Missing signature"
}
```

## Error Response (404 Not Found)

```json
{
  "error": "Profile not found"
}
```

## Supported Event Types

- `identity.verification_session.verified` - Verification completed successfully
- `identity.verification_session.requires_input` - Additional information needed
- `identity.verification_session.processing` - Verification in progress
- `identity.verification_session.canceled` - Verification canceled

