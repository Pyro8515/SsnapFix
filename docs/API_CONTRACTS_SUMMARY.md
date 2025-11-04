# API Contracts Summary

This document summarizes the API contracts implementation completed by Agent A (API & Contracts Lead).

## Overview

The single source of truth for mobile↔server communication has been established with:

1. **OpenAPI Specification** (`/docs/openapi.yaml`)
2. **Example Response Schemas** (`/docs/schemas/*.md`)
3. **Generated Dart DTOs** (`/lib/shared/data/api/dtos/*`)

## Deliverables

### 1. OpenAPI Specification (`/docs/openapi.yaml`)

Comprehensive OpenAPI 3.0.3 specification covering all endpoints:

- ✅ GET /api/me
- ✅ POST /api/role/switch
- ✅ GET /api/offers
- ✅ POST /api/pro/offers/accept (with 409 {reasons:[]} on gate)
- ✅ POST /api/stripe/identity/start + webhook payload schema
- ✅ POST /api/pro-docs/presign
- ✅ POST /api/pro-docs/submit
- ✅ POST /api/payments/start + webhook payload schema
- ✅ POST /api/background/start (Optional)

**Key Features:**
- Detailed request/response schemas
- Webhook payload schemas for Stripe Identity and Payments
- Error response schemas with `reasons` array for 409 responses
- All enums and types properly defined
- Security schemes (Bearer JWT)

### 2. Example Response Files (`/docs/schemas/*.md`)

Example response files for each endpoint:

- `api-me.md` - User information endpoint
- `api-role-switch.md` - Role switching endpoint
- `api-offers.md` - Offers listing endpoint
- `api-pro-offers-accept.md` - Offer acceptance with compliance gate examples
- `api-stripe-identity-start.md` - Identity verification start
- `api-stripe-identity-webhook.md` - Identity webhook payload examples
- `api-pro-docs-presign.md` - Document presign endpoint
- `api-pro-docs-submit.md` - Document submission endpoint
- `api-payments-start.md` - Payments onboarding start
- `api-stripe-payments-webhook.md` - Payments webhook payload examples
- `api-background-start.md` - Background check endpoint (optional)

Each file includes:
- Request body examples (for POST endpoints)
- Success responses (200 OK)
- Error responses (400, 401, 403, 404, 409, 500)

### 3. Generated Dart DTOs (`/lib/shared/data/api/dtos/*`)

Type-safe Dart models generated from the OpenAPI spec:

- `user_response.dart` - UserResponse, ProfessionalProfile, DocumentStatus, TradeCompliance
- `offer_dto.dart` - Offer, OfferAcceptRequest, OfferAcceptResponse
- `role_switch_dto.dart` - RoleSwitchResponse
- `document_dto.dart` - PresignRequest, PresignResponse, DocumentSubmitRequest, DocumentSubmitResponse
- `stripe_dto.dart` - IdentityStartResponse, PaymentsStartResponse, StripeWebhookEvent, BackgroundStartResponse
- `error_response.dart` - ErrorResponse with reasons array
- `dtos.dart` - Convenient export file for all DTOs

**Features:**
- Type-safe enums (AccountType, VerificationStatus, DocumentStatusEnum, OfferStatus, etc.)
- JSON serialization/deserialization (fromJson/toJson)
- Nullable fields properly handled
- All field names match OpenAPI spec exactly

## Usage

### Using DTOs in Flutter Code

```dart
import 'package:getdone/shared/data/api/dtos/dtos.dart';

// Parse API response
final userResponse = UserResponse.fromJson(jsonData);

// Build request
final request = OfferAcceptRequest(offerId: 'abc-123');
final requestJson = request.toJson();

// Handle errors
try {
  // API call
} catch (e) {
  if (e is ApiException && e.statusCode == 409) {
    final error = ErrorResponse.fromJson(jsonDecode(e.body));
    if (error.reasons != null) {
      // Handle compliance gate reasons
    }
  }
}
```

### Frontend Compilation

All DTOs are verified to compile without errors:
```bash
flutter analyze lib/shared/data/api/dtos/
# No issues found!
```

## Acceptance Criteria ✅

- ✅ Frontend compiles using generated DTOs
- ✅ No guessing field names - all fields match OpenAPI spec exactly
- ✅ Single source of truth established (`/docs/openapi.yaml`)
- ✅ Example responses provided for each endpoint
- ✅ All required endpoints covered
- ✅ Webhook payload schemas included
- ✅ 409 response with `reasons` array properly defined

## Next Steps

1. **Frontend Integration**: Update existing API client code to use the new DTOs
2. **Type Generation**: Consider automating DTO generation from OpenAPI spec in CI/CD
3. **Documentation**: Update API documentation to reference the OpenAPI spec
4. **Testing**: Use DTOs in API integration tests

## Notes

- All DTOs are generated from the OpenAPI spec and annotated as such
- The OpenAPI spec is the single source of truth - any changes should be made there first
- DTOs can be regenerated if the OpenAPI spec changes
- Webhook payloads follow Stripe's event structure
- The `/api/background/start` endpoint is marked as optional and may not be implemented yet

