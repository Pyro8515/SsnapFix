# POST /api/stripe/payments/webhook

## Request Body (Stripe Webhook Event)

```json
{
  "id": "evt_9876543210fedcba",
  "type": "account.updated",
  "data": {
    "object": {
      "id": "acct_1234567890abcdef",
      "type": "express",
      "details_submitted": true,
      "charges_enabled": true,
      "payouts_enabled": true,
      "payouts_enabled_default": true,
      "country": "US",
      "email": "professional@example.com"
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

- `account.updated` - Stripe Connect account updated
- `account.application.deauthorized` - Account disconnected

