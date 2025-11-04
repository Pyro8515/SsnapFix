# POST /api/pro/offers/accept

## Request Body

```json
{
  "offer_id": "660e8400-e29b-41d4-a716-446655440000"
}
```

## Success Response (200 OK)

```json
{
  "success": true,
  "offer_id": "660e8400-e29b-41d4-a716-446655440000"
}
```

## Error Response (400 Bad Request)

```json
{
  "error": "offer_id is required"
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
  "error": "Only active professionals can accept offers"
}
```

## Error Response (404 Not Found)

```json
{
  "error": "Offer not found"
}
```

## Error Response (409 Conflict) - Compliance Gate

```json
{
  "error": "Cannot accept offer: compliance issues",
  "reasons": [
    "Not compliant for trades: electrical",
    "Missing compliance verification for trades: hvac",
    "Account verification status is pending"
  ]
}
```

## Error Response (409 Conflict) - Already Assigned

```json
{
  "error": "Offer already assigned",
  "reasons": [
    "This offer has already been assigned to you"
  ]
}
```

## Error Response (409 Conflict) - Offer Not Available

```json
{
  "error": "Offer is not available",
  "reasons": [
    "Offer status is assigned"
  ]
}
```

