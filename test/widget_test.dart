import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paddock_pass/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WilliamsApp());

    // Karena aplikasi kamu tidak pakai counter bawaan,
    // kita cukup tes apakah widget utama berhasil di-build.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
