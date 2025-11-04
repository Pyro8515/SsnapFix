# POST /api/role/switch

## Success Response (200 OK)

```json
{
  "active_role": "professional"
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
  "error": "Role switching not allowed for this account"
}
```

## Error Response (409 Conflict)

```json
{
  "error": "Cannot switch to professional role: identity not verified"
}
```

