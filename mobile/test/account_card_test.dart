import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odaklan/features/account/account.dart';
import 'package:odaklan/features/account/account_card.dart';

Widget _host({Account? signedIn}) => ProviderScope(
  overrides: [
    if (signedIn != null)
      accountProvider.overrideWithValue(AsyncData(signedIn)),
  ],
  child: const MaterialApp(home: Scaffold(body: AccountCard())),
);

void main() {
  testWidgets('build without keys: guest, no sign-in button', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();
    expect(find.text('Misafir'), findsOneWidget);
    expect(find.text('Hesaplar bu sürümde kapalı.'), findsOneWidget);
    expect(find.text('Google ile giriş'), findsNothing);
  });

  testWidgets('signed in: nickname, email and sign-out', (tester) async {
    await tester.pumpWidget(
      _host(signedIn: (id: 'u1', email: 'a@b.co', nickname: 'Odakçı0042')),
    );
    expect(find.text('Odakçı0042'), findsOneWidget);
    expect(find.text('a@b.co'), findsOneWidget);
    expect(find.text('Çıkış'), findsOneWidget);
  });
}
