# Customer Panel — Frontend User Stories

**App:** laundryApp (Flutter, Material, `flutter_riverpod`, `go_router`)
**Scope:** Pure frontend/UI behavior of the customer experience — screens, widgets, navigation transitions, gestures, and visual states. Business/backend framing is intentionally left out here; see `customer-role-user-stories.md` for the functional/business version of these stories.

> Every story is written from what renders on screen and how it responds to interaction — component names, navigation transitions, and UI states (default/empty/loading/disabled) are called out explicitly since this is a frontend-engineering-oriented document.

---

## Epic 1 — Navigation Shell & Tab Bar

### FE-1.1 Switch between primary sections via bottom tabs
**As a** customer,
**I want** a persistent bottom tab bar with Home, Explore, Orders, Chat, and Profile,
**so that** I can jump between the app's main sections without losing my place.

- **Frontend behavior:** `StatefulShellRoute.indexedStack` (`lib/core/router/app_router.dart`, `_CustomerTabShell`) preserves each tab's scroll position/state when switching. Tab bar rendered by `lib/widgets/bottom_tab_bar.dart` using `kCustomerTabs` (icon + label per destination).
- **UI states:** Active tab shows a highlighted icon/label; inactive tabs are muted. Tapping a gated tab (Orders/Chat/Profile) while unauthenticated intercepts the switch and pushes `/login` instead of changing the selected index.

### FE-1.2 Navigate into full-screen flows without losing the tab bar's "home"
**As a** customer,
**I want** flows like shop detail, cart, schedule, checkout, tracking, and notifications to open as full-screen pushes over the tab shell,
**so that** I get an uncluttered, focused screen for each step, with a clear back action to return.

- **Frontend behavior:** Routes `/detail`, `/cart`, `/schedule`, `/checkout`, `/track`, `/notifs` are top-level siblings of the shell in `app_router.dart`, so they render without the bottom tab bar and use a standard `AppBar` back arrow.
- **UI states:** Standard push transition (slide-in) on entry; `context.go('/track')` on order placement **replaces** the navigation stack instead of pushing, so the back arrow from Track cannot return to a completed Checkout.

---

## Epic 2 — Guest Gating (Frontend Interaction Pattern)

### FE-2.1 See a contextual message when redirected to login
**As a** guest tapping a gated action,
**I want** the login screen to explain why I landed there,
**so that** the interruption feels purposeful rather than jarring.

- **Frontend behavior:** `gateGuest()` (`lib/state/auth_state.dart`) sets a `reason` string and stashes `redirectPath`/`redirectExtra` before calling `context.push('/login')`. `lib/screens/login/login_screen.dart` reads the reason and renders it in the header banner (e.g., "Log in to see your orders.").
- **UI states:** Reason banner only appears when a reason is set; default login (typed URL/tab-less entry) shows no banner.

### FE-2.2 Resume my original action after logging in
**As a** guest who just logged in from a gated prompt,
**I want** to land exactly where I was trying to go (not back at Home),
**so that** logging in doesn't cost me the progress I'd already made (e.g., a shop I'd selected).

- **Frontend behavior:** On successful login, `AuthNotifier` reads `redirectPath`/`redirectExtra` and issues `context.go(redirectPath, extra: redirectExtra)` instead of the default `roleHomePath(role)`.

### FE-2.3 See fewer personalized UI elements while browsing as a guest
**As a** guest,
**I want** the interface to simply omit elements that require an identity (pickup-location row, active-order banner) rather than showing broken/empty versions of them,
**so that** the guest experience feels intentional, not like a degraded logged-in view.

- **Frontend behavior:** Conditional widget rendering in `home_screen.dart` (`_Header`, active-order banner) checked against `authProvider` role — entire widget subtree is omitted (not disabled/greyed) when role is guest.

---

## Epic 3 — Home Screen Components

### FE-3.1 View my active order status as an animated banner
**As a** customer with an order in progress,
**I want** a banner with a subtle pulsing icon animation summarizing my order's status,
**so that** the ongoing order visually draws attention without being intrusive.

- **Files:** `lib/screens/home/widgets/active_order_banner.dart`
- **Interaction:** Tapping the banner navigates to `/track`.

### FE-3.2 Scroll a horizontal offers carousel
**As a** customer,
**I want** a horizontally-scrollable row of offer cards,
**so that** I can browse promotions without them consuming vertical space.

- **Files:** `lib/screens/home/widgets/offer_card.dart`
- **Interaction:** Each card has a "Claim" button that is itself a distinct tap target from the card body; claiming routes through the guest gate if unauthenticated.

### FE-3.3 Expand/collapse the services grid
**As a** customer,
**I want** a "See all / Show less" toggle on the services grid,
**so that** I can preview a few services by default and expand only if I want the full list.

- **Files:** `lib/screens/home/widgets/service_grid.dart`, data: `kServiceItems`
- **UI states:** Collapsed (default, partial grid) vs. expanded (full grid); toggle label/icon flips between the two states.

### FE-3.4 Scroll a horizontal nearby-shops carousel
**As a** customer,
**I want** shop cards in a horizontally-scrollable row with image, name, rating, and distance,
**so that** I can quickly compare nearby options without leaving Home.

- **Files:** `lib/screens/home/widgets/shop_card.dart`, data: `kShops`
- **Interaction:** Tapping a card pushes `/detail` with the tapped `Shop` object passed as router `extra` (no re-fetch — data flows directly through navigation).

---

## Epic 4 — Search Screen Components

### FE-4.1 Get live-filtered results as I type
**As a** customer,
**I want** the shop list to filter as I type in the search field,
**so that** I get immediate feedback without pressing a separate "search" button.

- **Files:** `lib/screens/search/search_screen.dart`, `lib/state/search_state.dart`
- **Frontend behavior:** Text field's `onChanged` updates a Riverpod state notifier; `filteredShops()` recomputes and the `ListView` rebuilds reactively.

### FE-4.2 Select one filter chip at a time
**As a** customer,
**I want** the filter row (Nearby, Top rated, Under TZS 13,000, 24h, Open now) to behave as single-select chips,
**so that** the filtering logic stays predictable — one active criterion at a time.

- **UI states:** Selected chip has a distinct filled/highlighted style; selecting a new chip visually deselects the previous one.

### FE-4.3 See a friendly empty state
**As a** customer whose search/filter combination matches nothing,
**I want** a clear empty-state message instead of a blank screen,
**so that** I know to adjust my query rather than assume the app is broken.

- **Files:** `lib/screens/search/search_screen.dart`

---

## Epic 5 — Shop Detail Components

### FE-5.1 Toggle a favorite heart icon overlaying the hero image
**As a** customer,
**I want** a heart icon button positioned over the shop's hero photo,
**so that** I can favorite/unfavorite without scrolling to a separate control.

- **Files:** `lib/screens/shop_detail/shop_detail_screen.dart`
- **UI states:** Filled heart (favorited) vs. outline heart (not favorited), toggled instantly on tap via `profileProvider.toggleFav`.

### FE-5.2 Increment item quantity with a "+" tap and see the bottom bar update live
**As a** customer,
**I want** the bottom CTA bar's subtotal to update immediately as I tap "+" on menu items,
**so that** I always see an accurate running total without navigating away.

- **Files:** `lib/screens/shop_detail/shop_detail_screen.dart`, `lib/state/cart_state.dart`
- **Frontend behavior:** Reactive Riverpod cart provider drives both the menu-row quantity badge and the sticky bottom bar's subtotal/"View basket" button in the same rebuild.

---

## Epic 6 — Cart Screen Components

### FE-6.1 Adjust quantity with a stepper control
**As a** customer,
**I want** a −/qty/+ stepper on each cart line item,
**so that** I can fine-tune quantities directly in the cart, not just from the shop menu.

- **Files:** `lib/screens/cart/cart_screen.dart`
- **UI states:** Items automatically disappear from the list when their quantity is stepped down to 0 (no separate "remove" button/confirmation).

### FE-6.2 See order summary math update live
**As a** customer,
**I want** the Subtotal/Delivery/Total summary card to recalculate immediately as I change quantities,
**so that** I always know what I'll be charged before proceeding.

- **Files:** `lib/screens/cart/cart_screen.dart`, `lib/state/cart_state.dart`

---

## Epic 7 — Schedule Screen Components

### FE-7.1 Pick a day from a horizontal chip strip
**As a** customer,
**I want** a 7-day horizontal scrollable chip picker,
**so that** I can select a pickup day with a single tap, in a compact space.

- **Files:** `lib/screens/schedule/schedule_screen.dart`, data: `kDays`

### FE-7.2 Pick a time window from a 2×2 grid
**As a** customer,
**I want** the four time-slot options (8–10 AM, 10–12 PM, 2–4 PM, 6–8 PM) laid out as a 2×2 tappable grid,
**so that** I can scan and select a slot without scrolling.

- **Files:** `lib/screens/schedule/schedule_screen.dart`, data: `kTimeSlots`
- **UI states:** Selected slot is visually highlighted (border/fill change); only one slot selectable at a time.

### FE-7.3 Select a saved address via radio cards
**As a** customer,
**I want** my saved addresses shown as selectable radio-style cards,
**so that** I can pick a pickup location clearly, with the current selection always visible.

- **Files:** `lib/screens/schedule/schedule_screen.dart` (`RadioOptionCard`), data: `kAddresses`

---

## Epic 8 — Checkout Screen Components

### FE-8.1 Apply a promo code and see the discount reflected instantly
**As a** customer,
**I want** to type a code and tap "Apply" to see a discount line appear in the order summary,
**so that** I get immediate confirmation the code "worked" before placing the order.

- **Files:** `lib/screens/checkout/checkout_screen.dart`, `lib/state/checkout_state.dart` (`discountFor()`)
- **UI states:** Discount line item only appears in the summary after a code is applied; disappears if the field is cleared.

### FE-8.2 Choose a payment method from radio cards
**As a** customer,
**I want** Visa card / Apple Pay / Cash on delivery presented as selectable radio cards (consistent with the address picker pattern),
**so that** the interaction feels consistent with the rest of the booking flow.

- **Files:** `lib/screens/checkout/checkout_screen.dart` (`RadioOptionCard`), data: `kPayments`

---

## Epic 9 — Order Tracking Screen Components

### FE-9.1 See a vertical step-tracker with timestamps
**As a** customer,
**I want** a vertical timeline (Picked up → Sorted → Washing → On the way) with a status pill at the top,
**so that** I can see both my current status and the full journey at a glance.

- **Files:** `lib/screens/track/track_order_screen.dart`, `lib/state/tracking_state.dart`, data: `kTrackSteps`
- **UI states:** Completed steps styled differently from the pending/current step; status pill text/color reflects `step` (0–3).

### FE-9.2 Contact my driver via icon buttons on their card
**As a** customer,
**I want** chat and phone icon buttons directly on the driver's info card,
**so that** I can reach out without navigating to a separate "contact" screen.

- **Files:** `lib/screens/track/track_order_screen.dart`
- **Frontend behavior:** Chat icon triggers a tab switch to `/chat` (reuses the existing shell, not a new push). Phone icon is present but wired to no handler (visually identical to chat icon, but non-functional).

---

## Epic 10 — Orders Screen Components

### FE-10.1 Toggle between Active and Completed with a segmented control
**As a** customer,
**I want** an Active/Completed segmented toggle at the top of Orders,
**so that** I can switch views without a page reload or separate screen.

- **Files:** `lib/screens/orders/orders_screen.dart`, `lib/state/orders_tab_state.dart`
- **UI states:** Selected segment visually distinct (filled/underlined); list content swaps instantly on toggle.

---

## Epic 11 — Chat Screen Components

### FE-11.1 Send a message via button tap or Enter key
**As a** customer,
**I want** to submit a chat message either by tapping the send icon or pressing Enter,
**so that** the input feels natural regardless of how I prefer to submit text.

- **Files:** `lib/screens/chat/chat_screen.dart`, `lib/state/chat_state.dart`
- **Frontend behavior:** New messages append to the bottom of the thread and the list auto-scrolls to reveal them; input field clears after send.

---

## Epic 12 — Notifications Screen Components

### FE-12.1 Scan notifications with icon-coded categories
**As a** customer,
**I want** each notification to show a distinct icon/initial by category (status, promo, driver, review-prompt),
**so that** I can visually scan for the type of update I care about without reading every line.

- **Files:** `lib/screens/notifications/notifications_screen.dart`, data: `kNotifications`
- **UI states:** Static list, no read/unread visual distinction, no swipe-to-dismiss or tap-through interaction implemented.

---

## Epic 13 — Profile Screen Components

### FE-13.1 Edit an address inline without leaving the page
**As a** customer,
**I want** tapping "Edit" on a saved address to swap that row into an editable state in place,
**so that** I don't get pulled into a separate edit screen for a small change.

- **Files:** `lib/screens/profile/profile_screen.dart` (`_AddressRow`)
- **UI states:** Default (label + "Edit" link) → editing (text field + "Use current location" link + Cancel/Save buttons). "Use current location" currently only shows a "coming soon" snackbar.

### FE-13.2 Toggle preferences with switches
**As a** customer,
**I want** Push notifications / Eco detergent / Contactless pickup as toggle switches,
**so that** I can flip a setting with a single tap and see instant visual confirmation.

- **Files:** `lib/screens/profile/profile_screen.dart`, `lib/state/profile_state.dart` (`togglePref`)

### FE-13.3 See stat tiles summarizing my account
**As a** customer,
**I want** compact stat tiles ("24 Orders", "3 Saved shops") near the top of my profile,
**so that** I get a quick sense of my activity without navigating elsewhere.

- **Files:** `lib/screens/profile/profile_screen.dart`

---

## Frontend-Specific Notes & Gaps

These are UI/interaction-layer observations, distinct from the backend gaps already tracked in `customer-role-user-stories.md`:

1. **No loading states anywhere** — because all data is synchronous mock data, no screen implements a loading spinner/skeleton. If real network calls are introduced later, every list/detail screen will need loading + error states designed.
2. **No pull-to-refresh** on Home, Search, Orders, or Notifications lists.
3. **No optimistic-update rollback pattern needed yet** (everything is local state), but the cart/profile update patterns (instant local mutation) will need error-handling UI once backed by a real API.
4. **Single empty-state implementation** (Search only) — Orders, Notifications, and Chat have no defined empty-state UI if their mock lists were ever empty.
5. **Accessibility:** no explicit `Semantics` labels found on icon-only buttons (favorite heart, driver call/chat icons, notification bell) — worth a dedicated accessibility pass.
6. **Tracking screen's "Demo: advance status" button** is a dev/demo affordance left in the production widget tree — should be removed or feature-flagged before release.

---

*Document generated from a full frontend/component-level analysis of `laundryApp/lib/screens/`, `lib/widgets/`, and `lib/state/` on 2026-08-13. Companion to `customer-role-user-stories.md` (business/functional framing).*
