# Frontend Architecture Discussion - Customer & Professional POV

## Current State Analysis

### ✅ What We Have

#### Customer Side (`lib/features/customer/`)
1. **Customer Dashboard** (`customer_dashboard_page.dart`)
   - Service selection (Plumbing, Electrical, etc.)
   - Quick actions: "Book again", "Active jobs", "Saved addresses", "Recent activity"
   - Role toggle (switch to Pro view)
   - **Status**: Basic UI, placeholder actions

2. **Booking Page** (`booking_page.dart`)
   - **Status**: Need to check implementation

3. **Track Job Page** (`track_job_page.dart`)
   - **Status**: Need to check implementation

#### Professional Side (`lib/features/pro/`)
1. **Pro Dashboard** (`pro_dashboard_page.dart`)
   - Online status toggle
   - Recent offers/jobs preview
   - Account snapshot (services, verification, payouts, trade compliance)
   - Bottom navigation (Dashboard, Jobs, Map, Messages, Account)
   - Verification banner
   - **Status**: Functional but needs integration with new endpoints

2. **Jobs Page** (`jobs_page.dart`)
   - **Status**: Need to check implementation

3. **Map Page** (`map_page.dart`)
   - **Status**: Need to check implementation

4. **Messages Page** (`messages_page.dart`)
   - **Status**: Need to check implementation

5. **Account Page** (`account_page.dart`)
   - **Status**: Need to check implementation

6. **Verification Page** (`verification/verification_page.dart`)
   - **Status**: Exists for document upload flow

### 🔴 What's Missing (New Features We Built)

#### Backend Endpoints We Need to Wire Up:
1. **Job Creation** (`POST /api/jobs`)
   - Customer creates a job request
   - Needs: Service selection, address input, location picker, scheduling, notes

2. **Job Status Updates** (`POST /api/jobs/{id}/status`)
   - Pro updates: `en_route`, `arrived`, `started`, `completed`
   - Customer sees real-time updates
   - Needs: Status UI, location tracking, notifications

3. **Matching Engine** (`POST /api/jobs/match`)
   - Auto-match pros when job created
   - Pro sees job offers
   - Needs: Offer acceptance flow, expiration handling

4. **Ratings System** (`POST /api/ratings/{jobId}`, `GET /api/ratings`)
   - Customer rates completed jobs
   - Pro sees rating history
   - Needs: Rating UI, star input, comment field, rating history

## Design Discussion Points

### 1. **Customer Journey Flow**

```
Customer Dashboard
  ↓ (Select Service)
Service Selection → Location Input → Job Details → Payment → Confirmation
  ↓
Active Jobs List
  ↓ (Select Job)
Job Tracking Page
  - Real-time status (requested → assigned → en_route → arrived → started → completed)
  - Pro info (name, photo, rating)
  - Location tracking (map view)
  - Chat/messages
  ↓ (Job Completed)
Rating Page
  - Star rating (1-5)
  - Comment
  - Submit
```

**Questions:**
- Should customers see a list of available pros before booking, or is it auto-matching only?
- Do we need a "Find Pros" feature where customers can browse and select?
- How should job scheduling work? (immediate, scheduled, recurring?)

### 2. **Professional Journey Flow**

```
Pro Dashboard
  ↓ (See Available Jobs)
Jobs List/Map View
  - Filter by service, distance, payout
  - See job details (service, location, price, customer rating)
  ↓ (Accept Offer)
Job Details Page
  - Customer info
  - Job requirements
  - Route to location
  - Start job button
  ↓ (On the Way)
Status Updates
  - En Route (GPS tracking)
  - Arrived (check-in)
  - Started (payment capture)
  - Completed (rating request)
  ↓
Payment Received
  - Payout amount
  - Platform fee breakdown
```

**Questions:**
- Should pros see all available jobs on a map, or just a list?
- How should offer expiration work? (30 min timer UI?)
- Do we need job bidding, or fixed pricing only?
- Should pros be able to message customers before accepting?

### 3. **Navigation Architecture**

#### Customer Navigation Structure:
```
Bottom Navigation (if needed):
- Home (Dashboard)
- Active Jobs (list of active/pending jobs)
- History (completed jobs)
- Profile/Settings
```

#### Professional Navigation Structure:
```
Bottom Navigation (already exists):
- Dashboard
- Jobs (available/active)
- Map (job locations)
- Messages
- Account
```

**Questions:**
- Should both have similar navigation patterns?
- Do we need separate "Active" and "History" tabs for customers?
- Should pros have a "Earnings" tab?

### 4. **Real-time Features**

What needs real-time updates:
- **Customer**: Job status changes, pro en route, arrival notifications
- **Pro**: New job offers, offer expiration, job status updates
- **Both**: Messages/chat

**Questions:**
- Use Supabase Realtime subscriptions?
- Push notifications for status changes?
- Should location tracking be real-time or periodic?

### 5. **Job Status Flow UI**

Status transitions need clear UI:

**Customer View:**
- "Job Requested" → "Finding Pro..." → "Pro Assigned" → "Pro En Route" → "Pro Arrived" → "Work Started" → "Work Completed" → "Rate Pro"

**Pro View:**
- "Offer Received" → "Offer Accepted" → "En Route" → "Arrived" → "Started" → "Completed" → "Payment Processing"

**Questions:**
- Timeline view vs. status cards?
- Progress indicators/animations?
- Estimated time for each status?

### 6. **Ratings & Reviews**

**Customer:**
- Rate after completion (mandatory or optional?)
- See pro's overall rating before booking
- View past ratings given

**Pro:**
- See customer's rating history
- View all ratings received
- Rating breakdown (5★, 4★, etc.)

**Questions:**
- Should ratings be mandatory before next job?
- Can customers edit ratings?
- Should pros rate customers too?

### 7. **Payment Integration**

**Customer:**
- Payment method selection
- Payment authorization (hold)
- Payment capture on "started"
- Receipt view

**Pro:**
- Payout tracking
- Earnings history
- Platform fee breakdown
- Payout schedule

**Questions:**
- Stripe integration UI needed?
- Payment method management page?
- Should customers see payment status in real-time?

## Recommended Structure

### Customer Features Needed:
```
lib/features/customer/
├── presentation/
│   ├── customer_dashboard_page.dart ✅ (exists, needs enhancement)
│   ├── booking/
│   │   ├── service_selection_page.dart (NEW)
│   │   ├── location_input_page.dart (NEW)
│   │   ├── job_details_page.dart (NEW)
│   │   └── payment_page.dart (NEW)
│   ├── jobs/
│   │   ├── active_jobs_page.dart (NEW)
│   │   ├── job_detail_page.dart (NEW)
│   │   └── job_tracking_page.dart (enhance existing)
│   ├── history/
│   │   ├── job_history_page.dart (NEW)
│   │   └── job_detail_page.dart (reuse)
│   └── ratings/
│       ├── rating_page.dart (NEW)
│       └── rating_history_page.dart (NEW)
```

### Professional Features Needed:
```
lib/features/pro/
├── presentation/
│   ├── pro_dashboard_page.dart ✅ (exists, needs integration)
│   ├── jobs/
│   │   ├── jobs_page.dart ✅ (exists, needs enhancement)
│   │   ├── job_offer_detail_page.dart (NEW)
│   │   ├── active_job_page.dart (NEW)
│   │   └── job_status_update_page.dart (NEW)
│   ├── map_page.dart ✅ (exists, needs integration)
│   ├── messages_page.dart ✅ (exists)
│   ├── account_page.dart ✅ (exists)
│   └── earnings/
│       ├── earnings_page.dart (NEW)
│       └── payout_history_page.dart (NEW)
```

## Key Design Decisions Needed

1. **Job Booking Flow**
   - Single-page form vs. multi-step wizard?
   - Auto-match only or customer can choose pro?

2. **Job Discovery for Pros**
   - Map view vs. list view vs. both?
   - Filtering options (distance, payout, service type)?

3. **Real-time Updates**
   - Which updates need real-time vs. polling?
   - Push notification strategy?

4. **Navigation Pattern**
   - Bottom navigation for both?
   - Tab-based navigation?
   - Drawer navigation?

5. **State Management**
   - Current: Riverpod ✅
   - Need: Job state management, real-time subscriptions

## Next Steps

1. **Decide on core flows** (booking, matching, status updates)
2. **Design navigation structure** (customer vs. pro)
3. **Plan real-time features** (what needs live updates)
4. **Wire up new endpoints** (jobs, ratings, status updates)
5. **Build missing UI screens** (job creation, tracking, ratings)

---

**Let's discuss:**
- What's your vision for the customer booking flow?
- How should pros discover and accept jobs?
- What real-time features are most important?
- Any specific UI/UX patterns you want to follow?

