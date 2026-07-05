import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

void main() {
  runApp(const ProviderScope(child: TkAdminApp()));
}

/// Panel Admin (Flutter Web) — identitas warna hijau gelap keabuan #0F5C3E
/// (design-tokens.md § Identitas warna per aplikasi).
/// A1-A6 dibangun pada milestone berikutnya.
class TkAdminApp extends StatelessWidget {
  const TkAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuntaskilat — Panel Admin',
      debugShowCheckedModeBanner: false,
      theme: TkTheme.light(identity: TkColors.identityAdmin),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TkColors.identityAdmin,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Panel Admin',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TkColors.surface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A1-A6 — milestone berikutnya',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: TkColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
