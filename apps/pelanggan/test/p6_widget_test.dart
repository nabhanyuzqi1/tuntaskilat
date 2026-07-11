import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tk_core/tk_core.dart';
import 'package:tk_pelanggan/providers/pemesanan_providers.dart';
import 'package:tk_pelanggan/screens/p6_rincian_tagihan_screen.dart';

// Reproduksi Bug 9: body P6 blank di device. Test ini memastikan seluruh
// kartu body (rincian, voucher, jadwal) benar-benar dirender dari draft valid.
void main() {
  const layanan = ServiceModel(
    serviceId: 'bersih-rumah',
    namaLayanan: 'Bersih Rumah',
    deskripsi: '',
    harga: 25000,
    satuan: 'ruang',
    aktif: true,
    ikon: 'cleaning_services',
  );

  final draft = DraftPesanan(
    layanan: layanan,
    pilihan: const PilihanHarga(kuantitas: 3),
    tanggal: DateTime(2026, 7, 12),
    jam: 10,
    alamat: 'Sampit, Kotawaringin Timur',
    lokasi: const GeoPoint(-2.5329, 112.9508),
  );

  testWidgets('P6 merender kartu rincian, voucher, dan jadwal', (t) async {
    // Viewport tinggi agar seluruh kartu ListView ter-layout (lazy).
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          draftPesananProvider.overrideWith((ref) => draft),
        ],
        child: const MaterialApp(home: P6RincianTagihanScreen()),
      ),
    );
    await t.pump();

    expect(find.text('Rincian Tagihan'), findsOneWidget); // header
    expect(find.text('Rincian Biaya'), findsOneWidget); // kartu 2
    expect(find.text('Voucher'), findsOneWidget); // kartu voucher
    expect(find.text('Jadwal & Alamat'), findsOneWidget); // kartu 4
    expect(find.text('Lanjut Bayar'), findsOneWidget); // footer
  });
}
