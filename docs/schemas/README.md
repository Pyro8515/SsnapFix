# API Response Examples

This directory contains example response schemas for all API endpoints defined in `/docs/openapi.yaml`.

## Files

- `api-me.md` - GET /api/me
- `api-role-switch.md` - POST /api/role/switch
- `api-offers.md` - GET /api/offers
- `api-pro-offers-accept.md` - POST /api/pro/offers/accept
- `api-stripe-identity-start.md` - POST /api/stripe/identity/start
- `api-stripe-identity-webhook.md` - POST /api/stripe/identity/webhook
- `api-pro-docs-presign.md` - POST /api/pro-docs/presign
- `api-pro-docs-submit.md` - POST /api/pro-docs/submit
- `api-payments-start.md` - POST /api/payments/start
- `api-stripe-payments-webhook.md` - POST /api/stripe/payments/webhook
- `api-background-start.md` - POST /api/background/start (Optional)

Each file contains:
- Request body examples (for POST endpoints)
- Success response examples (200 OK)
- Error response examples (400, 401, 403, 404, 409, 500)

These examples are derived from the OpenAPI specification and serve as reference documentation for developers.

