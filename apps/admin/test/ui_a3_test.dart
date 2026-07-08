import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/screens/a3_kelola_pesanan_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Test A3 dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: A3KelolaPesananScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });
}
