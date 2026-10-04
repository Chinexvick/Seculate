import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seculate/app/routes.dart';
import 'package:seculate/core/theme/app_theme.dart';
import 'package:seculate/data/models.dart';
import 'package:seculate/features/chat/chat_screen.dart';

import 'support/fakes.dart';

/// Every screen renders with realistic data (no overflow / build errors).
final _cases = <String, Object?>{
  Routes.logIn: null,
  Routes.signUp: null,
  Routes.forgotPassword: null,
  Routes.home: null,
  Routes.search: null,
  Routes.notifications: null,
  Routes.allChats: null,
  Routes.chat: ChatArgs(const Person(id: 'u2', name: 'Chijioke Okafor'),
      conversationId: 'c1'),
  Routes.borrowRequest: fixtureProducts.first,
  Routes.itemDetail: fixtureProducts.first,
  Routes.listItem: null,
  Routes.postService: null,
  Routes.upgrade: null,
  Routes.pricing: null,
  Routes.profile: null,
  Routes.editProfile: null,
  Routes.myListings: null,
  Routes.userSettings: null,
  Routes.businessDetails: null,
  Routes.companyDetails: null,
  Routes.confirmPhone: null,
  Routes.changeEmail: null,
  Routes.changeLanguage: null,
  Routes.chatToggle: null,
  Routes.feedbackToggle: null,
  Routes.manageNotifications: null,
  Routes.changePassword: null,
  Routes.deleteAccount: null,
  Routes.support: null,
  Routes.supportChat: null,
  Routes.serviceDetail: fixtureTasks.first,
  Routes.lenderProfile:
      const Person(id: 'owner-1', name: 'Jacob Jones', verified: true),
  Routes.personalDetails: null,
  Routes.identityVerification: null,
  Routes.locationGate: null,
  Routes.accountBlocked: null,
  Routes.transaction: 'tx1',
  Routes.transactions: null,
};

Future<void> _loadPoppins() async {
  final loader = FontLoader('Poppins');
  for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold', 'Italic']) {
    final bytes = File('assets/fonts/Poppins-$f.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadPoppins);
  setUp(installFakes);
  _cases.forEach((route, args) {
    testWidgets('renders $route without errors', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: (s) =>
            Routes.generate(RouteSettings(name: route, arguments: args)),
        initialRoute: route,
      ));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
    });
  });
}
