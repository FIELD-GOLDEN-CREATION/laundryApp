# Customer Role — User Story Document

**App:** laundryApp (Flutter, `lib/`)
**Scope:** All functionality available to the `UserRole.customer` (and, where noted, unauthenticated `UserRole.guest`) experience.
**Source of truth:** `lib/core/router/app_router.dart`, `lib/screens/{home,search,shop_detail,cart,schedule,checkout,track,orders,chat,notifications,profile,login}/`, `lib/state/*_state.dart`, `lib/data/mock_data.dart`

> **Context note:** This build has no backend — auth, cart, orders, chat, and tracking are all in-memory mock state (`lib/state/*_state.dart`, seeded from `lib/data/mock_data.dart`). Every story below reflects what the customer can actually do in the current UI, with a "Status" line noting where behavior is simulated rather than persisted.

---

## Epic 1 — Guest Browsing & Authentication

### US-1.1 Browse as a guest
**As a** first-time visitor who hasn't logged in,
**I want to** browse the home feed and search for shops without creating an account,
**so that** I can evaluate the service before committing to sign up.

- **Acceptance criteria:**
  - Visiting the app lands on `/home` with no login required.
  - Home and Search (`/search`) tabs are fully browsable while unauthenticated.
  - Personalized elements (pickup-location row, active-order banner) are hidden for guests.
- **Files:** `lib/screens/home/home_screen.dart`, `lib/screens/search/search_screen.dart`, `lib/core/router/app_router.dart`
- **Status:** Implemented (mock data only).

### US-1.2 Get prompted to log in at the right moment
**As a** guest,
**I want to** be asked to log in only when I try to do something that requires an account (open a shop, claim an offer, view orders/chat/profile, place an order),
**so that** I'm not forced through a signup wall before I've seen any value.

- **Acceptance criteria:**
  - Tapping a gated action (Orders tab, Chat tab, Profile tab, shop card, "Claim" on an offer, "Place order") redirects to `/login`.
  - The login screen shows a contextual reason message explaining why (e.g., "Log in to see your orders.").
  - After successful login, the app resumes the original action instead of dropping the user back at Home.
- **Files:** `lib/state/auth_state.dart` (`gateGuest`, `redirectPath`/`redirectExtra`), `lib/screens/login/login_screen.dart`
- **Status:** Implemented.

### US-1.3 Log in with an account
**As a** returning customer,
**I want to** enter my email and password to log in,
**so that** I can access my orders, chat, and profile.

- **Acceptance criteria:**
  - Email + password fields, password obscured by default.
  - Invalid credentials show an inline error banner.
  - Successful login routes to the customer home and restores any pending gated action.
- **Files:** `lib/screens/login/login_screen.dart`, `lib/state/login_form_state.dart`, `lib/state/auth_state.dart`
- **Status:** Implemented against a hardcoded in-memory account map (`user@gmail.com` / `user04` → customer). No real authentication/session/persistence.

### US-1.4 Continue browsing without logging in
**As a** guest who isn't ready to commit,
**I want to** dismiss the login prompt and keep browsing,
**so that** I retain control over when I create an account.

- **Acceptance criteria:** Login screen has a "Keep browsing as guest" link that returns to Home without authenticating.
- **Files:** `lib/screens/login/login_screen.dart`
- **Status:** Implemented.

### US-1.5 Log out
**As a** logged-in customer,
**I want to** log out from my profile,
**so that** I can end my session or switch accounts.

- **Acceptance criteria:** "Log out" button on Profile clears auth state and returns to `/home` as a guest.
- **Files:** `lib/screens/profile/profile_screen.dart`, `lib/state/auth_state.dart`
- **Status:** Implemented (clears in-memory state only).

---

## Epic 2 — Home Dashboard

### US-2.1 See my active order at a glance
**As a** customer with a laundry order in progress,
**I want to** see a live status banner on my home screen,
**so that** I don't have to dig into order history to check progress.

- **Acceptance criteria:** Authenticated home shows an animated banner (e.g., "Order #LD-2481 is being washed / Back at your door by Thu, 6:00 PM") that navigates to Track (`/track`) when tapped. Hidden for guests.
- **Files:** `lib/screens/home/widgets/active_order_banner.dart`, `lib/screens/home/home_screen.dart`
- **Status:** Implemented (mock order, not derived from an actually-placed order).

### US-2.2 Manage my pickup location from the home header
**As a** customer,
**I want to** see and edit my current pickup location at the top of Home,
**so that** nearby shop results and delivery estimates reflect where I am.

- **Acceptance criteria:** Header shows the current address (authenticated only) with an edit affordance.
- **Files:** `lib/screens/home/home_screen.dart` (`_Header`)
- **Status:** UI present; hidden entirely for guests.

### US-2.3 See notifications from the home bell
**As a** customer,
**I want to** tap a bell icon on Home to see my notifications, with a badge indicating unread items,
**so that** I stay aware of order and promo updates without hunting for them.

- **Files:** `lib/screens/home/home_screen.dart`, `lib/screens/notifications/notifications_screen.dart`
- **Status:** Implemented (badge dot is static, not a real unread count).

### US-2.4 Browse promotional offers
**As a** customer,
**I want to** scroll a "Just for you" carousel of offers and claim one,
**so that** I can take advantage of discounts relevant to me.

- **Acceptance criteria:** Horizontal offer cards with a "Claim" button; tapping claim (as a guest) triggers the login gate, then proceeds to shop detail.
- **Files:** `lib/screens/home/widgets/offer_card.dart`, `lib/data/mock_data.dart` (`kOffers`)
- **Status:** Implemented (mock offers).

### US-2.5 Browse services by category
**As a** customer,
**I want to** see a grid of service types (Wash & Fold, Ironing, Dry Clean, Carpets, Shoe Care, Curtains, Leather & Suede, Duvets & Bedding) and expand/collapse the list,
**so that** I can quickly find the kind of service I need.

- **Files:** `lib/screens/home/widgets/service_grid.dart`, `lib/data/mock_data.dart` (`kServiceItems`)
- **Status:** Implemented; service tiles are informational (not individually deep-linked to filtered search).

### US-2.6 Discover nearby laundry shops
**As a** customer,
**I want to** scroll a "Nearby shops" carousel from Home,
**so that** I can quickly jump into a shop I recognize or that's close by.

- **Acceptance criteria:** Tapping a shop card is gated for guests; otherwise opens shop detail (`/detail`) with the selected shop's data.
- **Files:** `lib/screens/home/widgets/shop_card.dart`, `lib/data/mock_data.dart` (`kShops`)
- **Status:** Implemented (mock shop list).

---

## Epic 3 — Search & Discovery

### US-3.1 Search shops by name or service
**As a** customer,
**I want to** type a query to filter shops by name or the services they offer,
**so that** I can find a specific shop or type of service quickly.

- **Files:** `lib/screens/search/search_screen.dart`, `lib/state/search_state.dart`
- **Status:** Implemented, client-side filter over mock data.

### US-3.2 Filter and sort shop results
**As a** customer,
**I want to** apply a single filter (Nearby, Top rated, Under TZS 13,000, 24h, Open now) to the shop list,
**so that** I can narrow results to what matters to me right now.

- **Acceptance criteria:** Filter chips are single-select; selecting one both filters and sorts (`filteredShops()`), and the result count updates ("X shops near 12 Chole Road, Masaki").
- **Files:** `lib/state/search_state.dart`, `lib/data/mock_data.dart` (`kFilterOptions`)
- **Status:** Implemented.

### US-3.3 See an empty state when nothing matches
**As a** customer,
**I want to** see a clear message when my search/filter returns no shops,
**so that** I understand the app isn't broken and can adjust my query.

- **Files:** `lib/screens/search/search_screen.dart`
- **Status:** Implemented.

---

## Epic 4 — Shop Detail & Ordering

### US-4.1 View a shop's profile
**As a** customer,
**I want to** see a shop's photo, name, rating, review count, distance, hours, feature badges, and description,
**so that** I can decide whether to order from them.

- **Files:** `lib/screens/shop_detail/shop_detail_screen.dart`
- **Status:** Implemented (mock shop detail).

### US-4.2 Favorite a shop
**As a** customer,
**I want to** tap a heart icon on a shop's page to save it as a favorite,
**so that** I can find it again easily later.

- **Files:** `lib/screens/shop_detail/shop_detail_screen.dart`, `lib/state/profile_state.dart` (`toggleFav`)
- **Status:** Implemented in-memory; reflected in Profile's "Saved shops" stat tile, not persisted across sessions.

### US-4.3 Browse a shop's price list and add items to cart
**As a** customer,
**I want to** see itemized services with unit descriptions and prices, and tap "+" to add items,
**so that** I can build an order of exactly what I need.

- **Acceptance criteria:** Tapping "+" increments that item's quantity in the cart; a bottom bar shows a running subtotal and a "View basket" CTA.
- **Files:** `lib/screens/shop_detail/shop_detail_screen.dart`, `lib/state/cart_state.dart`, `lib/data/mock_data.dart` (`kMenuItems`)
- **Status:** Implemented (mock menu, in-memory cart).

### US-4.4 Adjust item quantities in my cart
**As a** customer,
**I want to** increase, decrease, or remove items in my basket,
**so that** my order matches what I actually want before I schedule it.

- **Acceptance criteria:** Stepper (−/qty/+) per line item; items with qty 0 drop off the list; "+ Add more items" returns to the shop menu; order summary shows Subtotal, delivery fee ("Free"), and Total.
- **Files:** `lib/screens/cart/cart_screen.dart`, `lib/state/cart_state.dart`
- **Status:** Implemented.

---

## Epic 5 — Scheduling & Checkout

### US-5.1 Schedule a pickup
**As a** customer,
**I want to** choose a pickup address, day, and time window, plus leave a note for the driver,
**so that** my laundry is collected when and where it's convenient for me.

- **Acceptance criteria:** Saved-address picker (radio list), 7-day horizontal chip picker, 2×2 time-slot grid (8–10 AM, 10–12 PM, 2–4 PM, 6–8 PM), free-text driver note field.
- **Files:** `lib/screens/schedule/schedule_screen.dart`, `lib/state/schedule_state.dart`, `lib/data/mock_data.dart` (`kAddresses`, `kDays`, `kTimeSlots`)
- **Status:** Implemented (mock addresses).

### US-5.2 Review and pay for my order
**As a** customer,
**I want to** review my pickup details and order summary, choose a payment method, and optionally apply a promo code,
**so that** I can confirm everything is correct before committing to pay.

- **Acceptance criteria:** Summary card (pickup day/time, address, item count); payment method radio list (Card, Mobile Money, Cash on delivery) — "Card" opens a picker of the customer's saved cards with a "+ Link a new card" shortcut, "Mobile Money" opens a picker of Tanzanian providers (Mixx By Yas, M-Pesa, Airtel Money, HaloPesa); promo code field + "Apply" button applies a discount; summary shows Subtotal, Discount, Delivery, Total.
- **Files:** `lib/screens/checkout/checkout_screen.dart`, `lib/state/checkout_state.dart`, `lib/state/saved_cards_state.dart`, `lib/data/mock_data.dart` (`kMobileMoneyProviders`)
- **Status:** Implemented (promo discount logic is a mock flat-rate calculation, not validated against real codes).

### US-5.3 Place my order
**As a** customer,
**I want to** tap "Place order" to submit my scheduled pickup,
**so that** the shop can start processing my laundry.

- **Acceptance criteria:** Action is gated for guests; on success, navigates to Order Tracking (`/track`), replacing the checkout screen so the user can't navigate back into it.
- **Files:** `lib/screens/checkout/checkout_screen.dart`, `lib/state/auth_state.dart`
- **Status:** ⚠️ Simulated only — no order object is actually created or added to order history; there is no backend to persist the order. This is a known functional gap (see "Gaps" below).

---

## Epic 6 — Order Tracking & History

### US-6.1 Track my order's live status
**As a** customer,
**I want to** see a step-by-step timeline of my order's progress (Picked up → Sorted → Washing → On the way) with timestamps,
**so that** I know exactly where my laundry is in the process.

- **Files:** `lib/screens/track/track_order_screen.dart`, `lib/state/tracking_state.dart`, `lib/data/mock_data.dart` (`kTrackSteps`)
- **Status:** Implemented (map is a placeholder graphic; status only advances via the demo button, not real GPS/backend events).

### US-6.2 Contact my driver
**As a** customer,
**I want to** message or call my assigned driver from the tracking screen,
**so that** I can coordinate pickup/delivery details directly.

- **Acceptance criteria:** Driver card shows name, rating, avatar; chat icon opens the Chat tab; phone icon is present.
- **Files:** `lib/screens/track/track_order_screen.dart`
- **Status:** Chat button works (switches to Chat tab). ⚠️ Phone/call button is a non-functional placeholder — known gap.

### US-6.3 View my order history
**As a** customer,
**I want to** see my active and completed orders in separate lists,
**so that** I can check on current laundry or look back at past orders.

- **Acceptance criteria:** Segmented Active/Completed toggle; each order card shows order ID, status/type, and total; tapping an order opens tracking.
- **Files:** `lib/screens/orders/orders_screen.dart`, `lib/state/orders_tab_state.dart`, `lib/data/mock_data.dart` (`kActiveOrders`, `kCompletedOrders`)
- **Status:** Implemented against static mock lists (not updated by newly "placed" orders — see gap below).

---

## Epic 7 — Communication & Notifications

### US-7.1 Chat with my laundry shop
**As a** customer,
**I want to** send and read messages in a chat thread with my shop,
**so that** I can ask questions or give special instructions.

- **Acceptance criteria:** Single conversation thread, seeded with prior messages; typing and tapping send (or pressing enter) appends a new message bubble.
- **Files:** `lib/screens/chat/chat_screen.dart`, `lib/state/chat_state.dart`, `lib/data/mock_data.dart` (`kInitialChatMessages`)
- **Status:** ⚠️ Local-only — messages aren't sent anywhere and the shop never replies to new messages (known gap).

### US-7.2 View my notifications
**As a** customer,
**I want to** see a list of status updates, promos, driver updates, and review prompts,
**so that** I stay informed without actively checking the app.

- **Acceptance criteria:** Each notification shows an icon/initial, title, body, and relative timestamp; reachable from the bell icon on Home and Profile.
- **Files:** `lib/screens/notifications/notifications_screen.dart`, `lib/data/mock_data.dart` (`kNotifications`)
- **Status:** Implemented as a read-only list. ⚠️ No mark-as-read, delete, or filter actions exist — known gap.

---

## Epic 8 — Profile & Account Management

### US-8.1 View my profile summary
**As a** customer,
**I want to** see my name, email, avatar, total order count, and saved-shop count,
**so that** I have a quick snapshot of my account.

- **Files:** `lib/screens/profile/profile_screen.dart`
- **Status:** Implemented with static/mock stat values.

### US-8.2 Manage my saved addresses
**As a** customer,
**I want to** edit my saved pickup addresses inline,
**so that** my laundry is always collected from the right place.

- **Acceptance criteria:** Tapping "Edit" on an address reveals a text field, a "Use current location" link, and Cancel/Save buttons.
- **Files:** `lib/screens/profile/profile_screen.dart` (`_AddressRow`), `lib/state/profile_state.dart` (`updateAddressLine`)
- **Status:** Editing/saving works in-memory. ⚠️ "Use current location" is a placeholder ("coming soon" snackbar) — known gap.

### US-8.3 Set my preferences
**As a** customer,
**I want to** toggle Push notifications, Eco detergent by default, and Contactless pickup,
**so that** the service matches how I like my laundry handled.

- **Files:** `lib/screens/profile/profile_screen.dart`, `lib/state/profile_state.dart` (`togglePref`)
- **Status:** Implemented (in-memory only; no push notification system actually wired up).

### US-8.4 Manage my saved payment cards
**As a** customer,
**I want to** link a debit/credit card by entering the holder name, card number, expiry, and CVV, and see it listed with its network automatically identified,
**so that** I can pay faster at checkout without re-entering card details every time.

- **Acceptance criteria:** A "Saved cards" section lists linked cards (network badge, masked number, holder name, expiry) with a "Remove" action; "+ Link a card" opens a form that validates the inputs and classifies the card as Visa, Mastercard, or a generic bank card from its number as the customer types; a newly linked card is immediately available in Checkout's Card picker (see US-5.2).
- **Files:** `lib/screens/profile/profile_screen.dart`, `lib/widgets/link_card_sheet.dart`, `lib/widgets/card_brand_tag.dart`, `lib/models/saved_card.dart`, `lib/state/saved_cards_state.dart`
- **Status:** Implemented in-memory only — no real card validation, tokenization, or PCI-compliant processing; this is a mock payment-method store, not a payment gateway integration.

---

## Cross-Cutting: Guest vs. Customer Access Summary

| Area | Guest | Customer |
|---|---|---|
| Home / Search | ✅ Full browse | ✅ Full browse + personalization |
| Shop detail / add to cart | 🔒 Gated → login | ✅ |
| Cart / Schedule / Checkout | 🔒 Gated at checkout | ✅ |
| Orders tab | 🔒 Gated | ✅ |
| Chat tab | 🔒 Gated | ✅ |
| Profile tab | 🔒 Gated | ✅ |
| Notifications | ✅ Reachable, generic content | ✅ |

Gating logic: `gateGuest()` in `lib/state/auth_state.dart` — no formal middleware/RBAC layer exists; access control is enforced imperatively at each call site.

---

## Known Gaps / Backlog (surfaced during analysis, not existing stories)

These aren't implemented and would need real stories of their own if the product moves beyond prototype stage:

1. **No backend / persistence** — nothing survives an app restart; there is no API layer at all (`lib/` has zero HTTP/Firebase/Dio calls).
2. **"Place order" doesn't create an order** — checkout navigates straight to tracking without adding anything to order history.
3. **Chat is one-way** — the shop never responds to new messages sent by the customer.
4. **No reviews/ratings screen** — notification copy references rating a completed order, but no rating UI exists.
5. **No support/complaints flow** — beyond ad hoc shop chat, there's no dedicated help/support screen.
6. **Driver "call" button is a no-op placeholder** on the tracking screen.
7. **"Use current location" is a placeholder** on Profile's address editor.
8. **Notifications have no mark-as-read/delete/filter actions.**
9. **Order tracking advances via a manual "Demo" button**, not real driver location/status events.

---

*Document generated from a full codebase analysis of `laundryApp/lib/` (screens, state, router, mock data) on 2026-08-13.*
