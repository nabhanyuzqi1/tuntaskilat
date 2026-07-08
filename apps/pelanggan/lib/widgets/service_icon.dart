import 'package:flutter/material.dart';

/// Pemetaan field `services.ikon` (identifier ikon Material Design,
/// firestore-schema.md) ke IconData. Identifier di luar daftar memakai
/// ikon kebersihan umum.
IconData serviceIcon(String ikon) => switch (ikon) {
      'cleaning_services' => Icons.cleaning_services_outlined,
      'weekend' || 'chair' => Icons.weekend_outlined,
      'window' => Icons.window_outlined,
      'ac_unit' => Icons.ac_unit_rounded,
      'local_laundry_service' => Icons.local_laundry_service_outlined,
      'yard' || 'grass' => Icons.yard_outlined,
      'kitchen' => Icons.kitchen_outlined,
      'bathtub' => Icons.bathtub_outlined,
      'pest_control' => Icons.pest_control_outlined,
      'sanitizer' => Icons.sanitizer_outlined,
      'content_cut' => Icons.content_cut_rounded,
      'delete_sweep' => Icons.delete_sweep_outlined,
      _ => Icons.cleaning_services_outlined,
    };

/// Ilustrasi brand: gradasi hijau/kuning per kategori layanan, dipakai sebagai
/// latar kartu/hero (aset offline, tanpa masalah lisensi).
LinearGradient serviceGradient(String kategori) => switch (kategori) {
      'rumput' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A874D), Color(0xFF39A935)]),
      'home_cleaning' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E9E7E), Color(0xFF0A874D)]),
      _ => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A874D), Color(0xFF006542)]),
    };

/// Satuan skema ("per ruangan") → label ringkas lencana harga ("ruang"),
/// mengikuti gaya Hi-Fi ("Rp 25.000 /ruang").
String satuanSingkat(String satuan) {
  final tanpaPer = satuan.replaceFirst(RegExp(r'^per\s+'), '');
  return switch (tanpaPer) {
    'ruangan' => 'ruang',
    'm2' => 'm²',
    _ => tanpaPer,
  };
}
