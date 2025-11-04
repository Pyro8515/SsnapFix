# GET /api/offers

## Query Parameters

- `trade` (optional): Filter by trade type (e.g., "plumbing")
- `lat` (optional): Latitude for distance filtering
- `lng` (optional): Longitude for distance filtering
- `max_distance` (optional): Maximum distance in km (default: 50)

## Success Response (200 OK)

```json
[
  {
    "id": "660e8400-e29b-41d4-a716-446655440000",
    "job_title": "Fix leaking kitchen faucet",
    "description": "Kitchen faucet has been leaking for a week. Need urgent repair.",
    "trade": ["plumbing"],
    "location_lat": 40.7128,
    "location_lng": -74.0060,
    "customer_user_id": "770e8400-e29b-41d4-a716-446655440000",
    "status": "open",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  },
  {
    "id": "880e8400-e29b-41d4-a716-446655440000",
    "job_title": "Install new electrical panel",
    "description": "Replace old 100A panel with new 200A panel",
    "trade": ["electrical"],
    "location_lat": 40.7580,
    "location_lng": -73.9855,
    "customer_user_id": "990e8400-e29b-41d4-a716-446655440000",
    "status": "open",
    "created_at": "2024-01-14T14:20:00Z",
    "updated_at": "2024-01-14T14:20:00Z"
  }
]
```

## Error Response (401 Unauthorized)

```json
{
  "error": "Unauthorized"
}
```

