import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seculate/app/routes.dart';
import 'package:seculate/core/theme/app_theme.dart';
import 'package:seculate/data/auth_service.dart';
import 'package:seculate/data/models.dart';
import 'package:seculate/data/user_profile.dart';
import 'package:seculate/features/auth/forgot_password_screen.dart';

import 'support/fakes.dart';

Future<void> _loadPoppins() async {
  final loader = FontLoader('Poppins');
  for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold', 'Italic']) {
    final bytes = File('assets/fonts/Poppins-$f.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Widget _app(String route, [Object? args]) => MaterialApp(
      theme: AppTheme.light,
      onGenerateRoute: (s) => Routes.generate(RouteSettings(
          name: s.name == '/' ? route : s.name,
          arguments: s.name == '/' ? args : s.arguments)),
      initialRoute: '/',
    );

void main() {
  setUpAll(_loadPoppins);
  setUp(installFakes);

  group('6-digit code screen', () {
    testWidgets('wrong code shows an error and does not continue',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester
          .pumpWidget(_app(Routes.verifyCode, const VerifyCodeArgs('a@b.com')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(find.byType(TextField), '999999');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('didn’t work'), findsOneWidget);
      expect(find.text('Create Password'), findsNothing);
    });

    testWidgets('a 4-digit entry does not submit', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester
          .pumpWidget(_app(Routes.verifyCode, const VerifyCodeArgs('a@b.com')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Email verified'), findsNothing);
      expect(find.textContaining('didn’t work'), findsNothing);
    });

    testWidgets('correct code shows the verified screen', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester
          .pumpWidget(_app(Routes.verifyCode, const VerifyCodeArgs('a@b.com')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Email verified'), findsOneWidget);
    });

    testWidgets(
        'after a correct signup code the success screen shows, then create password',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester
          .pumpWidget(_app(Routes.verifyCode, const VerifyCodeArgs('a@b.com')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Email verified'), findsOneWidget);
      await tester.tap(find.text('Create password'));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Create Password'), findsOneWidget);
    });

    testWidgets('a copied 6-digit code is offered to paste', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') return {'text': '123456'};
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await tester
          .pumpWidget(_app(Routes.verifyCode, const VerifyCodeArgs('a@b.com')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('Paste code  123456'), findsOneWidget);
    });

    testWidgets('there is no magic-link wording anywhere', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester
          .pumpWidget(_app(Routes.verifyCode, const VerifyCodeArgs('a@b.com')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining(RegExp('link', caseSensitive: false)),
          findsNothing);
      expect(find.textContaining('6-digit code'), findsOneWidget);
    });
  });

  group('identity verification', () {
    testWidgets('offers in-app scan and NIN, never BVN', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(Routes.identityVerification, null));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('ID + face scan'), findsOneWidget);
      expect(find.text('NIN number'), findsOneWidget);
      expect(find.textContaining('BVN'), findsNothing);
    });

    testWidgets('skip opens the sheet and Continue and skip leaves the step',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(Routes.identityVerification, null));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Skip this step'));
      await tester.pumpAndSettle();
      expect(find.textContaining('BVN'), findsNothing);
      expect(find.text('Continue and skip'), findsOneWidget);
      await tester.tap(find.text('Continue and skip'));
      await tester.pumpAndSettle();
      expect(find.text('Identity Verification'), findsNothing);
    });
  });

  group('pure logic', () {
    test('onboarding resumes at the right screen', () {
      expect(AuthService.routeForStep('created'), Routes.createPassword);
      expect(AuthService.routeForStep('email_verified'), Routes.createPassword);
      expect(AuthService.routeForStep('profile'), Routes.personalDetails);
      expect(AuthService.routeForStep('location'), Routes.locationGate);
      expect(AuthService.routeForStep('verification'),
          Routes.identityVerification);
      expect(AuthService.routeForStep('done'), Routes.home);
    });

    test('greeting follows the time of day', () {
      expect(UserProfile.greeting(DateTime(2026, 1, 1, 8)), 'Good morning');
      expect(UserProfile.greeting(DateTime(2026, 1, 1, 13)), 'Good afternoon');
      expect(UserProfile.greeting(DateTime(2026, 1, 1, 20)), 'Good evening');
    });

    test('Product.fromSearch maps server rows', () {
      final p = Product.fromSearch({
        'id': 'x',
        'title': 'Fan',
        'location_label': 'Ikeja',
        'availability': '1 week',
        'collateral': 3000,
        'rating_avg': 4.5,
        'rating_count': 2,
        'image_path': 'http://img/a.jpg',
        'owner_id': 'o',
        'owner_name': 'Ada',
        'owner_verified': true,
        'price_per_day': 800,
        'distance_km': 0.4,
        'stock': 2,
        'features': ['a'],
        'kind': 'item',
      });
      expect(p.name, 'Fan');
      expect(p.collateralLabel, '3,000 Collateral');
      expect(p.priceLabel, '₦800/day');
      expect(p.distanceLabel, '400 m away');
      expect(p.availabilityDays, 7);
      expect(p.gallery, ['http://img/a.jpg']);
    });

    test('Txn labels are human friendly', () {
      Txn t(String s) => Txn(
          id: '1',
          kind: 'borrow',
          title: 't',
          state: s,
          amount: 100,
          collateral: 50,
          payerId: 'a',
          payeeId: 'b');
      expect(t('payment_pending').stateLabel, 'Awaiting payment');
      expect(t('escrow_held').stateLabel, 'Payment secured in escrow');
      expect(t('released').stateLabel, 'Completed');
      expect(t('x').total, 150);
    });

    test('Plan perks come straight from the server', () {
      final p = Plan.fromRow({
        'id': 'a',
        'name': 'Active',
        'emoji': '✅',
        'price_ngn': 500,
        'features': ['one', 'two']
      });
      expect(p.perks, ['one', 'two']);
      expect(p.priceLabel, '₦500 /month');
    });

    test('timeLabel formats today as a clock time', () {
      final now = DateTime.now();
      expect(timeLabel(DateTime(now.year, now.month, now.day, 9, 5)), '9:05AM');
      expect(timeLabel(null), '');
    });
  });

  group('chat safety (server verdict is shown, not decided by the app)', () {
    test('blocked message returns the reason', () async {
      final r = await FakeBackend().sendMessage('c1', 'call me 08012345678');
      expect(r.ok, isFalse);
      expect(r.blocked, isTrue);
      expect(r.error, contains('phone numbers'));
    });
  });
}
