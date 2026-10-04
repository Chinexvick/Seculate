# Seculate (Flutter, Android)

Local peer-to-peer marketplace app. Runs fully offline on mock data; no backend yet.

## Run
    flutter pub get
    flutter run            # any Android device / emulator (minSdk per Flutter default)
    flutter build apk --release

## Structure
- `lib/app/routes.dart`       all routes + transitions
- `lib/core/`                 theme, tokens, shared widgets
- `lib/data/`                 models, mock data, `MarketRepository` (the backend seam), `user_profile.dart`
- `lib/features/<area>/`      screens (auth, home, borrow, post, services, chat, profile, settings, support, listings)

## Connecting Supabase later
1. Implement `MarketRepository` (lib/data/market_repository.dart) with Supabase queries and swap the
   `marketRepository` instance.
2. Replace the `Future.delayed` fake waits in auth screens (login, sign up, verify code, create password,
   identity), `list_item_screen.dart` (save/post), `promote_ad_screen.dart`, settings screens
   (`verification_flows.dart`, `change_password_screen.dart`, `business_settings.dart`) and
   `support_screens.dart` (delete account, Secubot reply) with real calls.
3. `currentProfile` (lib/data/user_profile.dart) holds the signed-in user's data in memory; load it from
   the `profiles` table after login.
4. Photo pickers (post ad, profile, identity attach) are placeholders: add `image_picker` + Supabase Storage.
5. WhatsApp / email / call in Support currently show a toast: add `url_launcher`.

## Tests
`flutter test` renders every screen at 390x844 with the real Poppins font and fails on layout overflows.
