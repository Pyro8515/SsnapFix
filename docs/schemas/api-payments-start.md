# POST /api/payments/start

## Success Response (200 OK)

```json
{
  "url": "https://connect.stripe.com/setup/s/acct_1234567890abcdef",
  "expires_at": 1705328400,
  "account_id": "acct_1234567890abcdef"
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
  "error": "Only professionals can set up payments"
}
```

## Error Response (404 Not Found)

```json
{
  "error": "Professional profile not found"
}
```

## Error Response (500 Internal Server Error)

```json
{
  "error": "Failed to create Stripe account",
  "details": {
    "error": {
      "message": "Invalid country code"
    }
  }
}
```

