# UC E-Shelter — Architecture & Patterns

## Overview

**Laravel 12** / **PHP 8.2+** — Hotel/booking management platform with two interfaces:
- **Web dashboard** (Blade + Tailwind v4 + Flowbite) for hotel owners and admins
- **REST API** (Sanctum auth) for a mobile booking app

## Architecture Flow

```
Routes → Middleware → Controller → FormRequest (validation)
                                    |
                           Action class (business logic)
                                    |
                           Model / Repository (data access)
                                    |
                           View / ApiResponse (JSON)
```

## Dominant Patterns

### Action Pattern (primary — used for writes)

Single-purpose classes in `app/Actions/` with methods like `create()`, `update()`, `delete()`.

- Instantiated via `app(\App\Actions\SomeAction::class)` in controller constructors
- Keeps controllers thin and business logic reusable
- Custom Artisan generator: `php artisan make:action`

**Existing actions:** AccommodationAction, BookingAction, BusinessInformationAction, BusinessOwnerAction, FeatureAction, RoomAction, RoomTypeAction, UserAccommodation, UserAction

### Repository Pattern (secondary — used for reads)

`BaseRepository` wraps an Eloquent model with `__call()` magic forwarding to the query builder.

- Located in `app/Repositories/`
- Used when custom query scopes or filtering logic is needed
- Extended by: AccommodationRepository, UserRepository, PostRepository

## Directory Structure

```
app/
├── Actions/              # Business logic (single-purpose classes)
├── Console/Commands/     # Artisan commands
├── Exceptions/           # Exception handling
├── Helper/               # Standalone helper functions
├── Http/
│   ├── Controllers/      # Grouped by domain (Accommodations/, Booking/, etc.)
│   │   └── Api/BookingApp/  # Mobile app API controllers
│   ├── Middleware/        # Custom middleware (Auth, SetLocale, etc.)
│   └── Requests/          # Form request validation
├── Jobs/                 # Queue jobs
├── Mail/                 # Mailables
├── Models/               # Eloquent models
├── Policies/             # Authorization policies
├── Providers/            # Service providers
├── Repositories/         # Data access layer
├── Resources/Api/V1/     # API resource classes (placeholder)
├── Services/             # Payment services (PayWay)
└── Supports/             # Traits (ApiResponse, OTPGenerate)

database/
├── migrations/           # 21 migrations
├── factories/            # Model factories
└── seeders/              # Database seeders

resources/views/          # Blade templates
├── components/           # Reusable Blade components (buttons, forms, layouts)
└── [domain directories]  # accommodations, booking, billing, rooms, etc.

routes/
├── web.php               # Web dashboard routes
├── api.php               # Mobile app API routes
└── api/v1/api.php        # Versioned API (placeholder)
```

## Naming Conventions

| Layer | Convention | Example |
|---|---|---|
| Controllers | PascalCase, domain subdirectories | `Accommodations\AccommodationsController` |
| Models | PascalCase singular | `User`, `BusinessInformation` |
| Actions | PascalCase + "Action" suffix | `UserAction`, `RoomAction` |
| Repositories | PascalCase + "Repository" suffix | `UserRepository` |
| Form Requests | PascalCase + "Request" suffix | `SignUpRequest` |
| Middleware | PascalCase + "Middleware" suffix | `SetLocaleMiddleware` |
| Jobs | PascalCase + "Job" suffix | (inconsistency: `sendMailOTPJob` exists) |
| Routes (URL) | kebab-case | `/business-information`, `/forgot-password` |
| Routes (names) | dot-notation | `accommodations.index`, `contents.hero` |
| Views (dirs) | kebab-case | `room-types/`, `business-information/` |
| Views (files) | snake_case | `index.blade.php`, `create.blade.php` |

## Authentication

**Web (dashboard):** Custom OTP-based system (not Breeze/Jetstream).
- Session-based, uses `Auth` facade
- OTP email verification (6-digit code, 5-min expiry)
- Middleware chain: `auth` → `verified.email`

**API (mobile app):** Laravel Sanctum token-based.
- Sign-up creates `guest` role user, returns 30-day token
- CORS configured for `http://localhost:2025`

**User roles:** `super_admin`, `admin`, `hotel_owner`, `hotel_staff`, `guest`
- Stored in `role` column (string check — not yet fully leveraging Spatie)

## Validation

- **Web controllers:** Form Request classes in `app/Http/Requests/`
- **API controllers:** Mix of Form Requests and inline `Validator::make()`

## Frontend

- **No JS framework** (no Vue, React, Livewire)
- **Blade server-side rendering** with Tailwind CSS v4 + Flowbite components
- **ApexCharts** on dashboard (loaded as `window.ApexCharts`)
- **Dark mode** via `data-theme` attribute, persisted in localStorage
- **i18n** via `trans()` helper with locale middleware

## Key Packages

| Package | Purpose |
|---|---|
| `laravel/sanctum` | API token auth |
| `spatie/laravel-permission` | Role & permission management (partially used) |
| `spatie/laravel-medialibrary` | Media/file attachment |
| `gehrisandro/tailwind-merge-laravel` | Tailwind class merging |
| `apexcharts` | Dashboard charts |
| `flowbite` | UI components |
| `pestphp/pest` | Testing framework |

## Testing

- **Pest PHP** — currently skeletal (only default scaffold tests)
- No application-specific tests yet
- `RefreshDatabase` commented out in `Pest.php`

## Known Inconsistencies

- `sendMailOTPJob` / `sendMailVerifyJob` should be PascalCase (`SendMailOtpJob`)
- `SwichLanguageController` has a typo (should be `SwitchLanguageController`)
- Some controllers inline business logic instead of delegating to Action classes
- Spatie permissions installed but most role checks use raw `role` string column comparisons

## Adding a New Feature (recommended workflow)

1. **Route** — Add to `routes/web.php` or `routes/api.php`
2. **Form Request** — Create validation in `app/Http/Requests/`
3. **Action** — Create business logic in `app/Actions/`  (`php artisan make:action`)
4. **Controller** — Keep thin, delegate to Action
5. **View** — Add Blade template (or `ApiResponse` for API)
6. **Test** — Write Pest test
