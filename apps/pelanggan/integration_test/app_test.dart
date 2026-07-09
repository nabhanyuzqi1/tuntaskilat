import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tk_pelanggan/main.dart' as app;
import 'package:tk_core/tk_core.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Black-box UI & Functional Testing (Pelanggan)', () {
    testWidgets('Tuntaskilat Onboarding and Authentication Flow', (WidgetTester tester) async {
      // 1. Launch the application
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen (P1SplashScreen) to load Firebase and transition (min 1100ms)
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // 2. Handle Onboarding if it shows up
      final lewatiFinder = find.text('Lewati');
      if (lewatiFinder.evaluate().isNotEmpty) {
        debugPrint('--- Skipping Onboarding ---');
        await tester.tap(lewatiFinder);
        await tester.pumpAndSettle();
      }

      // 3. Verify we are on P2AuthScreen
      debugPrint('--- Verifying Auth Screen Loaded ---');
      expect(find.text('Selamat Datang'), findsOneWidget);
      expect(find.text('Layanan kebersihan on-demand untuk rumah Anda.'), findsOneWidget);

      // Find the email and password text fields
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2)); // Email and Password fields

      // 4. Skenario Black-Box 2: Input Validator (Karakter Ilegal/Format Salah)
      debugPrint('--- Testing Invalid Inputs Validator ---');
      await tester.enterText(textFields.at(0), 'invalid-email-format');
      await tester.enterText(textFields.at(1), 'short'); // Password too short
      await tester.pumpAndSettle();

      // Tap the 'Masuk' button
      final tombolMasuk = find.widgetWithText(TkButton, 'Masuk');
      await tester.tap(tombolMasuk);
      await tester.pumpAndSettle();

      // Verify validator triggers error messages
      expect(find.text('Email tidak valid'), findsOneWidget);
      expect(find.text('Kata sandi minimal 8 karakter'), findsOneWidget);

      // 5. Test Authentication with Valid Demo Credentials (Black-Box Skenario 5)
      debugPrint('--- Logging in with Demo Credentials ---');
      await tester.enterText(textFields.at(0), 'pelanggan@tuntaskilat.id');
      await tester.enterText(textFields.at(1), 'Pelanggan123');
      await tester.pumpAndSettle();

      // Clear validator warnings by pressing 'Masuk' again
      await tester.tap(tombolMasuk);
      
      // Wait for Firebase auth to complete and transition to Beranda (P3BerandaScreen)
      // Since this makes a real network request, we wait up to 5 seconds
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // 6. Verify we are on HomeShell (Beranda Screen P3)
      debugPrint('--- Verifying Beranda Screen ---');
      expect(find.text('Pilih Layanan Kebersihan'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      
      debugPrint('--- Integration Test Selesai & Sukses! ---');
    });
  });
}
