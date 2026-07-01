# HolaRide — Flutter App (full rider + driver flow, screens 1–24)

Covers the complete mockup now: rider flow (1–15) plus the driver side
— vehicle registration/approval, trip creation with admin-controlled
pricing, incoming request management, payouts — and the shared
in-trip features (chat, live tracking, rebook-after-cancellation).

## 1. Setup — replace the whole project this time

This update adds two new packages and a bundled image asset, so it's
not a drop-in-a-few-files update like the last two fixes:

1. Replace your entire `lib/` folder.
2. Replace `pubspec.yaml` (adds `image_picker` and `url_launcher`).
3. Copy in the new `assets/` folder (the splash background photo).
4. From your project root:
   ```bash
   flutter pub get
   flutter run
   ```

`flutter pub get` is **required** this time — skipping it will throw
"package not found" errors for `image_picker` and `url_launcher` the
moment those screens load.

## 2. What's new

**Splash screen** — now uses your actual marketing photo as a
full-bleed background (compressed to a 211 KB JPEG so it doesn't bloat
the app), with a navy gradient overlay so text stays readable over the
sky. Still waits for a tap on "Get Started."

**Driver flow** (all new):
- Vehicle registration — real photo picking from the gallery via
  `image_picker`, uploaded as actual files when you submit
- Vehicle status — approval timeline (Submitted → Under review →
  Approval), color-coded by state
- Create a trip — price per seat is shown but **never editable** here,
  matching the admin-controlled pricing rule; the driver picks route,
  date, time, and seats only
- My Trips (driver) — Upcoming/Past, tap into any trip to manage it
- Trip management — Requests tab (accept/reject), Bookings tab
  (confirmed passengers), Trip actions tab (cancel trip, mark
  completed, mark a specific passenger no-show)
- Payout history — balance, withdraw button, past payout list

**Shared / passenger-side additions:**
- Rebook screen — shown automatically when you tap a booking whose
  trip was cancelled by the driver
- Chat — unlocked once a booking is paid, polling-based, with system
  messages (booking accepted, payment completed) rendered distinctly
  from real messages
- Live tracking — countdown/ETA card with a simple drawn route (not a
  real map — see caveats below) and a **working call button** to the
  driver once a phone number is wired in

"Publish a Trip" on Home is now real: it checks your vehicle status
and routes you to registration, status, or trip creation accordingly.

## 3. Guessed endpoints — please verify against `/docs`

The first build's endpoints (auth, trips/search, me/bookings, etc.)
are unchanged. Everything below is new and unconfirmed:

| What | File | Guessed endpoint |
|---|---|---|
| Get my vehicle | `services/vehicle_service.dart` | `GET /drivers/me/vehicle` |
| Submit vehicle (multipart) | `services/vehicle_service.dart` | `POST /drivers/vehicle` |
| Price preview | `services/driver_service.dart` | `GET /trips/price-preview` |
| Create trip | `services/driver_service.dart` | `POST /trips` |
| Trip's bookings (driver view) | `services/driver_service.dart` | `GET /trips/{id}/bookings` |
| Accept booking | `services/driver_service.dart` | `POST /bookings/{id}/accept` |
| Reject booking | `services/driver_service.dart` | `POST /bookings/{id}/reject` |
| Mark no-show | `services/driver_service.dart` | `POST /bookings/{id}/no-show` |
| Cancel trip | `services/driver_service.dart` | `POST /trips/{id}/cancel` |
| Mark trip completed | `services/driver_service.dart` | `POST /trips/{id}/complete` |
| Balance | `services/payout_service.dart` | `GET /drivers/me/balance` |
| Payout history | `services/payout_service.dart` | `GET /drivers/me/payouts` |
| Withdraw | `services/payout_service.dart` | `POST /drivers/me/payouts/withdraw` |
| Chat messages | `services/chat_service.dart` | `GET /trips/{id}/chat` |
| Send message | `services/chat_service.dart` | `POST /trips/{id}/chat` |
| Live ETA | `services/trip_service.dart` | `GET /trips/{id}/live-status` |

Accept/reject are the most likely to already be correct — your earlier
backend work mentioned a `.../reject` endpoint by name. The rest are
following the same convention as your confirmed endpoints, but
untested. Same rule as before: each is isolated to one file, so a
mismatch is a quick fix once you see the real error.

**One vehicle-photo upload detail worth knowing**: multipart file
uploads need a field name and your backend's exact expected name for
that field (commonly `photos`) is unconfirmed — if submitting a
vehicle 422s, that error will likely name the field it actually wants.

## 4. What's intentionally not real yet

- **The map on the live tracking screen** is a drawn dotted line, not
  an interactive map — needs a Google Maps/Mapbox API key and platform
  setup.
- **The call button** on live tracking shows a message instead of
  calling, because `DriverInfo` doesn't carry a phone number yet. Add
  `phone` to `models/trip.dart`'s `DriverInfo.fromJson` once your trip
  detail endpoint exposes it, and the button works immediately — the
  `url_launcher` wiring is already in place.
- **Push notifications** — still polling (chat every 4s, live tracking
  every 15s, booking status every 6s).

## 5. Folder structure (new additions only)

```
lib/
  models/        vehicle.dart, chat_message.dart, payout.dart  (new)
  services/      vehicle_service.dart, driver_service.dart,
                 payout_service.dart, chat_service.dart         (new)
  screens/
    driver/       vehicle_registration, vehicle_status,
                  create_trip, my_trips, trip_management,
                  payout_history                                (new)
    bookings/     rebook_screen.dart                            (new)
    trip/         chat_screen.dart, live_tracking_screen.dart   (new)
assets/
  images/        splash_bg.jpg                                  (new)
```

Try `flutter run` and send me whatever it prints.
