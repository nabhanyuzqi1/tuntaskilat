import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// P17 — Detail Banner/Promo. Konten (gambar + judul + isi) datang dari
/// dokumen `banners` yang dikelola admin secara realtime; tombol
/// "Selengkapnya" membuka [BannerModel.tautan] bila diisi.
class P17BannerDetailScreen extends StatelessWidget {
  const P17BannerDetailScreen({super.key});

  static const route = '/p17';

  @override
  Widget build(BuildContext context) {
    final banner = ModalRoute.of(context)!.settings.arguments as BannerModel;

    return Scaffold(
      backgroundColor: TkColors.surface,
      appBar: AppBar(
        title: Text('Info & Promo',
            style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TkColors.inkSoft)),
        backgroundColor: TkColors.surface,
        foregroundColor: TkColors.inkSoft,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          if (banner.gambarUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(TkRadius.card),
              child: Image.network(
                banner.gambarUrl,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          if (banner.badge.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TkColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(banner.badge.toUpperCase(),
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: TkColors.onAccent)),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(banner.judul,
              style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft,
                  height: 1.3)),
          if (banner.subjudul.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(banner.subjudul,
                style: GoogleFonts.montserrat(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: TkColors.primary)),
          ],
          const SizedBox(height: 14),
          Text(
            banner.isi.isEmpty
                ? 'Ikuti terus info dan promo terbaru Tuntaskilat di sini.'
                : banner.isi,
            style: GoogleFonts.montserrat(
                fontSize: 14, color: TkColors.textSecondary, height: 1.65),
          ),
          if (banner.tautan.isNotEmpty) ...[
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: TkButton(
                label: 'Selengkapnya',
                onPressed: () => launchUrl(Uri.parse(banner.tautan),
                    mode: LaunchMode.externalApplication),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
