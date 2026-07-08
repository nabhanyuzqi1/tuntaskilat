import '../models/pricing.dart';
import '../models/service_model.dart';
import '../models/voucher_model.dart';

/// Katalog layanan sesuai **Pricelist TK** (Jasa Rumput + Home Cleaning).
/// Ini lapisan produk nyata (harga dinamis) — di luar naskah TA yang memakai
/// contoh fixed pricing. Dipakai untuk mengisi koleksi `services`.
List<ServiceModel> katalogSeed() => [
      // ---------- Jasa Rumput: per m² bertingkat ----------
      const ServiceModel(
        serviceId: 'jasa_rumput',
        namaLayanan: 'Jasa Potong Rumput',
        deskripsi:
            'Perapihan rumput & lahan. Tarif per meter persegi menyesuaikan '
            'kondisi lahan.',
        harga: 1200,
        satuan: 'm²',
        aktif: true,
        ikon: 'grass',
        tipeHarga: TipeHarga.perLuas,
        kategori: 'rumput',
        gambar: 'rumput',
        tiers: [
          TarifTier(
              id: 'ringan',
              nama: 'Perapihan rumput ringan (tanpa angkut)',
              hargaPerM2: 1200),
          TarifTier(
              id: 'sedang',
              nama: 'Rumput rumah, gulma, ilalang rendah',
              hargaPerM2: 1800),
          TarifTier(
              id: 'tinggi',
              nama: 'Ilalang tinggi, rumput gajah & akar liar',
              hargaPerM2: 2800),
          TarifTier(
              id: 'berat',
              nama: 'Semak kayu, belukar & tunas pohon',
              hargaPerM2: 4000),
        ],
      ),
      const ServiceModel(
        serviceId: 'semprot_gulma',
        namaLayanan: 'Semprot Gulma (Herbisida)',
        deskripsi: 'Penyemprotan herbisida untuk menekan pertumbuhan gulma.',
        harga: 25000,
        satuan: 'area',
        aktif: true,
        ikon: 'sanitizer',
        tipeHarga: TipeHarga.mulaiDari,
        kategori: 'rumput',
        gambar: 'rumput',
      ),
      const ServiceModel(
        serviceId: 'potong_dahan',
        namaLayanan: 'Pemotongan Dahan & Ranting',
        deskripsi: 'Pemangkasan dahan dan ranting pohon.',
        harga: 75000,
        satuan: 'pekerjaan',
        aktif: true,
        ikon: 'content_cut',
        tipeHarga: TipeHarga.mulaiDari,
        kategori: 'rumput',
        gambar: 'rumput',
      ),
      const ServiceModel(
        serviceId: 'angkut_rumput',
        namaLayanan: 'Penyapuan & Angkut Sisa Rumput',
        deskripsi: 'Pembersihan dan pengangkutan sisa potongan rumput.',
        harga: 60000,
        satuan: 'pekerjaan',
        aktif: true,
        ikon: 'delete_sweep',
        tipeHarga: TipeHarga.mulaiDari,
        kategori: 'rumput',
        gambar: 'rumput',
      ),

      // ---------- Home Cleaning: paket + durasi + add-on ----------
      const ServiceModel(
        serviceId: 'home_cleaning',
        namaLayanan: 'Home Cleaning',
        deskripsi:
            'Pembersihan rumah oleh petugas terlatih. Pilih paket, durasi, '
            'dan layanan tambahan sesuai kebutuhan.',
        harga: 90000,
        satuan: 'paket',
        aktif: true,
        ikon: 'cleaning_services',
        tipeHarga: TipeHarga.paket,
        kategori: 'home_cleaning',
        gambar: 'cleaning',
        paketOpsi: [
          PaketOpsi(
            id: 'reguler',
            nama: 'Reguler',
            jumlahPetugas: 1,
            hargaTambahJam: 35000,
            durasi: [
              DurasiOpsi(jam: 2, harga: 90000),
              DurasiOpsi(jam: 3, harga: 130000),
            ],
            spesifikasi: [
              'Sapu & pel lantai',
              'Rapikan barang & permukaan',
              'Cuci peralatan dapur ringan',
              'Lap kaca & debu terlihat',
            ],
          ),
          PaketOpsi(
            id: 'detail',
            nama: 'Detail Bersih',
            jumlahPetugas: 2,
            hargaTambahJam: 70000,
            durasi: [
              DurasiOpsi(jam: 2, harga: 180000),
              DurasiOpsi(jam: 3, harga: 260000),
            ],
            spesifikasi: [
              'Vacuum, sapu & pel menyeluruh',
              'Lap debu sela & sudut',
              'Penataan ulang ringan ruangan',
              'Pembersihan kaca lebih detail',
            ],
          ),
        ],
        addOns: [
          AddOn(id: 'km_ringan', nama: 'Kamar mandi ringan', harga: 35000),
          AddOn(id: 'km_kerak', nama: 'Kamar mandi kerak / lumut', harga: 75000),
          AddOn(id: 'lemari', nama: 'Bagian dalam lemari', harga: 25000),
          AddOn(id: 'kulkas', nama: 'Bagian dalam kulkas', harga: 25000),
          AddOn(id: 'vacum_sofa', nama: 'Vacum sofa', harga: 30000),
          AddOn(id: 'vacum_kasur', nama: 'Vacum kasur', harga: 30000),
          AddOn(id: 'cuci_piring', nama: 'Cuci piring banyak menumpuk', harga: 25000),
          AddOn(id: 'kaca_tinggi', nama: 'Kaca banyak & tinggi', harga: 25000),
          AddOn(id: 'tangga', nama: 'Tangga / area bertingkat', harga: 25000),
          AddOn(id: 'dapur_minyak', nama: 'Area dapur berminyak', harga: 35000),
        ],
      ),
    ];

/// Voucher contoh untuk memulai program promo. Kelola lebih lanjut via Admin.
List<VoucherModel> voucherSeed() => [
      const VoucherModel(
        voucherId: 'WELCOME15',
        kode: 'WELCOME15',
        tipe: TipeVoucher.persen,
        nilai: 15,
        deskripsi: 'Diskon 15% pelanggan baru (maks Rp20.000).',
        minBelanja: 50000,
        maxPotongan: 20000,
        kuota: 200,
      ),
      const VoucherModel(
        voucherId: 'HEMAT20',
        kode: 'HEMAT20',
        tipe: TipeVoucher.persen,
        nilai: 20,
        deskripsi: 'Diskon 20% (maks Rp25.000).',
        minBelanja: 100000,
        maxPotongan: 25000,
        kuota: 100,
      ),
      const VoucherModel(
        voucherId: 'POTONG10K',
        kode: 'POTONG10K',
        tipe: TipeVoucher.nominal,
        nilai: 10000,
        deskripsi: 'Potongan langsung Rp10.000.',
        minBelanja: 75000,
        kuota: 150,
      ),
    ];
