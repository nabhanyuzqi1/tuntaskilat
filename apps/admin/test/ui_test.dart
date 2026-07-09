import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tk_admin/screens/a7_voucher_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Test A7 rendering', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Row(children: [
              Expanded(
                child: IndexedStack(
                  index: 4,
                  children: [
                    Container(),
                    Container(),
                    Container(),
                    Container(),
                    A7VoucherScreen(),
                  ],
                )
              )
            ])
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kelola Voucher'), findsOneWidget);
  });
}
