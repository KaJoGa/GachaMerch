# GachaMerch - Genshin Import

GachaMerch is a Flutter mobile/web application for buying Genshin-themed items. The project uses a Flutter frontend, a Node.js + Express backend, and a MySQL database. It supports normal database login, Google OAuth login, bearer token authorization, role-based admin access, sale listing management, purchases with stock decrement, and transaction history.

This README is the external documentation file for the mobile lab assignment.

## Project Overview

Company: GachaMerch

Project name: Genshin Import

Description: Genshin Import provides Teyvat weapons and food items that users can view and buy. The app has two roles:

- Admin: manages items that are listed for sale.
- User: views listed items and buys any available quantity as long as stock is sufficient.

The original assignment asks for weapon CRUD. In this implementation, admin CRUD is implemented through the `listings` table: the master `weapons` and `foods` tables act as catalogs, while `listings` stores the items currently for sale, including sale price and stock.

## Tech Stack

| Layer | Technology |
| --- | --- |
| Database | MySQL |
| Backend | Node.js + Express |
| Frontend | Flutter |
| Auth | DB login, Google OAuth, bearer token |
| Local storage | SharedPreferences |
| HTTP client | Flutter `http`, backend `mysql2/promise` |

## Getting Started / How to Run

### 1. Database Setup
- Open your MySQL server (e.g., using XAMPP, MAMP, or native MySQL).
- Create a new database named `gachamerch`.
- Import the provided `gachamerch.sql` file into the `gachamerch` database to set up all required tables (`users`, `foods`, `weapons`, `listings`, `transactions`) and sample data.

### 2. Backend Setup (Node.js)
1. Open a terminal and navigate to the `backend` directory:
   ```bash
   cd backend
   ```
2. Install the necessary dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file in the `backend` folder containing your database configuration. Example:
   ```env
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=
   DB_NAME=gachamerch
   PORT=3000
   ```
4. Start the backend server:
   ```bash
   npm start
   ```
   *(The server will typically run on `http://localhost:3000`)*

### 3. Frontend Setup (Flutter)
1. Ensure you have [Flutter](https://docs.flutter.dev/get-started/install) installed and properly set up.
2. Open a new terminal and navigate to the root directory of the Flutter project.
3. Fetch the Flutter dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app on your preferred device or emulator:
   ```bash
   flutter run
   ```

> **Note on Localhost Connections:** 
> If you are running the Flutter app on an Android Emulator, it accesses your local computer's backend via `http://10.0.2.2:3000`. If you are running on Web, Windows, or an iOS Simulator, it uses `http://localhost:3000`. Ensure the base URL in the Flutter app matches your testing environment.

## Main Features

### Authentication

- Register with name, email, and password.
- Login with an account stored in the MySQL `users` table.
- Login with Google OAuth.
- Generate a random bearer token using `crypto.randomBytes(20).toString("hex")`.
- Store token and role locally with `SharedPreferences`.
- Verify token in protected backend endpoints.
- Refresh role from `/profile`, so admin access can be updated from the database.

### User Features

- View sale items from `GET /listings`.
- Browse products in a grid on the home page.
- See item name, price, stock, and image.
- Buy an item from the buy dialog.
- Choose quantity using a stepper capped by available stock.
- Backend validates stock using a transaction flow and rejects over-stock purchases.
- View purchase history in the Transactions tab.

### Admin Features

- Admin-only menu appears on the Profile page when `role == "admin"`.
- Manage Sales page shows all current sale listings.
- Add a listing from the combined weapon/food catalog.
- Search catalog items.
- Filter catalog by item type and category.
- Update listing price and stock.
- Delete a listing from sale.
- View stock health with color-coded `stock / initial_stock`.

### Extra Features

- DB-down detection through `dbGuard`, returning a clear 503 response when XAMPP/MySQL is not running.
- Frontend login and listing screens display real backend error messages instead of generic failures.
- Stock health indicator in admin:
  - Green when stock is above 50%.
  - Yellow when stock is at or below 50%.
  - Red when stock is at or below 20%.
- All / Weapons / Food segmented filter on Manage Sales.
- Price formatting with `$` on home, transactions, and admin pages.
- Transaction records keep `item_name` and `unit_price` snapshots, so history remains readable even if listings are changed or deleted later.

## App Screens

### Login Page

File: `lib/features/auth/login_page2.dart`

Purpose:

- Allows DB login with email and password.
- Provides Google Sign-In.
- Validates email and password before sending the request.
- Stores user data and navigates to the main menu on success.

### Register Page

File: `lib/features/auth/register_page2.dart`

Purpose:

- Creates a new user account.
- Validates name, email, password, and terms agreement.
- Shows success/error feedback with SnackBar or inline error text.

### Home Page

File: `lib/features/main/home_page.dart`

Purpose:

- Displays banner carousel, menu shortcuts, and sale items.
- Fetches products from `/listings`.
- Shows loading, empty, and error states.
- Opens the buy dialog for in-stock items.

### Purchase Confirmation Dialog

File: `lib/features/main/home_page.dart`

Purpose:

- Acts as the purchase confirmation flow.
- Shows item name, price, stock, quantity, and total.
- Lets the user increase/decrease quantity.
- Calls `POST /transactions` when confirmed.

### Transactions Page

File: `lib/features/main/transaction_page.dart`

Purpose:

- Fetches authenticated transaction history.
- Displays item name, quantity, unit price, total price, and date.
- Supports pull-to-refresh.

### Profile Page

File: `lib/features/main/profile_page.dart`

Purpose:

- Displays name, email, role badge, profile actions, and logout.
- Refreshes profile from protected `/profile`.
- Shows the Manage Sales menu only for admins.

### Manage Sales Page

File: `lib/features/admin/manage_listings_page.dart`

Purpose:

- Admin CRUD screen for sale listings.
- Shows all sale listings with image, stock, and price.
- Supports All / Weapons / Food filtering.
- Opens edit and delete actions.

### Catalog Picker Page

File: `lib/features/admin/manage_listings_page.dart`

Purpose:

- Admin selects a master item from weapons or foods.
- Supports tabs, search, and category filter.
- Opens the sale listing form.

### Listing Form Page

File: `lib/features/admin/manage_listings_page.dart`

Purpose:

- Creates or edits a listing.
- Validates price and stock.
- Sends data to `POST /listings` or `PUT /listings/:id`.

## Screenshots

Place final screenshots in `docs/screenshots/` and link them here before submission.

Recommended screenshot list:

| Page | Screenshot path |
| --- | --- |
| Login | `docs/screenshots/login.png` |
| Register | `docs/screenshots/register.png` |
| Home / weapon list | `docs/screenshots/home.png` |
| Buy confirmation dialog | `docs/screenshots/buy-dialog.png` |
| Transactions | `docs/screenshots/transactions.png` |
| Profile | `docs/screenshots/profile.png` |
| Manage Sales | `docs/screenshots/manage-sales.png` |
| Catalog Picker | `docs/screenshots/catalog-picker.png` |
| Listing Form | `docs/screenshots/listing-form.png` |

## Backend API

Base URL:

- Flutter Web: `http://localhost:3000`
- Android emulator: `http://10.0.2.2:3000`

### Auth Endpoints

| Method | Endpoint | Protected | Description |
| --- | --- | --- | --- |
| POST | `/auth/register` | No | Register a new DB user. |
| POST | `/auth/login` | No | Login with email/password and return bearer token. |
| POST | `/auth/google-login` | No | Verify Google access token, auto-register if needed, and return bearer token. |
| GET | `/profile` | Yes | Return current authenticated user. |

### Catalog and Listing Endpoints

| Method | Endpoint | Protected | Description |
| --- | --- | --- | --- |
| GET | `/weapons` | No | List weapon catalog. |
| GET | `/weapons/:id` | No | Get one weapon from the catalog. |
| GET | `/fetch/weapons` | No | Legacy weapon list route. |
| GET | `/fetch/foods` | No | List food catalog. |
| GET | `/listings` | No | List items currently for sale. |
| GET | `/catalog` | Admin | List master catalog items for admin listing creation. |
| POST | `/listings` | Admin | Create a sale listing from an existing weapon or food. |
| PUT | `/listings/:id` | Admin | Update listing price and stock. |
| DELETE | `/listings/:id` | Admin | Remove listing from sale. |

### Transaction Endpoints

| Method | Endpoint | Protected | Description |
| --- | --- | --- | --- |
| POST | `/transactions` | Yes | Buy an item and decrement stock. |
| GET | `/transactions` | Yes | Get current user's transaction history. |

Protected requests must send:

```http
Authorization: Bearer <token>
```

## Database

Main database file:

```text
gachamerch.sql
```

Important tables:

| Table | Purpose |
| --- | --- |
| `users` | Stores user account, hashed password, role, and bearer token. |
| `weapons` | Master weapon catalog. |
| `foods` | Master food catalog. |
| `listings` | Items currently listed for sale, with price and stock. |
| `transactions` | Purchase history with item and price snapshots. |

Important migration scripts:

| Script | Purpose |
| --- | --- |
| `backend/scripts/migrateWeapons.js` | Adds required weapon fields such as type, description, stock, and price. |
| `backend/scripts/migrateListings.js` | Creates the `listings` table. |
| `backend/scripts/migrateInitialStock.js` | Adds `initial_stock` for stock health indicator. |
| `backend/scripts/migrateTransactions.js` | Creates the `transactions` table. |

## Setup and Run

### 1. Import Database

1. Start XAMPP MySQL.
2. Create/import the database from `gachamerch.sql`.
3. Make sure the database name matches `DB_NAME` in `backend/.env`.

### 2. Configure Backend Environment

Create `backend/.env`:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=gachamerch
DB_PORT=3306
GOOGLE_CLIENT_ID=your_web_oauth_client_id
GOOGLE_ANDROID_CLIENT_ID=your_android_oauth_client_id_optional
```

### 3. Install Backend Dependencies

```bash
cd backend
npm install
```

Dependencies are already represented by `backend/package.json` and `backend/package-lock.json`.

### 4. Run Database Migrations

From the `backend` folder:

```bash
node scripts/migrateWeapons.js
node scripts/migrateListings.js
node scripts/migrateInitialStock.js
node scripts/migrateTransactions.js
```

### 5. Run Backend Server

```bash
cd backend
node app.js
```

Expected output:

```text
Server running http://127.0.0.1:3000
Database connected (XAMPP MySQL OK).
```

### 6. Run Flutter App

For Chrome/web:

```bash
flutter run -d chrome --web-port=5000
```

For Android emulator:

```bash
flutter run
```

The repository also includes:

```text
run_web.bat
```

That batch file starts the backend, waits briefly, runs Flutter Web on port 5000, then stops the backend when Flutter closes.

## UI Components Used

The project uses more than five Flutter UI component types:

- `TextField` and `TextFormField` for login, register, search, price, and stock inputs.
- `ElevatedButton`, `TextButton`, `IconButton`, and `FloatingActionButton`.
- `ListView` for transactions, profile menu, catalog, and admin listings.
- `GridView` for home products and menu shortcuts.
- `Card` for product/admin/listing/form display.
- `Image.network` and `SvgPicture.asset` for product images and Google icon.
- `AlertDialog` and `SnackBar` for confirmation and feedback.
- `AppBar`, `BottomNavigationBar`, and `TabBar`.
- `DropdownButton` for category filtering.
- `SegmentedButton` for All / Weapons / Food admin filter.
- `Checkbox` for register terms agreement.
- `RefreshIndicator` for refreshable lists.

## Validations Implemented

The app implements at least three validation categories with visible error messages:

| Validation type | Location | Error example |
| --- | --- | --- |
| Required field | Login/Register | `Email is required`, `Name is required`, `Password is required` |
| Format validation | Login/Register | `Invalid email` |
| Length validation | Login/Register | `Password must be at least 6 characters`, name/email max length |
| Terms validation | Register | `You must agree to the terms` |
| Numeric validation | Listing form | `Invalid number` |
| Range validation | Listing form | `Price > 0`, `Stock >= 0` |
| Purchase stock validation | Buy dialog/backend | Quantity stepper capped by stock and backend rejects insufficient stock |
| Auth validation | Backend middleware | `Token required`, `Invalid token` |
| Admin validation | Backend middleware | Admin-only listing write endpoints |

## Theme Customization

Theme file:

```text
lib/theme/app_theme.dart
```

Customized theme properties:

- Color scheme:
  - Primary muted gold: `#C29A5B`
  - Secondary sage/jade: `#5A716A`
  - Warm background: `#FDFBF7`
  - White surface: `#FFFFFF`
  - Dark text: `#3E342F`
- App background via `scaffoldBackgroundColor`.
- AppBar, ElevatedButton, FloatingActionButton, and text cursor colors.
- Custom visible text sizes in login/register/home/profile/admin screens.
- Image display uses `BoxFit.contain` for products and thumbnails.
- Alpha/tint usage for icons, category filter capsule, and role badge.

Custom font family has not been added yet. The app currently uses the default Flutter/Material font.

## Creativity Points

- The sale flow is implemented through `listings`, making master catalog data reusable and keeping admin actions focused on what is currently for sale.
- The app supports weapons and food, even though the assignment focuses on weapons.
- Transaction history stores snapshots to avoid broken history when listings change.
- Admin stock health indicator makes low-stock items easy to notice.
- DB-down handling improves demo reliability by showing a clear MySQL/XAMPP error.
- Google OAuth is handled without Firebase Auth; the backend verifies Google access tokens and issues its own bearer token.

## Current Completion Notes

Completed:

- DB login and registration.
- Google OAuth login.
- Bearer token generation and verification.
- Public product listing.
- Admin listing create/update/delete.
- User purchase flow with stock decrement.
- Transaction history.
- Profile with role-based admin access.
- Visible theme customization.
- This README documentation file.

Still open:

- Standalone weapon detail page.
- Standalone cart page.
- Custom font family.
- Final screenshot images for every page.

