# Changelog

## 1.0.8 (build 9)
- Side menu: removed social links; every item has its own icon.
- Support: contact email is info@seculate.ng; only Chat and Email remain; social icons open the pages.
- Business info on the profile can now be edited and is saved to the account.
- Errand types have their own icons.
- Links and email now open correctly on Android 11 and newer.

## 1.0.7 (build 8)
- Wallet: top-up, withdraw to bank, pay for credits and plans from the wallet.
- Agreement certificates and trust score.
- In-app identity verification (ID document + face scan, or NIN), with a result screen for each outcome.
- One result screen per event (credits added, plan active, verification, payment not completed).
- Report a problem, deal timeline, request editing, pause a listing, attach a listing to a bid, minimum and maximum rental days.
- Branded emails for payment and verification events; payment result pages on pay.seculate.ng.
- Backend: wallet, withdrawal, identity and notification edge functions.

## iOS
- Added the iOS project (bundle id ng.seculate.seculate, iOS 15+) with camera, microphone, photo and location permission texts and the seculate:// link.
- A GitHub Actions workflow (iOS build) builds the app on a Mac runner. The IPA it produces is unsigned; installing on a device or uploading to TestFlight needs an Apple Developer account and signing.
