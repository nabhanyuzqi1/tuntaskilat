
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tk_core/tk_core.dart';

import 'app_providers.dart';
import 'beranda_providers.dart';

/// Slot terisi pada hari tertentu — dipakai P5 untuk menampilkan slot
/// disabled + ikon gembok (kaidah Pencegahan Kesalahan).
final slotTerisiProvider = StreamProvider.autoDispose
    .family<Set<DateTime>, ({String serviceId, DateTime hari})>((ref, args) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const {});
  return ref.watch(firestoreServiceProvider).watchSlotTerisi(args.serviceId, args.hari);
});

/// Draft pemesanan (P5) — dipegang sementara sampai pelanggan konfirmasi
/// pembayaran di P7. Order + kunci slot BARU dibuat saat bayar, sehingga
/// pelanggan bebas kembali/mengedit tanpa menyandera jadwal atau membuat
/// order ganda.
class DraftPesanan {
  const DraftPesanan({
    required this.layanan,
    required this.pilihan,
    this.tanggal,
    this.jam,
    this.alamat = '',
    this.lokasi,
    this.catatan = '',
    this.voucherKode = '',
    this.voucher,
  });

  final ServiceModel layanan;

  /// Pilihan harga dinamis (tier/luas, paket/durasi/add-on, atau kuantitas).
  final PilihanHarga pilihan;
  final DateTime? tanggal;
  final int? jam;
  final String alamat;
  final GeoPoint? lokasi;
  final String catatan;

  /// Voucher yang diterapkan pelanggan (kosong bila tak ada).
  final String voucherKode;
  final VoucherModel? voucher;

  DateTime? get jadwal => tanggal == null || jam == null
      ? null
      : DateTime(tanggal!.year, tanggal!.month, tanggal!.day, jam!);

  /// Rincian + subtotal dari model (sumber kebenaran sama dgn backend).
  HasilHarga get hasil => layanan.hitungHarga(pilihan);
  num get subtotal => hasil.subtotal;

  /// Potongan voucher (pratinjau; backend memvalidasi ulang saat bayar).
  num get potongan => voucher == null
      ? 0
      : voucher!.hitungPotongan(subtotal, DateTime.now()).potongan;

  num get total => subtotal - potongan;

  bool get lengkap => jadwal != null &&
      alamat.trim().isNotEmpty &&
      lokasi != null &&
      subtotal > 0;

  DraftPesanan salin({
    PilihanHarga? pilihan,
    DateTime? tanggal,
    int? jam,
    String? alamat,
    GeoPoint? lokasi,
    String? catatan,
    String? voucherKode,
    VoucherModel? voucher,
    bool hapusJam = false,
    bool hapusVoucher = false,
  }) =>
      DraftPesanan(
        layanan: layanan,
        pilihan: pilihan ?? this.pilihan,
        tanggal: tanggal ?? this.tanggal,
        jam: hapusJam ? null : (jam ?? this.jam),
        alamat: alamat ?? this.alamat,
        lokasi: lokasi ?? this.lokasi,
        catatan: catatan ?? this.catatan,
        voucherKode: hapusVoucher ? '' : (voucherKode ?? this.voucherKode),
        voucher: hapusVoucher ? null : (voucher ?? this.voucher),
      );
}

/// Draft aktif. Diisi saat pelanggan membuka P5 dari P4, dipertahankan saat
/// bolak-balik P5↔P6↔P7, dan dibersihkan setelah pesanan sukses dibuat.
final draftPesananProvider = StateProvider<DraftPesanan?>((_) => null);

/// Alamat tersimpan pelanggan (subkoleksi) untuk picker cepat di P5.
final alamatTersimpanProvider =
    StreamProvider.autoDispose.family<List<AlamatModel>, String>((ref, uid) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchAlamat(uid);
});

/// Hasil upaya pembuatan pesanan+pembayaran (P7).
typedef HasilPesan = ({OrderModel? order, String? error, bool jadwalPenuh});

class PembayaranController extends AutoDisposeAsyncNotifier<OrderModel?> {
  @override
  Future<OrderModel?> build() async => null;

  /// Konfirmasi pembayaran → buat order + payment dalam satu transaction
  /// (Atomic Locking di titik bayar). Bukti (non-tunai) diunggah ke Storage
  /// lebih dulu; harga dihitung ulang di backend (skenario #6).
  Future<HasilPesan> konfirmasi({
    required DraftPesanan draft,
    required MetodeBayar metode,
    Uint8List? buktiBytes,
  }) async {
    if (!ref.read(firebaseSiapProvider)) {
      return (
        order: null,
        error: 'Terjadi kendala. Coba beberapa saat lagi.',
        jadwalPenuh: false
      );
    }
    if (!draft.lengkap) {
      return (
        order: null,
        error: 'Lengkapi jadwal dan alamat terlebih dahulu.',
        jadwalPenuh: false
      );
    }
    if (metode != MetodeBayar.tunai && buktiBytes == null) {
      return (
        order: null,
        error: 'Unggah bukti transfer terlebih dahulu.',
        jadwalPenuh: false
      );
    }
    final profil = await ref.read(profilSayaProvider.future);
    if (profil == null) {
      return (
        order: null,
        error: 'Sesi Anda berakhir. Silakan masuk kembali.',
        jadwalPenuh: false
      );
    }

    state = const AsyncLoading();
    try {
      String? buktiUrl;
      if (buktiBytes != null) {
        buktiUrl = await ref.read(storageServiceProvider).uploadBuktiBayar(
              userId: profil.userId,
              orderId: FirestoreService.slotOrderId(
                  draft.layanan.serviceId, draft.jadwal!),
              bytes: buktiBytes,
            );
      }
      final order = await ref.read(firestoreServiceProvider).buatPesananLengkap(
            pelanggan: profil,
            serviceId: draft.layanan.serviceId,
            jadwal: draft.jadwal!,
            pilihan: draft.pilihan,
            alamatLayanan: draft.alamat.trim(),
            lokasi: draft.lokasi!,
            metode: metode,
            voucherKode: draft.voucherKode,
            buktiBayar: buktiUrl,
            catatan: draft.catatan.trim(),
          );
      state = AsyncData(order);
      // Konteks Crashlytics — bila ada crash di alur lacak/bayar, tim tahu
      // order mana yang bermasalah.
      unawaited(setKunciCrash('orderId', order.orderId));
      // Simpan alamat terakhir agar bisa dipilih cepat lain kali (dedupe
      // berdasar teks). Gagal simpan tidak menggagalkan pemesanan.
      unawaited(_simpanAlamatTerakhir(profil.userId, draft));
      return (order: order, error: null, jadwalPenuh: false);
    } on JadwalPenuhException {
      state = const AsyncData(null);
      return (order: null, error: 'Jadwal Penuh', jadwalPenuh: true);
    } on TidakAdaKruException {
      // Semua kru pada jam itu terpakai / belum ada kru untuk layanan ini.
      state = const AsyncData(null);
      return (order: null, error: 'Jadwal Penuh', jadwalPenuh: true);
    } on VoucherException catch (e) {
      state = const AsyncData(null);
      return (order: null, error: e.toString(), jadwalPenuh: false);
    } on LuarWilayahLayananException {
      state = const AsyncData(null);
      return (
        order: null,
        error: 'Lokasi Anda di luar area layanan Kota Sampit '
            '(Out of Delivery Range).',
        jadwalPenuh: false
      );
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException saat konfirmasi: $e\n$stack');
      state = const AsyncData(null);
      return (
        order: null,
        error: 'Gagal diproses: ${e.message ?? e.toString()}',
        jadwalPenuh: false
      );
    } catch (e, stack) {
      debugPrint('Error tak terduga saat konfirmasi: $e\n$stack');
      state = const AsyncData(null);
      return (
        order: null,
        error: 'Pembayaran belum dapat diproses. Periksa koneksi Anda '
            'lalu coba lagi. ($e)',
        jadwalPenuh: false
      );
    }
  }

  /// Simpan/refresh alamat "Terakhir Dipakai" tanpa duplikat teks.
  Future<void> _simpanAlamatTerakhir(String uid, DraftPesanan draft) async {
    try {
      final svc = ref.read(firestoreServiceProvider);
      final ada = await svc.watchAlamat(uid).first;
      if (ada.any((a) => a.alamat.trim() == draft.alamat.trim())) return;
      await svc.simpanAlamat(
        uid,
        AlamatModel(
          id: '',
          label: 'Terakhir Dipakai',
          alamat: draft.alamat.trim(),
          lokasi: draft.lokasi!,
        ),
      );
    } catch (_) {
      // abaikan — fitur kenyamanan, bukan kritis
    }
  }
}

final pembayaranControllerProvider =
    AsyncNotifierProvider.autoDispose<PembayaranController, OrderModel?>(
        PembayaranController.new);
