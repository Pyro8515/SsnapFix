# POST /api/stripe/identity/start

## Success Response (200 OK)

```json
{
  "verification_session_id": "vs_1234567890abcdef",
  "client_secret": "vs_1234567890abcdef_secret_abc123",
  "url": "https://verify.stripe.com/start/vs_1234567890abcdef"
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
  "error": "Only professionals can start identity verification"
}
```

## Error Response (500 Internal Server Error)

```json
{
  "error": "Failed to create Stripe Identity session",
  "details": {
    "error": {
      "message": "Invalid API key"
    }
  }
}
```

