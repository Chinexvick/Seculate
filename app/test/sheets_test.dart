import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seculate/core/widgets/location_sheet.dart';
import 'package:seculate/core/widgets/price_sheet.dart';
import 'package:seculate/data/ng_locations.dart';

Widget _host(Future<void> Function(BuildContext) open) => MaterialApp(
      home: Builder(
          builder: (c) => Scaffold(
                body: Center(
                    child: TextButton(
                        onPressed: () => open(c), child: const Text('open'))),
              )),
    );

void main() {
  test('location list covers all states and more than Lagos/Abuja', () {
    final all = allNgLocations();
    expect(ngLocationsByState.length, 37);
    expect(all.length, greaterThan(300));
    expect(all.first, 'Lekki, Lagos');
    expect(all, contains('Port Harcourt, Rivers'));
    expect(all, contains('Maitama, Abuja'));
  });

  testWidgets('price sheet accepts any typed amount with no cap',
      (tester) async {
    PriceFilter? out;
    await tester.pumpWidget(_host((c) async {
      out = await showPriceSheet(c, current: PriceFilter.none);
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '500');
    await tester.enterText(fields.at(1), '2500000');
    await tester.pump();
    expect(find.text('2,500,000'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(out, const PriceFilter(from: 500, to: 2500000));
  });

  testWidgets('location sheet lets you add a custom location', (tester) async {
    String? out;
    await tester.pumpWidget(_host((c) async {
      out = await showLocationSheet(c);
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-location')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ogudu GRA, Lagos');
    await tester.pump();
    await tester.tap(find.text('Use this location'));
    await tester.pumpAndSettle();
    expect(out, 'Ogudu GRA, Lagos');
  });
}
