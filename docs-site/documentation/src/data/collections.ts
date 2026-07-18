export type Field = { name: string; type: string; desc?: string }
export type EnumDef = { name: string; values: string }
export type CollectionDef = {
  id: string
  path: string
  model: string
  desc: string
  fields: Field[]
  enums?: EnumDef[]
  note?: string
}

export const COLLECTIONS: CollectionDef[] = [
  {
    id: 'users',
    path: 'users/{userId}',
    model: 'UserModel',
    desc: 'One document per account, docId = Firebase Auth UID. Shared shape across all 3 roles.',
    fields: [
      { name: 'nama', type: 'string' },
      { name: 'email', type: 'string' },
      { name: 'noTelepon', type: 'string' },
      { name: 'alamat', type: 'string' },
      { name: 'role', type: 'UserRole' },
      { name: 'fotoUrl', type: 'string' },
      { name: 'nonaktif', type: 'bool', desc: 'company-deactivated account flag' },
      { name: 'kodeReferal', type: 'string', desc: 'deterministic 6-char base32 hash of uid, prefixed TK' },
      { name: 'referredBy', type: 'string', desc: 'referral code entered at signup' },
    ],
    enums: [{ name: 'UserRole', values: 'pelanggan | kru | admin' }],
    note: 'Subcollection users/{uid}/alamat: { label, alamat, lokasi: GeoPoint } — saved addresses.',
  },
  {
    id: 'services',
    path: 'services/{serviceId}',
    model: 'ServiceModel',
    desc: 'Catalog of bookable cleaning services with dynamic pricing.',
    fields: [
      { name: 'namaLayanan', type: 'string' },
      { name: 'deskripsi', type: 'string' },
      { name: 'harga', type: 'num', desc: 'base / "starting from" price' },
      { name: 'satuan', type: 'string', desc: 'per jam | per ruangan | per m2' },
      { name: 'aktif', type: 'bool' },
      { name: 'kategori', type: 'string', desc: 'rumput | home_cleaning | umum' },
      { name: 'gambarUrl', type: 'string' },
      { name: 'tipeHarga', type: 'TipeHarga' },
      { name: 'tiers', type: 'TarifTier[]', desc: '{ id, nama, hargaPerM2 } — for per_luas pricing' },
      { name: 'paketOpsi', type: 'PaketOpsi[]', desc: '{ id, nama, jumlahPetugas, durasi[], hargaTambahJam, spesifikasi }' },
      { name: 'addOns', type: 'AddOn[]', desc: '{ id, nama, harga }' },
      { name: 'jumlahKru', type: 'num', desc: 'capacity — maintained by Cloud Function, never written by admin edits' },
    ],
    enums: [{ name: 'TipeHarga', values: 'per_luas | paket | mulai_dari' }],
  },
  {
    id: 'orders',
    path: 'orders/{orderId}',
    model: 'OrderModel',
    desc: 'The central document — every transaction and its full lifecycle.',
    fields: [
      { name: 'userId', type: 'string' },
      { name: 'serviceId', type: 'string' },
      { name: 'cleanerId', type: 'string', desc: 'lead crew member, "" = unassigned' },
      { name: 'tanggalPesan / jadwal', type: 'Timestamp' },
      { name: 'totalHarga / subtotal / potongan', type: 'num', desc: 'totalHarga = subtotal − potongan' },
      { name: 'status', type: 'OrderStatus' },
      { name: 'penugasan', type: 'Penugasan[]', desc: '{ cleanerId, nama, peran, sudahKonfirmasi, diterima, fotoUrl }' },
      { name: 'kruIds', type: 'string[]', desc: 'for array-contains queries' },
      { name: 'metodePembayaran', type: 'MetodeBayar' },
      { name: 'voucherKode / rincian', type: 'string / BarisRincian[]' },
      { name: 'fotoSebelum / fotoSesudah', type: 'string[]', desc: 'work-report photos' },
      { name: 'slotId', type: 'string', desc: 'written manually, not in toMap() — links to the capacity slot' },
      { name: 'kasTunaiDibukukan', type: 'bool', desc: 'idempotency guard for cash-commission booking' },
    ],
    enums: [
      { name: 'OrderStatus', values: 'dibuat → menunggu_pembayaran → menunggu_verifikasi → (ditolak ↩ | terverifikasi) → menunggu_penugasan → ditugaskan → dalam_perjalanan → diproses → selesai → dinilai, + dibatalkan' },
      { name: 'MetodeBayar', values: 'transfer_bank | qris | tunai' },
    ],
  },
  {
    id: 'payments',
    path: 'payments/{paymentId}',
    model: 'PaymentModel',
    desc: 'Payment proof + verification status. Xendit adds ad-hoc gateway/invoiceId/invoiceUrl fields not in the Dart model.',
    fields: [
      { name: 'orderId / userId', type: 'string' },
      { name: 'metode', type: 'MetodeBayar' },
      { name: 'jumlah', type: 'num' },
      { name: 'buktiBayar', type: 'string?', desc: 'Storage URL' },
      { name: 'statusBayar', type: 'StatusBayar' },
    ],
    enums: [{ name: 'StatusBayar', values: 'menunggu | terverifikasi | ditolak' }],
  },
  {
    id: 'payouts',
    path: 'payouts/{orderId}_{cleanerId}',
    model: 'PayoutModel',
    desc: 'Crew wage ledger — immutable to clients once created. Money is never trusted from the client after this point.',
    fields: [
      { name: 'orderId / cleanerId / namaKru', type: 'string' },
      { name: 'peran', type: 'PeranKru' },
      { name: 'jumlah', type: 'num' },
      { name: 'status', type: 'StatusPayout' },
    ],
    enums: [
      { name: 'PeranKru', values: 'worker (weight 1.0) | helper (weight 0.6)' },
      { name: 'StatusPayout', values: 'pending | dibayar | ditahan' },
    ],
  },
  {
    id: 'kru',
    path: 'kru/{cleanerId}',
    model: 'KruModel',
    desc: 'Crew profile, docId = Firebase Auth UID.',
    fields: [
      { name: 'nama / noTelepon / fotoUrl', type: 'string' },
      { name: 'statusKetersediaan', type: 'bool', desc: 'online/offline toggle' },
      { name: 'posisi', type: 'GeoPoint?', desc: 'live location, streamed while dalam_perjalanan' },
      { name: 'rataRating / jumlahUlasan', type: 'num', desc: 'server-authoritative, recomputed on every review' },
      { name: 'fcmTokens', type: 'string[]' },
      { name: 'keahlian', type: 'string[]', desc: 'serviceIds — empty array = generalist (eligible for all services)' },
      { name: 'tipe', type: 'KruTipe' },
      { name: 'status', type: 'StatusKru', desc: 'only aktif is assignable' },
      { name: 'rekening', type: 'RekeningKru', desc: '{ jenis: bank|ewallet, penyedia, nomor, atasNama }' },
    ],
    enums: [
      { name: 'KruTipe', values: 'kru | mitra | vendor' },
      { name: 'StatusKru', values: 'aktif | nonaktif | diberhentikan' },
    ],
  },
  {
    id: 'kaskru',
    path: 'kasKru/{cleanerId}',
    model: 'KasKru',
    desc: 'Cash-deposit ledger — how much commission from cash-paid jobs a crew member is still holding.',
    fields: [
      { name: 'namaKru', type: 'string' },
      { name: 'saldoTunai', type: 'int', desc: '≥ 0. Invariant: saldoTunai == totalMasuk − totalSetor' },
      { name: 'batasNunggak', type: 'int', desc: 'default 200000 (Rp) — arrears threshold' },
      { name: 'totalMasuk / totalSetor', type: 'int', desc: 'lifetime accumulated in / deposited out' },
    ],
    note: 'setoran/{setoranId}: { cleanerId, namaKru, jumlah, diterimaOleh, waktu, catatan } — immutable deposit history.',
  },
  {
    id: 'vouchers',
    path: 'vouchers/{kode}',
    model: 'VoucherModel',
    desc: 'docId = uppercase code.',
    fields: [
      { name: 'tipe', type: 'TipeVoucher' },
      { name: 'nilai', type: 'num', desc: 'percent or fixed amount depending on tipe' },
      { name: 'minBelanja / maxPotongan', type: 'num', desc: 'maxPotongan 0 = unbounded' },
      { name: 'kuota / terpakai', type: 'int', desc: 'kuota 0 = unlimited' },
      { name: 'berlakuHingga', type: 'string?', desc: 'ISO date' },
      { name: 'khususPenggunaBaru', type: 'bool' },
      { name: 'sekaliPerNomor', type: 'bool', desc: 'default true — locks claim per phone number, not per uid' },
    ],
    enums: [{ name: 'TipeVoucher', values: 'persen | nominal' }],
    note: "voucherUsages/{kode}__{telepon}: anti-abuse lock, immutable to the user once created.",
  },
  {
    id: 'reviews',
    path: 'reviews/{reviewId}',
    model: 'ReviewModel',
    desc: 'Public — every review re-aggregates the rated crew member\'s kru.rataRating server-side (onReviewCreate).',
    fields: [
      { name: 'orderId / userId / cleanerId', type: 'string' },
      { name: 'penilaian', type: 'num', desc: '1–5' },
      { name: 'komentar / namaPelanggan', type: 'string' },
    ],
  },
  {
    id: 'notifications',
    path: 'notifications/{id}',
    model: 'NotificationModel',
    desc: 'In-app notification feed, mirrors FCM pushes.',
    fields: [
      { name: 'userId', type: 'string', desc: 'recipient' },
      { name: 'judul / pesan', type: 'string' },
      { name: 'dibaca', type: 'bool' },
      { name: 'orderId', type: 'string?', desc: 'deep-link target' },
    ],
  },
  {
    id: 'disputes',
    path: 'disputes/{disputeId}',
    model: 'DisputeModel',
    desc: 'Appeals over work quality or payout amount.',
    fields: [
      { name: 'orderId / pengajuId / pengajuNama', type: 'string' },
      { name: 'pengaju', type: 'PengajuBanding' },
      { name: 'status', type: 'StatusBanding' },
      { name: 'alasan / catatanAdmin', type: 'string' },
      { name: 'buktiUrl', type: 'string?' },
    ],
    enums: [
      { name: 'PengajuBanding', values: 'kru | pelanggan' },
      { name: 'StatusBanding', values: 'diajukan | diterima | ditolak' },
    ],
  },
  {
    id: 'banners-broadcasts',
    path: 'banners/{id} · broadcasts/{id}',
    model: 'BannerModel · (none)',
    desc: 'Two unrelated concepts despite the similar name — see the AI/Notifications pages for how each is used.',
    fields: [
      { name: 'banners.judul / subjudul / badge / gambarUrl / isi / tautan / urutan / aktif', type: '—', desc: 'persistent, admin-curated promo content shown on the Beranda' },
      { name: 'broadcasts.judul / pesan / terkirim / tanpaToken / selesaiPada', type: '—', desc: 'one-shot marketing push blast to all pelanggan, no dedicated model class' },
    ],
  },
  {
    id: 'settings',
    path: 'settings/{docId}',
    model: 'various',
    desc: 'Runtime configuration, admin-controlled. See individual docIds below.',
    fields: [
      { name: 'komisi', type: 'KonfigKomisi', desc: 'global commission % + per-service overrides' },
      { name: 'pembayaran', type: 'KonfigPembayaran', desc: 'which payment methods are active/static/dynamic' },
      { name: 'app', type: 'KonfigApp', desc: 'maintenance mode / forced update — publicly readable' },
      { name: 'ai', type: 'KonfigAi', desc: 'provider + API keys for AI features — admin-only, secret' },
      { name: 'referral', type: '{ nominal, minBelanja, masaBerlakuHari }', desc: 'referral reward configuration' },
    ],
  },
  {
    id: 'referralclaims',
    path: 'referralClaims/{telepon}',
    model: '(none)',
    desc: 'One document per phone number, ever — the anti-abuse lock for the referral program.',
    fields: [
      { name: 'telepon / buyerId / referrerId', type: 'string' },
      { name: 'kodeReferal / voucherKode', type: 'string' },
    ],
  },
  {
    id: 'admin2fa',
    path: 'admin2fa/{uid}',
    model: '(none)',
    desc: 'TOTP secret for admin 2FA. Owner-only read/write.',
    fields: [
      { name: 'secret', type: 'string' },
      { name: 'aktif', type: 'bool' },
    ],
  },
  {
    id: 'slots',
    path: 'slots/{slotId}',
    model: '(none)',
    desc: 'Capacity counter backing the atomic-locking booking mechanism.',
    fields: [
      { name: 'serviceId / jadwal', type: 'string / Timestamp' },
      { name: 'terisi / kapasitas', type: 'num', desc: 'terisi can only be incremented by exactly +1 per client write (rule-enforced); decrements are admin-SDK only' },
    ],
  },
]
