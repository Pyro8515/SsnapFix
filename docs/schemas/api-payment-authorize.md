# Payment Authorization Flow (v2)

This document describes the payment authorization contract for booking jobs. This is a **future feature (v2)** that will allow customers to authorize payments when booking jobs.

## Overview

The payment authorization flow allows customers to:
1. Authorize payment for a job booking
2. Hold funds in escrow until job completion
3. Release payment to professional after job completion
4. Handle refunds/disputes

## Flow Diagram

```
Customer books job
  ↓
POST /api/bookings (v2)
  ↓
Create Payment Intent with Stripe
  ↓
Customer authorizes payment (client_secret)
  ↓
Funds held in escrow
  ↓
Job completed
  ↓
POST /api/bookings/:id/complete (v2)
  ↓
Release payment to professional
```

## Endpoints (v2 - Future)

### POST /api/bookings

**Purpose**: Create a booking with payment authorization

**Request Body**:
```json
{
  "offer_id": "uuid",
  "professional_user_id": "uuid",
  "payment_method_id": "pm_xxx",
  "amount": 50000,
  "currency": "usd",
  "description": "Plumbing repair for kitchen sink"
}
```

**Response**:
```json
{
  "booking_id": "uuid",
  "payment_intent_id": "pi_xxx",
  "client_secret": "pi_xxx_secret_xxx",
  "status": "pending_authorization",
  "amount": 50000,
  "currency": "usd"
}
```

**Status Codes**:
- `200`: Booking created, payment authorization required
- `400`: Invalid request (missing fields, invalid amount)
- `401`: Unauthorized
- `403`: Forbidden (not a customer)
- `404`: Offer or professional not found
- `409`: Conflict (professional not available, not compliant)

---

### POST /api/bookings/:id/confirm-payment

**Purpose**: Confirm payment authorization (called from frontend after Stripe confirmation)

**Request Body**:
```json
{
  "payment_intent_id": "pi_xxx",
  "status": "succeeded"
}
```

**Response**:
```json
{
  "booking_id": "uuid",
  "status": "confirmed",
  "payment_status": "authorized",
  "amount_held": 50000
}
```

**Status Codes**:
- `200`: Payment confirmed
- `400`: Invalid payment intent
- `404`: Booking not found
- `409`: Payment already confirmed

---

### POST /api/bookings/:id/complete

**Purpose**: Mark job as complete and release payment to professional

**Request Body**:
```json
{
  "completed_at": "2024-01-15T10:30:00Z",
  "notes": "Job completed successfully"
}
```

**Response**:
```json
{
  "booking_id": "uuid",
  "status": "completed",
  "payment_status": "paid",
  "payout_id": "po_xxx",
  "amount_paid": 50000
}
```

**Status Codes**:
- `200`: Job completed, payment released
- `400`: Invalid request
- `401`: Unauthorized
- `403`: Forbidden (only customer or professional can complete)
- `404`: Booking not found
- `409`: Job already completed or payment not authorized

---

### POST /api/bookings/:id/cancel

**Purpose**: Cancel booking and refund payment

**Request Body**:
```json
{
  "reason": "customer_cancelled",
  "refund_amount": 50000
}
```

**Response**:
```json
{
  "booking_id": "uuid",
  "status": "cancelled",
  "payment_status": "refunded",
  "refund_id": "re_xxx",
  "amount_refunded": 50000
}
```

**Status Codes**:
- `200`: Booking cancelled, refund processed
- `400`: Invalid request
- `401`: Unauthorized
- `404`: Booking not found
- `409`: Cannot cancel (already completed or payment released)

---

### GET /api/bookings/:id

**Purpose**: Get booking details including payment status

**Response**:
```json
{
  "id": "uuid",
  "offer_id": "uuid",
  "customer_user_id": "uuid",
  "professional_user_id": "uuid",
  "status": "confirmed",
  "payment_status": "authorized",
  "payment_intent_id": "pi_xxx",
  "amount": 50000,
  "currency": "usd",
  "amount_held": 50000,
  "amount_paid": null,
  "created_at": "2024-01-15T10:00:00Z",
  "completed_at": null,
  "cancelled_at": null
}
```

---

## Database Schema (v2 - Future)

### bookings table

```sql
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  offer_id UUID NOT NULL REFERENCES offers(id),
  customer_user_id UUID NOT NULL REFERENCES users(id),
  professional_user_id UUID NOT NULL REFERENCES users(id),
  status TEXT NOT NULL CHECK (status IN ('pending_authorization', 'confirmed', 'in_progress', 'completed', 'cancelled')),
  payment_intent_id TEXT,
  payment_status TEXT CHECK (payment_status IN ('pending', 'authorized', 'paid', 'refunded', 'failed')),
  amount INTEGER NOT NULL, -- Amount in cents
  currency TEXT NOT NULL DEFAULT 'usd',
  amount_held INTEGER,
  amount_paid INTEGER,
  payout_id TEXT,
  refund_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  confirmed_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  notes TEXT
);
```

---

## Stripe Integration

### Payment Intent Creation

When creating a booking, a Payment Intent is created with:
- `amount`: Job amount in cents
- `currency`: 'usd' (default)
- `payment_method`: Customer's payment method
- `capture_method`: 'manual' (hold funds, don't capture immediately)
- `on_behalf_of`: Professional's Stripe Connect account ID
- `transfer_data[destination]`: Professional's Stripe account
- `application_fee_amount`: Platform fee (if applicable)
- `metadata`: Booking ID, user IDs, offer ID

### Payment Authorization Flow

1. Customer initiates booking
2. Backend creates Payment Intent with `capture_method: 'manual'`
3. Frontend uses `client_secret` to confirm payment with Stripe
4. Payment is authorized but not captured
5. Funds are held in escrow
6. When job is completed, backend captures the payment
7. Funds are transferred to professional's Stripe Connect account

### Payment Release

When job is completed:
1. Backend calls `POST /v1/payment_intents/{id}/capture`
2. Payment is captured and transferred to professional
3. Professional receives payout to their bank account (via Stripe Connect)

### Refunds

If booking is cancelled:
1. Backend calls `POST /v1/refunds`
2. Refund is processed back to customer's payment method
3. Booking status updated to 'cancelled'

---

## Error Handling

### Payment Errors

**Insufficient Funds**:
```json
{
  "error": "payment_failed",
  "code": "card_declined",
  "message": "Your card was declined.",
  "payment_intent_id": "pi_xxx"
}
```

**Payment Already Authorized**:
```json
{
  "error": "payment_already_authorized",
  "code": "conflict",
  "message": "Payment for this booking is already authorized."
}
```

**Professional Not Available**:
```json
{
  "error": "professional_unavailable",
  "code": "conflict",
  "reasons": ["Professional is not accepting new bookings"]
}
```

---

## Security Considerations

1. **Payment Intent Creation**: Only customers can create bookings
2. **Payment Authorization**: Must be done client-side with Stripe.js
3. **Payment Capture**: Only backend can capture payments (after job completion)
4. **Refunds**: Only customer or professional can request refunds (with restrictions)
5. **Webhook Verification**: All Stripe webhooks must be verified
6. **Idempotency**: Payment operations must be idempotent

---

## Webhook Events (v2 - Future)

### payment_intent.succeeded
- Payment authorization confirmed
- Update booking payment_status to 'authorized'

### payment_intent.payment_failed
- Payment authorization failed
- Update booking payment_status to 'failed'
- Notify customer

### charge.refunded
- Refund processed
- Update booking payment_status to 'refunded'
- Update refund_id

---

## Testing

### Test Scenarios

1. **Happy Path**:
   - Customer books job → Payment authorized → Job completed → Payment released

2. **Cancellation**:
   - Customer books job → Payment authorized → Customer cancels → Refund processed

3. **Payment Failure**:
   - Customer books job → Payment fails → Booking not confirmed → Customer notified

4. **Professional Not Available**:
   - Customer books job → Professional unavailable → Booking rejected → Payment not authorized

---

## Implementation Notes

- This is a **v2 feature** and not yet implemented
- Requires Stripe Connect accounts for professionals
- Requires payment method storage for customers
- Requires escrow management
- Requires dispute handling
- Requires payout scheduling

---

## Related Documentation

- [Stripe Connect Documentation](https://stripe.com/docs/connect)
- [Payment Intents API](https://stripe.com/docs/payments/payment-intents)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)

