# GetDone Design System - Customer & Professional Experiences

## Color Palette Recommendations

### Option 1: Trust & Reliability (Recommended)
**Primary Color**: Deep Teal (#006B6B) or Ocean Blue (#0066CC)
- **Psychology**: Trust, reliability, professionalism, calm
- **Perfect for**: Service marketplace (conveys trust and professionalism)
- **Complementary**: Warm Orange (#FF6B35) for CTAs and highlights

**Full Palette:**
```
Primary:       #006B6B (Deep Teal) - Main brand color
Primary Light: #008B8B (Lighter teal for hover states)
Primary Dark:  #004D4D (Darker teal for pressed states)

Secondary:     #FF6B35 (Warm Orange) - CTAs, highlights, urgency
Secondary Light: #FF8C66
Secondary Dark:  #CC4420

Success:       #10B981 (Emerald Green) - Completed jobs, positive actions
Warning:       #F59E0B (Amber) - Pending, offers, warnings
Error:         #EF4444 (Red) - Errors, cancellations, rejections

Neutral:
- Background:  #FFFFFF (White)
- Surface:     #F9FAFB (Light Gray)
- Border:       #E5E7EB (Gray)
- Text Primary: #111827 (Dark Gray)
- Text Secondary: #6B7280 (Medium Gray)
- Text Disabled: #9CA3AF (Light Gray)
```

### Option 2: Energy & Growth
**Primary Color**: Vibrant Purple (#7C3AED) or Indigo (#4F46E5)
- **Psychology**: Innovation, growth, energy, modern
- **Complementary**: Lime Green (#84CC16) for success

### Option 3: Professional & Modern
**Primary Color**: Slate Blue (#6366F1) or Deep Blue (#1E40AF)
- **Psychology**: Professional, modern, trustworthy
- **Complementary**: Coral (#FF6B6B) for CTAs

**Recommendation: Option 1 (Deep Teal + Warm Orange)**
- Best for service marketplace
- Conveys trust and reliability
- Warm orange creates urgency for CTAs
- Professional yet approachable

---

## Customer vs Professional Design Differentiation

### Design Philosophy

**Customer Experience:**
- **Theme**: "Simple, Fast, Trustworthy"
- **Focus**: Ease of use, quick booking, peace of mind
- **Aesthetic**: Clean, minimal, consumer-friendly
- **Color Usage**: Softer, lighter, more approachable
- **Typography**: More rounded, friendly
- **Spacing**: More generous, less dense
- **Interactions**: Smooth, reassuring, positive

**Professional Experience:**
- **Theme**: "Powerful, Efficient, Data-Driven"
- **Focus**: Productivity, earnings, job management
- **Aesthetic**: Dense information, professional tools
- **Color Usage**: Stronger contrast, more data visualization
- **Typography**: More structured, business-focused
- **Spacing**: More compact, information-dense
- **Interactions**: Quick, efficient, professional

---

## Customer Design System

### Color Palette
```
Primary:       #006B6B (Deep Teal)
Secondary:     #FF6B35 (Warm Orange) - CTAs only
Success:       #10B981 (Emerald Green)
Background:    #FFFFFF (White)
Surface:       #F9FAFB (Very Light Gray)
Text Primary:   #111827 (Dark Gray)
Text Secondary: #6B7280 (Medium Gray)

Accent Colors:
- Service Icons: Various soft pastels (Plumbing: #60A5FA, Electrical: #FBBF24, etc.)
- Active States: #006B6B (Primary)
- Pending: #F59E0B (Amber)
```

### Typography
```
Headlines:     Inter/System - Bold - 24-32px
Titles:        Inter/System - Semi-Bold - 18-20px
Body:          Inter/System - Regular - 16px
Caption:       Inter/System - Regular - 14px
Button:         Inter/System - Semi-Bold - 16px

Line Height:   1.5x (generous, easy to read)
Letter Spacing: Normal (slightly looser for readability)
```

### Components

#### Service Cards
- **Style**: Large, rounded corners (16px), soft shadows
- **Layout**: Grid (2 columns), generous padding (24px)
- **Interactions**: Scale animation (1.05x) on press
- **Icons**: Large (48px), colorful, friendly

#### Job Status Cards
- **Style**: Horizontal cards, rounded (12px), light background
- **Status Indicators**: 
  - Pending: Yellow badge (#F59E0B)
  - Assigned: Blue badge (#006B6B)
  - In Progress: Orange badge (#FF6B35)
  - Completed: Green badge (#10B981)
- **Timeline**: Vertical timeline with dots and lines

#### Map View
- **Style**: Full-screen map with floating action buttons
- **Markers**: Large, friendly, colorful
- **Pro Location**: Animated pulsing marker
- **Route**: Smooth animated polyline

#### Booking Flow
- **Style**: Multi-step wizard with progress indicator
- **Progress**: Horizontal bar with step numbers (1/5, 2/5, etc.)
- **Steps**: Large, clear, minimal information per step
- **Confirmation**: Success screen with celebration animation

#### Dashboard
- **Style**: Hero section with large service cards
- **Sections**: Cards with rounded corners, soft shadows
- **Quick Actions**: Large, prominent buttons
- **Spacing**: Generous (24px between sections)

---

## Professional Design System

### Color Palette
```
Primary:       #006B6B (Deep Teal) - Same as customer
Secondary:     #6366F1 (Indigo) - Data visualization
Success:       #10B981 (Emerald Green)
Warning:       #F59E0B (Amber)
Error:         #EF4444 (Red)
Background:    #F3F4F6 (Light Gray) - Slightly darker
Surface:       #FFFFFF (White)
Text Primary:   #111827 (Dark Gray)
Text Secondary: #4B5563 (Darker Gray - more contrast)

Data Colors:
- Earnings: #10B981 (Green)
- Pending: #F59E0B (Amber)
- Active Jobs: #006B6B (Teal)
- Offers: #6366F1 (Indigo)
```

### Typography
```
Headlines:     SF Pro/System - Bold - 24-28px (more compact)
Titles:        SF Pro/System - Semi-Bold - 18px
Body:          SF Pro/System - Regular - 14px (smaller, denser)
Caption:       SF Pro/System - Regular - 12px
Button:         SF Pro/System - Semi-Bold - 14px

Line Height:   1.4x (more compact)
Letter Spacing: Tighter (more professional)
```

### Components

#### Dashboard Stats Cards
- **Style**: Compact cards, data-dense, charts/graphs
- **Layout**: Grid (3-4 columns), minimal padding (16px)
- **Metrics**: Large numbers, small labels
- **Charts**: Mini sparkline charts, progress bars

#### Job Offers Feed
- **Style**: List view, compact cards, information-dense
- **Layout**: Vertical list, minimal spacing (8px)
- **Quick Actions**: Small buttons (Accept/Reject) inline
- **Expiration Timer**: Prominent countdown badge

#### Earnings Dashboard
- **Style**: Tab-based (Today, Weekly, Monthly, All-Time)
- **Charts**: Line charts, bar charts, pie charts
- **Metrics**: Large numbers with trend indicators (↑↓)
- **Transactions**: Table view with filters

#### Map View
- **Style**: Split view (map + job list side-by-side)
- **Markers**: Small, professional, color-coded by status
- **Filters**: Sidebar with filters (service, distance, payout)
- **Info Windows**: Compact, data-focused

#### Job Management
- **Style**: Compact cards with quick actions
- **Status Updates**: Quick action buttons (Start, Complete, etc.)
- **Customer Info**: Collapsible sections
- **Job Details**: Tabbed interface (Details, Photos, Notes, Payment)

#### Availability Toggle
- **Style**: Large, prominent, top of dashboard
- **Design**: Switch with status indicator (Online/Offline)
- **Real-time**: Animated pulse when online
- **Earnings Ticker**: Live counter showing earnings while online

---

## Visual Design Differences

### Customer Experience

#### Layout
- **Spacing**: Generous (24px between sections, 16px padding)
- **Card Style**: Large, rounded (16px), soft shadows
- **Information Density**: Low (one main action per screen)
- **Navigation**: Bottom nav (4 items), large icons

#### Typography
- **Font Size**: Larger (16px body, 24px headlines)
- **Weight**: Softer (Regular body, Semi-Bold titles)
- **Line Height**: Generous (1.5x)

#### Colors
- **Background**: Pure white (#FFFFFF)
- **Primary Usage**: Softer, more approachable
- **Accent Colors**: Pastel service icons
- **Contrast**: Lower (easier on eyes)

#### Interactions
- **Animations**: Smooth, reassuring (300ms)
- **Feedback**: Positive, encouraging
- **Loading States**: Skeleton screens, friendly messages
- **Empty States**: Illustrations, helpful guidance

#### Icons
- **Style**: Outlined, friendly, colorful
- **Size**: Large (24-48px)
- **Usage**: Service icons, status indicators

---

### Professional Experience

#### Layout
- **Spacing**: Compact (16px between sections, 12px padding)
- **Card Style**: Smaller, less rounded (8px), subtle shadows
- **Information Density**: High (multiple actions, data points)
- **Navigation**: Bottom nav (5 items), compact icons

#### Typography
- **Font Size**: Smaller (14px body, 24px headlines)
- **Weight**: Stronger (Semi-Bold body, Bold titles)
- **Line Height**: Tighter (1.4x)

#### Colors
- **Background**: Light gray (#F3F4F6)
- **Primary Usage**: Stronger, more professional
- **Data Colors**: Vibrant for charts and metrics
- **Contrast**: Higher (better readability)

#### Interactions
- **Animations**: Quick, efficient (200ms)
- **Feedback**: Direct, actionable
- **Loading States**: Progress bars, data tables
- **Empty States**: Data-focused, actionable

#### Icons
- **Style**: Filled, professional, monochrome
- **Size**: Medium (20-24px)
- **Usage**: Status indicators, quick actions

---

## Component-Specific Designs

### Customer Components

#### Service Selection Card
```
┌─────────────────────────────┐
│  [Large Icon - 64px]        │
│                             │
│  Plumbing                   │
│  Fix leaks, installs       │
│                             │
│  $50 - $150                 │
└─────────────────────────────┘
- Rounded: 16px
- Padding: 24px
- Shadow: Soft (elevation 2)
- Background: White
- Icon: Large, colorful, friendly
```

#### Job Status Card
```
┌─────────────────────────────┐
│  🔧 Plumbing - Leaky Faucet │
│  ─────────────────────────  │
│  Status: In Progress        │
│  [Timeline: ●──●──●──○]     │
│                             │
│  Pro: John D. ⭐ 4.8        │
│  ETA: 15 minutes            │
│                             │
│  [View Details] [Message]   │
└─────────────────────────────┘
- Horizontal layout
- Status badge with color
- Timeline visualization
- Pro info with avatar
- Multiple action buttons
```

#### Booking Summary
```
┌─────────────────────────────┐
│  Booking Summary            │
│  ─────────────────────────  │
│                             │
│  Service: Plumbing          │
│  Task: Leaky Faucet         │
│  Location: 123 Main St      │
│  Time: ASAP                 │
│                             │
│  Base Fee:        $50.00    │
│  Diagnostic:      $25.00    │
│  ─────────────────────────  │
│  Total:           $75.00    │
│                             │
│  [Confirm Booking]          │
└─────────────────────────────┘
- Clear pricing breakdown
- Large confirm button
- Friendly, reassuring
```

---

### Professional Components

#### Job Offer Card
```
┌─────────────────────────────┐
│  Plumbing │ Leaky Faucet    │
│  ─────────────────────────  │
│  📍 2.3 miles │ $75.00      │
│  ⏰ Expires in 28:15        │
│                             │
│  Customer: Jane S. ⭐ 4.9   │
│  Location: 123 Main St      │
│  Time: ASAP                 │
│                             │
│  [Accept] [View Details]    │
└─────────────────────────────┘
- Compact, information-dense
- Expiration timer prominent
- Distance and payout visible
- Quick action buttons
```

#### Earnings Card
```
┌─────────────────────────────┐
│  Today's Earnings           │
│  ─────────────────────────  │
│                             │
│  $247.50                    │
│  ↑ 15% from yesterday       │
│                             │
│  [Chart: Mini sparkline]    │
│                             │
│  Jobs: 3 │ Avg: $82.50      │
└─────────────────────────────┘
- Large number, small labels
- Trend indicator
- Mini chart
- Compact metrics
```

#### Active Job Card
```
┌─────────────────────────────┐
│  #1234 │ Plumbing           │
│  ─────────────────────────  │
│  Customer: Jane S.          │
│  Status: In Progress        │
│  Location: 2.3 miles        │
│                             │
│  [Start] [Complete] [Call]  │
└─────────────────────────────┘
- Job ID prominent
- Status badge
- Quick actions (all visible)
- Compact layout
```

---

## Animation & Interaction Patterns

### Customer Animations
- **Page Transitions**: Slide (300ms, ease-out)
- **Card Tap**: Scale (1.05x, 150ms)
- **Status Updates**: Smooth fade + slide (300ms)
- **Loading**: Skeleton screens with shimmer
- **Success**: Celebration animation (checkmark + scale)

### Professional Animations
- **Page Transitions**: Fade (200ms, ease-in-out)
- **Card Tap**: Subtle lift (elevation change, 100ms)
- **Status Updates**: Quick fade (200ms)
- **Loading**: Progress bars, spinners
- **Success**: Checkmark (150ms, no celebration)

---

## Navigation Patterns

### Customer Navigation
```
Bottom Navigation (4 items):
┌─────────────────────────────┐
│  🏠 Home │ 📋 Jobs │ 📜 History │ 👤 Profile │
└─────────────────────────────┘
- Large icons (24px)
- Labels below icons
- Generous spacing
- Current page highlighted
```

### Professional Navigation
```
Bottom Navigation (5 items):
┌─────────────────────────────────────────┐
│  📊 Dashboard │ 💼 Jobs │ 🗺️ Map │ 💬 Messages │ 👤 Account │
└─────────────────────────────────────────┘
- Compact icons (20px)
- Labels below icons
- Tighter spacing
- Current page highlighted
```

---

## Responsive Design

### Customer
- **Mobile First**: Optimized for mobile
- **Breakpoints**: Single column until tablet
- **Touch Targets**: Large (min 44x44px)
- **Gestures**: Swipe to dismiss, pull to refresh

### Professional
- **Tablet Support**: Optimized for larger screens
- **Breakpoints**: Multi-column on tablets
- **Touch Targets**: Standard (min 40x40px)
- **Gestures**: Quick actions, swipe for status updates

---

## Accessibility

### Both Experiences
- **Color Contrast**: WCAG AA compliant (4.5:1)
- **Touch Targets**: Minimum 40x40px
- **Text Size**: Scalable (supports system font size)
- **Screen Readers**: Proper labels and semantics
- **Keyboard Navigation**: Full keyboard support

---

## Design Tokens

### Customer Tokens
```dart
// Colors
static const primaryColor = Color(0xFF006B6B);
static const secondaryColor = Color(0xFFFF6B35);
static const backgroundColor = Color(0xFFFFFFFF);
static const surfaceColor = Color(0xFFF9FAFB);

// Spacing
static const spacingXS = 4.0;
static const spacingS = 8.0;
static const spacingM = 16.0;
static const spacingL = 24.0;
static const spacingXL = 32.0;

// Border Radius
static const radiusS = 8.0;
static const radiusM = 12.0;
static const radiusL = 16.0;
static const radiusXL = 24.0;

// Shadows
static const shadowS = BoxShadow(...); // Soft, subtle
static const shadowM = BoxShadow(...); // Medium, friendly
```

### Professional Tokens
```dart
// Colors
static const primaryColor = Color(0xFF006B6B); // Same
static const secondaryColor = Color(0xFF6366F1); // Different
static const backgroundColor = Color(0xFFF3F4F6); // Darker
static const surfaceColor = Color(0xFFFFFFFF);

// Spacing
static const spacingXS = 4.0;
static const spacingS = 8.0;
static const spacingM = 12.0; // Tighter
static const spacingL = 16.0; // Tighter
static const spacingXL = 24.0;

// Border Radius
static const radiusS = 4.0; // Smaller
static const radiusM = 8.0; // Smaller
static const radiusL = 12.0; // Smaller

// Shadows
static const shadowS = BoxShadow(...); // Subtle, professional
static const shadowM = BoxShadow(...); // Minimal
```

---

## Implementation Strategy

### Phase 1: Design System Foundation
1. ✅ Define color palette (Deep Teal + Warm Orange)
2. ✅ Create design tokens for both experiences
3. ✅ Set up typography system
4. ✅ Define spacing and layout grids

### Phase 2: Component Library
1. Customer components (cards, buttons, forms)
2. Professional components (data cards, metrics, charts)
3. Shared components (navigation, loading states)

### Phase 3: Screen Implementation
1. Customer screens (onboarding, booking, tracking)
2. Professional screens (dashboard, jobs, earnings)

---

## Key Differentiators Summary

| Aspect | Customer | Professional |
|--------|----------|--------------|
| **Primary Color** | Deep Teal (#006B6B) | Deep Teal (#006B6B) |
| **Secondary Color** | Warm Orange (#FF6B35) | Indigo (#6366F1) |
| **Background** | Pure White (#FFFFFF) | Light Gray (#F3F4F6) |
| **Spacing** | Generous (24px) | Compact (16px) |
| **Border Radius** | Large (16px) | Small (8px) |
| **Typography** | Larger (16px) | Smaller (14px) |
| **Information Density** | Low | High |
| **Animations** | Smooth (300ms) | Quick (200ms) |
| **Icons** | Large, colorful | Medium, monochrome |
| **Focus** | Simple, friendly | Efficient, data-driven |

---

**Recommendation**: Use Deep Teal (#006B6B) as primary with Warm Orange (#FF6B35) for customer CTAs, and Indigo (#6366F1) for professional data visualization.

**Next Steps**: 
1. Review and approve color palette
2. Create component designs in Figma/sketch
3. Implement design tokens
4. Build component library

