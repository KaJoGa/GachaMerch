# Target: Genshin Import — Flutter Mobile App

> Assignment spec for **GachaMerch** project. This file is the source of truth for Claude Code. Treat every checkbox as a deliverable that must be present and demonstrable before the project is considered complete.

> **Progress status — updated 2026-06-03.** Core loop is complete: DB login + Google OAuth, role-based admin, full CRUD on the **sale inventory** (`listings` table), user buy flow with atomic stock decrement, and transaction history. **Deviation from spec:** admin CRUD operates on a `listings` table (items currently for sale, polymorphic over weapons + foods) rather than mutating the master weapon catalog directly — so "insert/update/delete weapon" is satisfied as "insert/update/delete a sale listing". **Still open:** dedicated weapon detail page, dedicated cart page, custom font family, and the external documentation file (§9). Checkboxes below reflect this.
>
> **Extra features beyond the checklist (creativity points for §9):**
> - **DB-down detection** — `dbGuard` middleware + final error-handler return a clear 503 ("XAMPP MySQL not running") instead of cryptic 500s; login surfaces the real cause instead of always blaming the password.
> - **Stock health indicator** — Manage Sales shows `stock / initial_stock` colour-coded green → yellow (≤ 50%, rounded up) → red (≤ 20%, rounded down) against the baseline captured at listing time.
> - **View mode filter** — Manage Sales has an All / Weapons / Food segmented filter.
> - **Price formatting** — all displayed prices are prefixed with `$` across home, transactions and admin.

---

## 1. Project Overview

**Company:** GachaMerch
**Project Name:** Genshin Import
**Description:** Genshin Import is an application that provides numerous Teyvat weapons and artifacts which the user can buy in the application. There are 2 roles in the application:

- **Admin** can insert, update, and delete weapons.
- **User** can view weapons and buy weapons in Genshin Import.

The weapon must have: `id`, `name`, `type`, `description`, `stock`, `image`, and `price`.
A user can buy as many of a weapon as they want.

---

## 2. Tech Stack (Required)

| Layer | Technology |
|---|---|
| Database | **MySQL** |
| Backend | **Node.js + Express** |
| Frontend | **Flutter (mobile)** |
| Auth | DB-based login + External OAuth + Bearer token |

---

## 3. Roles & Permissions

### Admin
- [x] [DONE] Insert weapon _(via `POST /listings` — admin lists an existing weapon for sale)_
- [x] [DONE] Update weapon _(via `PUT /listings/:id` — price & stock)_
- [x] [DONE] Delete weapon _(via `DELETE /listings/:id` — remove from sale)_
- [x] [DONE] View weapon list _(Manage Sales page)_

### User
- [x] [DONE] View weapon list / details _(home grid + buy dialog showing name/price/stock; no standalone detail page yet)_
- [x] [DONE] Buy weapon (any quantity, must respect stock) _(quantity stepper capped at stock; backend `SELECT ... FOR UPDATE` rejects over-stock)_

---

## 4. Database Requirements (MySQL)

The application must perform **at least**:
- [x] [DONE] 1 × CREATE operation _(register user, create listing, insert transaction)_
- [x] [DONE] 1 × RETRIEVE operation _(list weapons/foods/listings, profile, history)_
- [x] [DONE] 1 × UPDATE operation _(update listing price/stock; stock decrement on buy)_
- [x] [DONE] 1 × DELETE operation _(delete listing)_

### Required tables (minimum)
- [x] [DONE] `users` — id, username/email, password (hashed), role (admin/user), oauth fields _(opaque hex token in `users.token`)_
- [x] [DONE] `weapons` — id, name, type, description, stock, image (URL or path), price _(type/description/stock/price added via `migrateWeapons.js`)_
- [x] [DONE] `transactions` / `purchases` — id, user_id, quantity, total_price, created_at _(+ listing_id, item_name & unit_price snapshot)_

### Weapon schema (mandatory fields)
```
id          INT / UUID, PK
name        VARCHAR
type        VARCHAR        (e.g. Sword, Bow, Catalyst, Claymore, Polearm)
description TEXT
stock       INT            (must decrement on purchase)
image       VARCHAR        (URL or asset path)
price       DECIMAL/INT
```

---

## 5. Backend Requirements (Node.js + Express)

The backend must expose **at least**:
- [x] [DONE] **2 × GET** requests _(`/weapons`, `/listings`, `/transactions`, `/profile`, …)_
- [x] [DONE] **1 × POST / PUT / PATCH / DELETE** request _(POST/PUT/DELETE `/listings`, POST `/transactions`, POST `/auth/*`)_

### Suggested endpoints
- [x] [DONE] `GET  /weapons` — list all weapons
- [x] [DONE] `GET  /weapons/:id` — get single weapon (also `GET /transactions` history)
- [x] [DONE] `POST /weapons` — admin: create weapon _(implemented as `POST /listings`)_
- [x] [DONE] `PUT  /weapons/:id` — admin: update weapon _(implemented as `PUT /listings/:id`)_
- [x] [DONE] `DELETE /weapons/:id` — admin: delete weapon _(implemented as `DELETE /listings/:id`)_
- [x] [DONE] `POST /auth/login` — DB login, returns bearer token
- [x] [DONE] `POST /auth/oauth` — OAuth callback / token exchange _(`/auth/google` — verifies Google access token)_
- [x] [DONE] `POST /transactions` — user: buy weapon (decrement stock)

### Bearer token rules
- [x] [DONE] Token length **≥ 20 characters** _(`crypto.randomBytes(20).toString("hex")` = 40 chars)_
- [x] [DONE] Token is **alphanumeric** _(hex)_
- [x] [DONE] **At least 1 protected endpoint** verifies the bearer token (middleware) _(`authMiddleware` on `/profile`, `/transactions`, `/listings` writes, …)_

---

## 6. Frontend Requirements (Flutter Mobile)

### Pages — **minimum 5** _(≥ 5 met ✅)_
Suggested:
- [x] [DONE] Login page
- [x] [DONE] Register page (optional but recommended)
- [x] [DONE] Home / weapon list page
- [ ] Weapon detail page (with Buy button) _(buy is a dialog from home; no standalone page yet)_
- [ ] Cart / purchase confirmation page _(buy dialog acts as confirmation; no cart page)_
- [x] [DONE] Admin CRUD page (add / edit / delete weapon) _(Manage Sales + Catalog Picker + Listing Form)_
- [x] [DONE] Profile / transaction history page _(Profile + Transactions tab)_

### UI Components — **minimum 5 kinds** _(≥ 5 met ✅)_
Examples (pick at least 5 distinct kinds):
- [x] [DONE] TextField / TextFormField
- [x] [DONE] Button (ElevatedButton / TextButton / IconButton)
- [x] [DONE] ListView / GridView
- [x] [DONE] Card
- [x] [DONE] Image (NetworkImage / AssetImage)
- [x] [DONE] Dialog / BottomSheet / SnackBar
- [x] [DONE] AppBar / Drawer / BottomNavigationBar _(AppBar + BottomNavigationBar + TabBar)_
- [x] [DONE] Dropdown / Slider / Switch _(category filter dropdown)_

### Data Validations — **minimum 3 kinds** _(≥ 3 met ✅)_
Each must show an **error message** on failure. Examples:
- [x] [DONE] Required field (e.g. name cannot be empty) _(register name/email)_
- [x] [DONE] Format validation (email, numeric-only for price/stock) _(int parse on price/stock)_
- [x] [DONE] Range / length validation (min length for password, stock ≥ 0, price > 0) _(name/email ≤ 100, price > 0, stock ≥ 0)_
- [x] [DONE] Quantity ≤ available stock when buying _(stepper capped + backend check)_

---

## 7. Authentication

- [x] [DONE] Login successfully using a user stored in the **MySQL DB**
- [x] [DONE] Login successfully using **External OAuth** (Google / Facebook / Twitter / etc.) _(Google OAuth — access token verified on backend)_
- [x] [DONE] Generate **bearer token** — ≥ 20 chars, alphanumeric _(custom random hex token, 40 chars, stored in `users.token`)_
- [x] [DONE] At least **1 endpoint** verifies the bearer token before responding

---

## 8. UI Design / Theming

The app must be themed and involve changing **2–4 properties**. Examples:
- [ ] Custom font family (e.g. Genshin-inspired font via `google_fonts` or custom asset) _(not added — using default font)_
- [x] [DONE] Custom color scheme (primary, accent, background) _(`AppColors` — gold/sage/cream/brown palette via `buildAppTheme()`)_
- [x] [DONE] Custom font sizes / text styles _(price/title/badge styles)_
- [x] [DONE] Custom tint / alpha on images or overlays _(filter capsule + role badge alpha tints)_
- [x] [DONE] Content mode / image fit _(`BoxFit.contain` on product/thumbnail images)_

Rules:
- [x] [DONE] All customizations must be **visible** in the running app
- [x] [DONE] All customizations must be **noted in the documentation** _(documented in `README.md`)_
- [x] [DONE] Design must remain **usable** — sufficient contrast between text and background, non-clashing colors

---

## 9. External Documentation

- [x] [DONE] Produce an **external documentation file** (PDF / README / docs site) that explains: _(`README.md`)_
  - [x] [DONE] Feature details — what each screen and endpoint does
  - [x] [DONE] Creativity points — what makes this implementation stand out (theming choices, UX touches, extra features)
  - [ ] Screenshots of every page
  - [x] [DONE] Setup / run instructions for backend and Flutter app
  - [x] [DONE] List of UI components used (≥ 5)
  - [x] [DONE] List of validations implemented (≥ 3)
  - [x] [DONE] List of theme properties customized (2–4)

---

## 10. Suggested Project Structure

```
genshin-import/
├── backend/                  # Node.js + Express
│   ├── src/
│   │   ├── routes/
│   │   │   ├── auth.js
│   │   │   ├── weapons.js
│   │   │   └── transactions.js
│   │   ├── middleware/
│   │   │   └── auth.js       # bearer token verification
│   │   ├── controllers/
│   │   ├── models/           # MySQL queries (mysql2 / sequelize / prisma)
│   │   ├── config/
│   │   │   └── db.js
│   │   └── app.js
│   ├── .env                  # DB creds, JWT secret, OAuth client ids
│   └── package.json
│
├── frontend/                 # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── pages/
│   │   │   ├── login_page.dart
│   │   │   ├── home_page.dart
│   │   │   ├── weapon_detail_page.dart
│   │   │   ├── cart_page.dart
│   │   │   └── admin_page.dart
│   │   ├── widgets/
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   │   └── auth_service.dart
│   │   ├── models/
│   │   │   └── weapon.dart
│   │   └── utils/
│   │       └── validators.dart
│   └── pubspec.yaml
│
├── database/
│   └── schema.sql            # CREATE TABLE statements + seed data
│
└── docs/
    └── DOCUMENTATION.md      # external documentation
```

---

## 11. Acceptance Checklist (Final)

Before submitting, verify every item:

**Database**
- [x] [DONE] MySQL connected, schema created, seed data inserted _(445 foods, 236 weapons)_
- [x] [DONE] At least 1 of each: CREATE / READ / UPDATE / DELETE working end-to-end

**Backend**
- [x] [DONE] ≥ 2 GET endpoints implemented and tested
- [x] [DONE] ≥ 1 POST/PUT/PATCH/DELETE endpoint implemented and tested
- [x] [DONE] Bearer token: ≥ 20 chars, alphanumeric
- [x] [DONE] At least 1 endpoint protected by bearer token middleware

**Frontend**
- [x] [DONE] ≥ 5 pages
- [x] [DONE] ≥ 5 kinds of UI components
- [x] [DONE] ≥ 3 kinds of validation, each with a clear error message
- [x] [DONE] Connected to backend via HTTP

**Auth**
- [x] [DONE] DB login works
- [x] [DONE] External OAuth login works
- [x] [DONE] Bearer token issued and verified

**UI / Theme**
- [x] [DONE] 2–4 theme properties customized and visible
- [x] [DONE] Contrast / readability verified

**Documentation**
- [x] [DONE] External documentation file produced
- [ ] All required sections covered (see §9)

---

## 12. Reference

- Assignment doc: `020226 FM-BINUS-AA-FPT-66/R7`
- Example token format (from spec): `n8x7wfqtsrvxnvsm8dcz` (20 chars, alphanumeric)
