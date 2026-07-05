import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

void main() {
  runApp(const ProviderScope(child: TkKruApp()));
}

/// Portal Kru — identitas warna hijau tua #006542
/// (design-tokens.md § Identitas warna per aplikasi).
/// KO1-KO3 + K1-K6 dibangun pada milestone berikutnya.
class TkKruApp extends StatelessWidget {
  const TkKruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuntaskilat — Portal Kru',
      debugShowCheckedModeBanner: false,
      theme: TkTheme.light(identity: TkColors.identityKru),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TkColors.identityKru,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Portal Kru',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TkColors.surface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'KO1-KO3 + K1-K6 — milestone berikutnya',
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
