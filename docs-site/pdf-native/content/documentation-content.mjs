// Content transcribed from docs-site/documentation/src/pages/*.tsx

export const HOME = {
  slug: 'overview', eyebrow: 'Technical Documentation', title: 'Tuntaskilat Developer Reference',
  description: 'On-demand home cleaning service platform — 3 Flutter client apps (Customer, Worker, Admin) on a shared Firebase backend. This reference covers the data model, Cloud Functions API, security rules, and business logic that power it.',
  blocks: [
    { type: 'stats', items: [
      { n: '3', label: 'Client Apps' }, { n: '22', label: 'Cloud Functions' },
      { n: '20+', label: 'Firestore Collections' }, { n: '1', label: 'Shared Package (tk_core)' },
    ] },
    { type: 'subHeading', text: 'Tech Stack' },
    { type: 'code', title: 'stack.yaml', code:
`client:
  framework: Flutter 3.41
  state: Riverpod 2.6
  language: Dart 3.11
  apps: [pelanggan, kru, admin]
  shared_package: packages/tk_core

backend:
  platform: Firebase
  functions: Node.js 20 (2nd Gen), TypeScript
  region: asia-southeast2
  database: Cloud Firestore (NoSQL, document-based)
  auth: Firebase Authentication (email/password + Google)
  storage: Cloud Storage
  messaging: Firebase Cloud Messaging (FCM)

integrations:
  ai: [Gemini, OpenAI, Anthropic]      # multi-provider, admin-configurable
  payments: [transfer_bank, qris, tunai, xendit]
  whatsapp: Fonnte` },
  ],
};

export const GETTING_STARTED = {
  slug: 'getting-started', eyebrow: 'Introduction', title: 'Getting Started',
  description: 'Clone the monorepo, install dependencies, and get all three apps running locally.',
  blocks: [
    { type: 'subHeading', text: 'Prerequisites' },
    { type: 'paragraph', text: "You'll need the following tools installed:" },
    { type: 'code', code:
`Flutter SDK    3.41.x (stable channel)
Dart SDK       3.11.x
Node.js        20.x
Firebase CLI   latest  (npm i -g firebase-tools)
A Firebase project with Firestore, Auth, Storage, Functions, FCM enabled` },
    { type: 'subHeading', text: 'Repository Structure' },
    { type: 'paragraph', text: 'This is a Flutter pub workspace monorepo — one Git repository, multiple apps sharing a common package:' },
    { type: 'code', code:
`tkapps/
|-- apps/
|   |-- pelanggan/     # Customer app (Android)
|   |-- kru/            # Worker app (Android)
|   \\-- admin/          # Admin panel (Flutter Web)
|-- packages/
|   \\-- tk_core/         # Shared models, services, theme, widgets
|-- firebase/
|   |-- functions/       # Cloud Functions (TypeScript)
|   |-- firestore.rules
|   \\-- storage.rules
|-- docs-site/
|   |-- manualbook/       # This site's sibling — end-user manual
|   \\-- documentation/    # You are here
|-- firebase.json         # Hosting targets, functions, rules
\\-- pubspec.yaml           # Workspace root` },
    { type: 'subHeading', text: 'Local Setup' },
    { type: 'code', code:
`git clone https://github.com/nabhanyuzqi1/tuntaskilat.git
cd tuntaskilat

# Flutter workspace — installs deps for all 3 apps + tk_core at once
flutter pub get

# Cloud Functions
cd firebase/functions
npm install
cd ../..

# Connect to your own Firebase project (or use the existing one)
firebase use --add` },
    { type: 'callout', kind: 'info', text: 'Each app needs its own firebase_options.dart, generated via flutterfire configure — run it once per app (apps/pelanggan, apps/kru, apps/admin).' },
    { type: 'subHeading', text: 'Running Each App' },
    { type: 'code', code:
`# Customer app (Android emulator/device)
cd apps/pelanggan && flutter run

# Worker app
cd apps/kru && flutter run

# Admin panel (web)
cd apps/admin && flutter run -d chrome

# Cloud Functions emulator
cd firebase && firebase emulators:start --only firestore,functions` },
    { type: 'subHeading', text: 'Testing' },
    { type: 'code', code:
`# Unit + widget tests (business logic, pricing, security scenarios)
flutter test packages/tk_core
flutter test apps/admin

# Static analysis across the workspace
flutter analyze packages/tk_core apps/admin apps/pelanggan apps/kru

# Cloud Functions type-check
cd firebase/functions && npx tsc -p .` },
  ],
};

export const ARCHITECTURE = {
  slug: 'architecture', eyebrow: 'Introduction', title: 'Architecture',
  description: 'A monorepo of 3 Flutter clients sharing one package, backed by Firebase — Firestore as the source of truth, Cloud Functions as the money-critical safety net.',
  blocks: [
    { type: 'subHeading', text: 'System Overview' },
    { type: 'paragraph', text: 'Every client writes optimistically via a Firestore transaction (client-side pricing/locking), and every write of consequence is re-validated by a Cloud Function running with the Admin SDK — which bypasses Security Rules and is treated as the single source of truth for money. The client is a preview; the server is authoritative.' },
    { type: 'code', code:
`+------------+   +------------+   +------------+
| Pelanggan  |   |    Kru     |   |   Admin    |
| (Android)  |   | (Android)  |   |   (Web)    |
+-----+------+   +-----+------+   +-----+------+
      |                |                |
      +--------+-------+-------+--------+
               |                |
        packages/tk_core (models, services, theme)
               |
+--------------+---------------------------------+
|                    Firebase                     |
| Firestore, Auth, Storage, FCM                   |
| Cloud Functions (asia-southeast2)               |
+--------------+---------------------------------+
               |
+--------------+---------------------------------+
| Xendit, Fonnte (WA), AI providers               |
| (Gemini / OpenAI / Anthropic)                   |
+--------------------------------------------------+` },
    { type: 'subHeading', text: 'Client Applications' },
    { type: 'table', head: ['App', 'Platform', 'Users', 'Purpose'], widths: [90, 60, 70, '*'], rows: [
      ['apps/pelanggan', 'Android', 'Customers', 'Browse services, book, pay, track, review, chat, AI CS.'],
      ['apps/kru', 'Android', 'Field crew', 'Accept jobs, navigate, report work, manage cash deposits.'],
      ['apps/admin', 'Flutter Web', 'Staff/owner', 'Manage orders, catalog, crew, vouchers, commission, operations.'],
    ] },
    { type: 'subHeading', text: 'Shared Package (tk_core)' },
    { type: 'rich', parts: [{ code: 'packages/tk_core' }, ' holds everything that must stay consistent across apps: Firestore models & enums, the ', { code: 'FirestoreService' }, ' facade (all reads/writes/transactions), auth flow, theme tokens (colors, typography, radius), and shared widgets. No app talks to Firestore directly — everything routes through ', { code: 'tk_core' }, '.'] },
    { type: 'subHeading', text: 'Backend Services' },
    { type: 'table', head: ['Service', 'Role'], widths: [110, '*'], rows: [
      ['Cloud Firestore', 'Document-based NoSQL database — the system of record for orders, users, payments, etc.'],
      ['Firebase Auth', 'Email/password + Google sign-in. Role (pelanggan/kru/admin) stored on the users document, not in Auth claims.'],
      ['Cloud Storage', 'Payment proof uploads, work-report photos, profile photos, service images.'],
      ['Cloud Functions', '22 functions (Node.js 20, TypeScript, region asia-southeast2) — triggers, scheduled jobs, and callables.'],
      ['FCM', 'Push notifications for order status changes, chat messages, assignment reminders, broadcasts.'],
    ] },
    { type: 'subHeading', text: 'Auth & Roles' },
    { type: 'rich', parts: ['A single ', { code: 'UserRole' }, ' enum (', { code: 'pelanggan' }, ' | ', { code: 'kru' }, ' | ', { code: 'admin' }, ') gates which app an account can log into. ', { code: 'AuthService.signIn()' }, ' checks the role against the app performing the login and signs the session out immediately on a mismatch (a pelanggan account cannot log into the Kru portal, etc.) — this check exists both client-side and mirrored in Security Rules.'] },
    { type: 'table', head: ['Role', 'Self-registration?', 'How the account is created'], widths: [70, 90, '*'], rows: [
      ['pelanggan', 'Yes', 'registerPelanggan() — email/password or Google sign-in, self-service.'],
      ['kru', 'No', "Admin only, via A5 -> AkunKruService.buatAkunKru() (uses a secondary Firebase App instance so the admin's own session is never disturbed)."],
      ['admin', 'No', 'Existing admin only, via the buatAdmin callable Cloud Function (admin.auth().createUser() server-side).'],
    ] },
    { type: 'callout', kind: 'info', text: 'Admin accounts can additionally require TOTP 2FA (RFC 6238) at login — secret stored in admin2fa/{uid}, owner-only read/write.' },
    { type: 'subHeading', text: 'Atomic Locking Pattern' },
    { type: 'paragraph', text: 'Booking a time slot is a classic race condition — two customers could both read "slot open" and both write a booking. Tuntaskilat solves this without a dedicated locking service, using a Firestore transaction against a capacity counter:' },
    { type: 'code', title: 'simplified booking transaction', code:
`await db.runTransaction(async (tx) => {
  const slotSnap = await tx.get(slotRef)
  const { terisi = 0, kapasitas } = slotSnap.data() ?? {}

  if (terisi >= kapasitas) throw new JadwalPenuhException()

  // Firestore rule enforces this write can ONLY increment by exactly 1
  tx.set(slotRef, { terisi: terisi + 1, kapasitas }, { merge: true })
  tx.set(orderRef, order.toMap())
})` },
    { type: 'rich', parts: [{ code: 'kapasitas' }, " (capacity) is not a fixed number — it's recomputed automatically whenever crew data changes (see ", { code: 'recomputeKapasitasLayanan()' }, ' in the Functions reference), so booking availability always reflects how many eligible crew are actually active for that service.'] },
  ],
};

export const DATA_MODEL = {
  slug: 'data-model', eyebrow: 'API Reference', title: 'Data Model',
  description: 'Every Firestore collection Tuntaskilat writes to — field names, types, and enum values, sourced directly from packages/tk_core/lib/models/.',
  blocks: [
    { type: 'rich', parts: ['Model source files live in ', { code: 'packages/tk_core/lib/models/' }, ' — one Dart class per collection, each with typed ', { code: 'fromMap()' }, '/', { code: 'toMap()' }, ' so every read/write goes through the same shape.'] },
    { type: 'subHeading', text: 'users/{userId}' },
    { type: 'paragraph', text: 'UserModel — one document per account, docId = Firebase Auth UID. Shared shape across all 3 roles.' },
    { type: 'fields', items: [
      { name: 'nama', type: 'string' }, { name: 'email', type: 'string' }, { name: 'noTelepon', type: 'string' },
      { name: 'alamat', type: 'string' }, { name: 'role', type: 'UserRole' }, { name: 'fotoUrl', type: 'string' },
      { name: 'nonaktif', type: 'bool', desc: 'company-deactivated account flag' },
      { name: 'kodeReferal', type: 'string', desc: 'deterministic 6-char base32 hash of uid, prefixed TK' },
      { name: 'referredBy', type: 'string', desc: 'referral code entered at signup' },
    ] },
    { type: 'paragraph', text: 'Enum UserRole: pelanggan | kru | admin. Subcollection users/{uid}/alamat: { label, alamat, lokasi: GeoPoint } — saved addresses.' },
    { type: 'subHeading', text: 'services/{serviceId}' },
    { type: 'paragraph', text: 'ServiceModel — catalog of bookable cleaning services with dynamic pricing.' },
    { type: 'fields', items: [
      { name: 'namaLayanan', type: 'string' }, { name: 'deskripsi', type: 'string' },
      { name: 'harga', type: 'num', desc: 'base / "starting from" price' },
      { name: 'satuan', type: 'string', desc: 'per jam | per ruangan | per m2' },
      { name: 'aktif', type: 'bool' }, { name: 'kategori', type: 'string', desc: 'rumput | home_cleaning | umum' },
      { name: 'gambarUrl', type: 'string' }, { name: 'tipeHarga', type: 'TipeHarga' },
      { name: 'tiers', type: 'TarifTier[]', desc: '{ id, nama, hargaPerM2 } — for per_luas pricing' },
      { name: 'paketOpsi', type: 'PaketOpsi[]', desc: '{ id, nama, jumlahPetugas, durasi[], hargaTambahJam, spesifikasi }' },
      { name: 'addOns', type: 'AddOn[]', desc: '{ id, nama, harga }' },
      { name: 'jumlahKru', type: 'num', desc: 'capacity — maintained by Cloud Function, never written by admin edits' },
    ] },
    { type: 'paragraph', text: 'Enum TipeHarga: per_luas | paket | mulai_dari.' },
    { type: 'subHeading', text: 'orders/{orderId}' },
    { type: 'paragraph', text: 'OrderModel — the central document, every transaction and its full lifecycle.' },
    { type: 'fields', items: [
      { name: 'userId', type: 'string' }, { name: 'serviceId', type: 'string' },
      { name: 'cleanerId', type: 'string', desc: 'lead crew member, "" = unassigned' },
      { name: 'tanggalPesan / jadwal', type: 'Timestamp' },
      { name: 'totalHarga / subtotal / potongan', type: 'num', desc: 'totalHarga = subtotal - potongan' },
      { name: 'status', type: 'OrderStatus' },
      { name: 'penugasan', type: 'Penugasan[]', desc: '{ cleanerId, nama, peran, sudahKonfirmasi, diterima, fotoUrl }' },
      { name: 'kruIds', type: 'string[]', desc: 'for array-contains queries' },
      { name: 'metodePembayaran', type: 'MetodeBayar' },
      { name: 'voucherKode / rincian', type: 'string / BarisRincian[]' },
      { name: 'fotoSebelum / fotoSesudah', type: 'string[]', desc: 'work-report photos' },
      { name: 'slotId', type: 'string', desc: 'written manually, not in toMap() — links to the capacity slot' },
      { name: 'kasTunaiDibukukan', type: 'bool', desc: 'idempotency guard for cash-commission booking' },
    ] },
    { type: 'paragraph', text: 'Enum OrderStatus: dibuat -> menunggu_pembayaran -> menunggu_verifikasi -> (ditolak (retry) | terverifikasi) -> menunggu_penugasan -> ditugaskan -> dalam_perjalanan -> diproses -> selesai -> dinilai, + dibatalkan. Enum MetodeBayar: transfer_bank | qris | tunai.' },
    { type: 'subHeading', text: 'payments/{paymentId}' },
    { type: 'paragraph', text: 'PaymentModel — payment proof + verification status. Xendit adds ad-hoc gateway/invoiceId/invoiceUrl fields not in the Dart model.' },
    { type: 'fields', items: [
      { name: 'orderId / userId', type: 'string' }, { name: 'metode', type: 'MetodeBayar' }, { name: 'jumlah', type: 'num' },
      { name: 'buktiBayar', type: 'string?', desc: 'Storage URL' }, { name: 'statusBayar', type: 'StatusBayar' },
    ] },
    { type: 'paragraph', text: 'Enum StatusBayar: menunggu | terverifikasi | ditolak.' },
    { type: 'subHeading', text: 'payouts/{orderId}_{cleanerId}' },
    { type: 'paragraph', text: 'PayoutModel — crew wage ledger, immutable to clients once created. Money is never trusted from the client after this point.' },
    { type: 'fields', items: [
      { name: 'orderId / cleanerId / namaKru', type: 'string' }, { name: 'peran', type: 'PeranKru' },
      { name: 'jumlah', type: 'num' }, { name: 'status', type: 'StatusPayout' },
    ] },
    { type: 'paragraph', text: 'Enum PeranKru: worker (weight 1.0) | helper (weight 0.6). Enum StatusPayout: pending | dibayar | ditahan.' },
    { type: 'subHeading', text: 'kru/{cleanerId}' },
    { type: 'paragraph', text: 'KruModel — crew profile, docId = Firebase Auth UID.' },
    { type: 'fields', items: [
      { name: 'nama / noTelepon / fotoUrl', type: 'string' }, { name: 'statusKetersediaan', type: 'bool', desc: 'online/offline toggle' },
      { name: 'posisi', type: 'GeoPoint?', desc: 'live location, streamed while dalam_perjalanan' },
      { name: 'rataRating / jumlahUlasan', type: 'num', desc: 'server-authoritative, recomputed on every review' },
      { name: 'fcmTokens', type: 'string[]' },
      { name: 'keahlian', type: 'string[]', desc: 'serviceIds — empty array = generalist (eligible for all services)' },
      { name: 'tipe', type: 'KruTipe' }, { name: 'status', type: 'StatusKru', desc: 'only aktif is assignable' },
      { name: 'rekening', type: 'RekeningKru', desc: '{ jenis: bank|ewallet, penyedia, nomor, atasNama }' },
    ] },
    { type: 'paragraph', text: 'Enum KruTipe: kru | mitra | vendor. Enum StatusKru: aktif | nonaktif | diberhentikan.' },
    { type: 'subHeading', text: 'kasKru/{cleanerId}' },
    { type: 'paragraph', text: 'KasKru — cash-deposit ledger, how much commission from cash-paid jobs a crew member is still holding.' },
    { type: 'fields', items: [
      { name: 'namaKru', type: 'string' },
      { name: 'saldoTunai', type: 'int', desc: '>= 0. Invariant: saldoTunai == totalMasuk - totalSetor' },
      { name: 'batasNunggak', type: 'int', desc: 'default 200000 (Rp) — arrears threshold' },
      { name: 'totalMasuk / totalSetor', type: 'int', desc: 'lifetime accumulated in / deposited out' },
    ] },
    { type: 'paragraph', text: 'setoran/{setoranId}: { cleanerId, namaKru, jumlah, diterimaOleh, waktu, catatan } — immutable deposit history.' },
    { type: 'subHeading', text: 'vouchers/{kode}' },
    { type: 'paragraph', text: 'VoucherModel — docId = uppercase code.' },
    { type: 'fields', items: [
      { name: 'tipe', type: 'TipeVoucher' }, { name: 'nilai', type: 'num', desc: 'percent or fixed amount depending on tipe' },
      { name: 'minBelanja / maxPotongan', type: 'num', desc: 'maxPotongan 0 = unbounded' },
      { name: 'kuota / terpakai', type: 'int', desc: 'kuota 0 = unlimited' },
      { name: 'berlakuHingga', type: 'string?', desc: 'ISO date' },
      { name: 'khususPenggunaBaru', type: 'bool' },
      { name: 'sekaliPerNomor', type: 'bool', desc: 'default true — locks claim per phone number, not per uid' },
    ] },
    { type: 'paragraph', text: 'Enum TipeVoucher: persen | nominal. voucherUsages/{kode}__{telepon}: anti-abuse lock, immutable to the user once created.' },
    { type: 'subHeading', text: 'reviews/{reviewId}' },
    { type: 'paragraph', text: "ReviewModel — public, every review re-aggregates the rated crew member's kru.rataRating server-side (onReviewCreate)." },
    { type: 'fields', items: [
      { name: 'orderId / userId / cleanerId', type: 'string' }, { name: 'penilaian', type: 'num', desc: '1-5' }, { name: 'komentar / namaPelanggan', type: 'string' },
    ] },
    { type: 'subHeading', text: 'notifications/{id}' },
    { type: 'paragraph', text: 'NotificationModel — in-app notification feed, mirrors FCM pushes.' },
    { type: 'fields', items: [
      { name: 'userId', type: 'string', desc: 'recipient' }, { name: 'judul / pesan', type: 'string' },
      { name: 'dibaca', type: 'bool' }, { name: 'orderId', type: 'string?', desc: 'deep-link target' },
    ] },
    { type: 'subHeading', text: 'disputes/{disputeId}' },
    { type: 'paragraph', text: 'DisputeModel — appeals over work quality or payout amount.' },
    { type: 'fields', items: [
      { name: 'orderId / pengajuId / pengajuNama', type: 'string' }, { name: 'pengaju', type: 'PengajuBanding' },
      { name: 'status', type: 'StatusBanding' }, { name: 'alasan / catatanAdmin', type: 'string' }, { name: 'buktiUrl', type: 'string?' },
    ] },
    { type: 'paragraph', text: 'Enum PengajuBanding: kru | pelanggan. Enum StatusBanding: diajukan | diterima | ditolak.' },
    { type: 'subHeading', text: 'banners/{id} / broadcasts/{id}' },
    { type: 'paragraph', text: 'BannerModel / (none) — two unrelated concepts despite the similar name. banners: judul/subjudul/badge/gambarUrl/isi/tautan/urutan/aktif — persistent, admin-curated promo content shown on the Beranda. broadcasts: judul/pesan/terkirim/tanpaToken/selesaiPada — one-shot marketing push blast to all pelanggan, no dedicated model class.' },
    { type: 'subHeading', text: 'settings/{docId}' },
    { type: 'paragraph', text: 'Runtime configuration, admin-controlled. See individual docIds below.' },
    { type: 'fields', items: [
      { name: 'komisi', type: 'KonfigKomisi', desc: 'global commission % + per-service overrides' },
      { name: 'pembayaran', type: 'KonfigPembayaran', desc: 'which payment methods are active/static/dynamic' },
      { name: 'app', type: 'KonfigApp', desc: 'maintenance mode / forced update — publicly readable' },
      { name: 'ai', type: 'KonfigAi', desc: 'provider + API keys for AI features — admin-only, secret' },
      { name: 'referral', type: '{ nominal, minBelanja, masaBerlakuHari }', desc: 'referral reward configuration' },
    ] },
    { type: 'subHeading', text: 'referralClaims/{telepon}' },
    { type: 'paragraph', text: 'One document per phone number, ever — the anti-abuse lock for the referral program.' },
    { type: 'fields', items: [
      { name: 'telepon / buyerId / referrerId', type: 'string' }, { name: 'kodeReferal / voucherKode', type: 'string' },
    ] },
    { type: 'subHeading', text: 'admin2fa/{uid} / slots/{slotId}' },
    { type: 'paragraph', text: 'admin2fa: TOTP secret for admin 2FA. Owner-only read/write. slots: capacity counter backing the atomic-locking booking mechanism.' },
    { type: 'fields', items: [
      { name: 'secret', type: 'string' }, { name: 'aktif', type: 'bool' },
      { name: 'serviceId / jadwal', type: 'string / Timestamp' },
      { name: 'terisi / kapasitas', type: 'num', desc: 'terisi can only be incremented by exactly +1 per client write (rule-enforced); decrements are admin-SDK only' },
    ] },
  ],
};

export const FUNCTIONS = {
  slug: 'cloud-functions', eyebrow: 'API Reference', title: 'Cloud Functions',
  description: '22 server-side functions — all running in asia-southeast2 as a safety-net layer that mirrors and validates client-side transactions.',
  blocks: [
    { type: 'callout', kind: 'info', text: 'Every function shares one Firestore admin instance and the REGION = "asia-southeast2" constant, defined in firebase/functions/src/index.ts.' },
    { type: 'subHeading', text: 'Orders & Pricing Integrity' },
    { type: 'functions', items: [
      { name: 'onOrderCreate', trigger: 'onDocumentCreated', path: 'orders/{orderId}', desc: 'Re-reads the service document and recomputes the correct price server-side, correcting the order in place if the client-submitted totalHarga/subtotal/potongan drift by more than Rp1.', note: 'Anti price-tampering: the client computes a preview price for UX, but this function is what actually decides what the customer owes.' },
      { name: 'validatePayment', trigger: 'onDocumentCreated', path: 'payments/{paymentId}', desc: "Confirms payment.jumlah equals the referenced order's totalHarga (tolerance Rp1); corrects it if mismatched." },
      { name: 'onOrderFinalize', trigger: 'onDocumentUpdated', path: 'orders/{orderId}', desc: "Fires on transition into status 'selesai'. Computes crew payouts (weighted split, helper ratio 0.6) and, for cash orders, books the platform commission into the lead crew member's kasKru ledger.", note: 'Idempotent via the kasTunaiDibukukan flag on the order document — cash commission is only ever booked once.' },
      { name: 'onOrderAssigned', trigger: 'onDocumentUpdated', path: 'orders/{orderId}', desc: "Fires on transition into 'ditugaskan'. Sends FCM push to every assigned crew member's fcmTokens, cleaning up invalid tokens." },
      { name: 'onOrderCancelled', trigger: 'onDocumentUpdated', path: 'orders/{orderId}', desc: "Fires on transition into 'dibatalkan'. Decrements the booking slot's terisi counter (or deletes the slot doc) — the only permitted decrement path, since clients can only increment." },
      { name: 'pushStatusPelanggan', trigger: 'onDocumentUpdated', path: 'orders/{orderId}', desc: "Pushes FCM to the customer on every meaningful status transition, with data.tipe='status' for deep-linking into the tracking screen." },
      { name: 'autoCancelTanpaKru', trigger: 'onSchedule', path: 'every 60 minutes (Asia/Makassar)', desc: "Cancels orders stuck in 'terverifikasi'/'menunggu_penugasan' for more than 24 hours with no crew assigned, notifying the customer." },
    ] },
    { type: 'subHeading', text: 'Chat & Notifications' },
    { type: 'functions', items: [
      { name: 'onChatMessageCreate', trigger: 'onDocumentCreated', path: 'orders/{orderId}/messages/{messageId}', desc: 'Determines recipients (pelanggan -> all kruIds; kru -> userId), writes a notification doc, and pushes FCM.' },
      { name: 'reminderKru', trigger: 'onSchedule', path: 'every 30 minutes (Asia/Makassar)', desc: "Finds 'ditugaskan' orders whose jadwal is 90-150 minutes away and sends a reminder push to assigned crew." },
      { name: 'onBroadcastCreate', trigger: 'onDocumentCreated', path: 'broadcasts/{id}', desc: "Mass-pushes an FCM notification to every user with role=='pelanggan', then writes delivery stats back onto the broadcast doc." },
      { name: 'waNotifOrder', trigger: 'onDocumentUpdated', path: 'orders/{orderId}', desc: 'Sends a WhatsApp message via Fonnte for terverifikasi/ditugaskan/selesai status transitions. No-op if FONNTE_TOKEN is unset.' },
    ] },
    { type: 'subHeading', text: 'Reviews & Capacity' },
    { type: 'functions', items: [
      { name: 'onReviewCreate', trigger: 'onDocumentCreated', path: 'reviews/{reviewId}', desc: 'Re-aggregates ALL reviews for the rated cleanerId and overwrites kru/{cleanerId}.rataRating / jumlahUlasan — server-authoritative, never client-computed.' },
      { name: 'onKruDitulis', trigger: 'onDocumentWritten', path: 'kru/{cleanerId}', desc: 'Any create/update/delete of a crew doc triggers recomputeKapasitasLayanan().' },
      { name: 'onLayananDibuat', trigger: 'onDocumentCreated', path: 'services/{serviceId}', desc: 'A new service triggers recomputeKapasitasLayanan() so jumlahKru is populated immediately.' },
      { name: 'backfillKapasitasKru', trigger: 'onCall', path: 'admin-only', desc: 'Manually forces a full recompute of service capacities — used after bulk keahlian edits.' },
    ] },
    { type: 'subHeading', text: 'Admin & Referral' },
    { type: 'functions', items: [
      { name: 'buatAdmin', trigger: 'onCall', path: 'admin-only', desc: 'Input { email, password, nama }. Creates a Firebase Auth user + users doc (role: admin) without disturbing the caller\'s session. Returns { uid }.' },
      { name: 'setNonaktifAdmin', trigger: 'onCall', path: 'admin-only', desc: 'Input { uid, nonaktif }. Disables/enables the target Auth account. Cannot target self (failed-precondition).' },
      { name: 'rewardReferral', trigger: 'onDocumentUpdated', path: 'orders/{orderId}', desc: "On a buyer's first completed order, mints a reward voucher for the referrer, guarded by a transaction on referralClaims/{phone} — one claim per phone number, ever." },
    ] },
    { type: 'subHeading', text: 'Payments (Xendit)' },
    { type: 'functions', items: [
      { name: 'xenditWebhook', trigger: 'onRequest', path: 'HTTP endpoint', desc: "Validates x-callback-token, then on status PAID/SETTLED marks the matching payment & order 'terverifikasi'. Returns 501 if XENDIT_CALLBACK_TOKEN is unset." },
      { name: 'buatTagihanXendit', trigger: 'onCall', path: 'auth required', desc: 'Input { orderId, amount }. Verifies order ownership, calls the Xendit Invoices API, persists invoiceUrl/invoiceId on the payment doc. Requires XENDIT_SECRET_KEY.' },
    ] },
    { type: 'subHeading', text: 'AI' },
    { type: 'functions', items: [
      { name: 'csAi', trigger: 'onCall', path: 'auth required', desc: 'Input { pertanyaan, orderId? }. Multi-provider chat (Gemini/OpenAI/Anthropic) grounded in the live service catalog + the caller\'s own order status. Returns { jawaban }.' },
      { name: 'analisaBisnisAi', trigger: 'onCall', path: 'admin-only', desc: 'Aggregates the trailing 30 days of orders (numerically, server-side) and asks the configured LLM for a concise business summary + action suggestions. Returns { ringkasan }.' },
    ] },
    { type: 'subHeading', text: 'Shared Helpers' },
    { type: 'paragraph', text: 'Two utilities worth knowing when reading the source:' },
    { type: 'code', code:
`// Reads settings/komisi — perLayanan[serviceId] override, else global, clamped 0-100.
async function komisiPersenUntuk(serviceId: string): Promise<number>

// Recomputes services.jumlahKru = count of active kru (status undefined/null/'aktif')
// whose keahlian is empty (generalist) or includes the serviceId. Drives the
// capacity-based booking slot mechanism.
async function recomputeKapasitasLayanan(): Promise<void>` },
  ],
};

export const SECURITY_RULES = {
  slug: 'security-rules', eyebrow: 'API Reference', title: 'Security Rules',
  description: 'firebase/firestore.rules — the second line of defense alongside Cloud Functions. Read/write access per collection.',
  blocks: [
    { type: 'subHeading', text: 'Helper Functions' },
    { type: 'code', code:
`function isSignedIn() { return request.auth != null; }
function role() { return get(/databases/$(db)/documents/users/$(request.auth.uid)).data.role; }
function isOwner(uid) { return isSignedIn() && request.auth.uid == uid; }
function isAdmin() { return isSignedIn() && role() == 'admin'; }` },
    { type: 'subHeading', text: 'Access Control Matrix' },
    { type: 'table', head: ['Collection', 'Read', 'Create', 'Update', 'Delete'], widths: [95, 90, 100, '*', 45], rows: [
      ['users/{userId}', 'owner or admin', 'owner only', 'owner or admin', 'admin'],
      ['services', 'public', '—', 'admin', 'admin'],
      ['slots/{slotId}', 'any signed-in', 'signed-in, terisi must be exactly +1', 'same rule, or admin', 'admin'],
      ['orders/{orderId}', 'participant or admin', 'signed-in owner; price fields must match services', 'admin, or participant limited to status/photos/cancellation', 'admin'],
      ['orders/{id}/messages', 'participant or admin', 'participant or admin', '—', '—'],
      ['kru/{cleanerId}', 'public', 'admin', 'owner/admin, or signed-in diff-only on rating fields', 'admin'],
      ['settings/ai', 'admin only', 'admin', 'admin', 'admin'],
      ["settings/{other}", "signed-in, or public if docId=='app'", 'admin', 'admin', 'admin'],
      ['payments', 'owner or admin', 'signed-in owner', 'admin only', '—'],
      ['reviews', 'public', 'signed-in owner', 'admin', 'admin'],
      ['notifications', 'owner', 'any signed-in (ideally server-written)', '—', '—'],
      ['vouchers/{kode}', 'signed-in', 'admin', 'admin, or diff-only terpakai == old+1', 'admin'],
      ['voucherUsages', 'get: any signed-in; list: admin/owner', 'signed-in owner', 'admin', 'admin'],
      ['broadcasts / banners', 'admin / public', 'admin', 'admin', 'admin'],
      ['admin2fa/{uid}', 'owner', 'owner', 'owner', 'owner'],
      ['payouts', 'admin or owning cleaner', 'admin or signed-in (in completion tx)', 'admin', 'admin'],
      ['kasKru', 'admin or owning cleaner', '—', 'admin only', 'admin'],
      ['setoran', 'admin or owning cleaner', 'admin', 'admin', 'admin'],
      ['referralClaims', 'admin or any signed-in', '—', 'admin only', 'admin'],
      ['disputes', 'admin or the filer', 'signed-in filer, status must be diajukan', 'admin', 'admin'],
    ] },
    { type: 'subHeading', text: 'Key Invariants' },
    { type: 'callout', kind: 'warning', text: "Order money/ownership fields are immutable to non-admins once created — a client can only ever touch ['status', 'fotoSebelum', 'fotoSesudah', 'penugasan'] on an existing order, and cancellation is only permitted from pre-assignment statuses." },
    { type: 'paragraph', text: 'Other write-shape constraints enforced at the rules layer:' },
    { type: 'list', items: [
      'Slot terisi can only be incremented by exactly +1 per client write — decrements are admin-SDK only (the atomic-locking mechanism).',
      'Voucher terpakai can only increment by exactly 1 per write.',
      'kru rating fields (rataRating, jumlahUlasan) can only move via a controlled delta matching a genuine review submission.',
      'kasKru balances are never client-writable — only Cloud Functions (admin SDK, which bypasses rules entirely) or admin-authenticated writes can change them.',
    ] },
  ],
};

export const BUSINESS_LOGIC = {
  slug: 'business-logic', eyebrow: 'Business Logic', title: 'Commission & Payouts',
  description: 'The exact algorithms behind money in Tuntaskilat — every formula here is enforced server-side, never trusted from the client.',
  blocks: [
    { type: 'subHeading', text: 'Wage Splitting — bagiUpah()' },
    { type: 'rich', parts: [{ code: 'packages/tk_core/lib/models/wage.dart' }, " — splits a completed order's total between platform commission and crew, weighted by role."] },
    { type: 'code', code:
`totalInt   = round(total)
komisi     = round(totalInt * komisiPersen / 100)     // platform commission
pool       = totalInt - komisi                          // remaining for crew
totalBobot = sum(peran.bobot for each crew member)       // worker=1.0, helper=0.6

for each crew member p:
    bagian[p] = floor(pool * p.peran.bobot / totalBobot)

sisa = pool - sum(bagian)                                 // rounding remainder
bagian[crew.first] += sisa                                // remainder -> lead/first member

# Guarantee: komisi + sum(bagian) == total, exactly. No Rupiah lost or created.` },
    { type: 'callout', kind: 'warning', text: "The server-side onOrderFinalize Cloud Function reimplements the same weighted split inline, but rounds each share individually rather than floor + remainder-to-first — so its per-share numbers can differ from the client's bagiUpah() preview by +/-1 for the same input. The client value is only a preview; the Cloud Function is authoritative for actual payouts." },
    { type: 'subHeading', text: 'Commission Config — KonfigKomisi' },
    { type: 'code', code: 'persenUntuk(serviceId) = clamp(perLayanan[serviceId] ?? komisiPersen, 0, 100)' },
    { type: 'rich', parts: ['Mirrored server-side as ', { code: 'komisiPersenUntuk(serviceId)' }, ', reading ', { code: 'settings/komisi' }, '. Global default is 20%.'] },
    { type: 'subHeading', text: 'Cash Deposit Ledger — KasKru' },
    { type: 'paragraph', text: "For cash-paid orders, the crew member collects the full amount from the customer in person — but the platform's commission share is still owed. That amount is tracked as a debt (saldoTunai) the crew must periodically settle with the office." },
    { type: 'code', code:
`saldoTunai = totalMasuk - totalSetor           // audit invariant
bolehTerimaTunai = saldoTunai <= batasNunggak   // default batasNunggak = Rp200,000` },
    { type: 'rich', parts: [{ code: 'saldoTunai' }, ' increases exactly once per cash order, booked by ', { code: 'onOrderFinalize' }, ' (guarded by the ', { code: 'kasTunaiDibukukan' }, ' flag) — no client path can write it directly (Security Rules restrict kasKru writes to admin). It decreases only when an admin records a deposit via ', { code: 'terimaSetoran()' }, ', which runs inside a transaction that rejects any deposit amount exceeding the current balance.'] },
    { type: 'subHeading', text: 'Voucher Discount Formula' },
    { type: 'code', code:
`if !aktif                              -> reject 'nonaktif'
if now > berlakuHingga                 -> reject 'kadaluwarsa'
if sisaKuota <= 0                      -> reject 'kuotaHabis'   // sisaKuota = kuota<=0 ? unbounded : kuota-terpakai
if subtotal < minBelanja               -> reject 'minimalBelanja'

potongan = tipe=='persen' ? subtotal * nilai / 100 : nilai
if tipe=='persen' && maxPotongan>0 && potongan>maxPotongan
    potongan = maxPotongan
if potongan > subtotal
    potongan = subtotal` },
    { type: 'rich', parts: ['The server-side ', { code: 'potonganFormulaVoucher()' }, ' applies the same nominal-cap math WITHOUT the kuota/expiry/aktif gates (those are enforced client-side inside the booking transaction) — its purpose is purely to cap the claimed amount: ', { code: 'potonganBenar = min(potonganKlien, formulaMax)' }, ', preventing a client from claiming more discount than the voucher\'s own math allows.'] },
    { type: 'subHeading', text: 'Voucher Anti-Abuse' },
    { type: 'rich', parts: ['Two independent guards inside ', { code: 'buatPesananLengkap()' }, ':'] },
    { type: 'subHeading2', text: 'New-user-only vouchers' },
    { type: 'rich', parts: ['Checked ', { code: 'outside' }, ' the transaction (a query for any prior order by ', { code: 'userId' }, ') — if the user has ordered before, throws ', { code: 'VoucherException(hanyaPenggunaBaru)' }, '.'] },
    { type: 'subHeading2', text: 'Per-phone-number lock' },
    { type: 'rich', parts: ['Doc ID ', { code: 'voucherUsages/{kode}__{normalizedPhone}' }, ' (phone normalized: ', { code: '0xxxx -> 62xxxx' }, ', non-digits stripped). Inside the transaction, if that doc already exists -> reject. This is keyed on phone number, not uid — specifically to prevent the "make a new account, reuse the phone number" abuse vector. ', { code: 'voucher.terpakai' }, ' is incremented by exactly 1 in the same transaction, matching the Security Rules constraint.'] },
    { type: 'subHeading', text: 'Capacity-Based Slots' },
    { type: 'rich', parts: ['Replaces a legacy boolean "taken" lock with a live counter. ', { code: 'services.jumlahKru' }, ' — maintained by ', { code: 'recomputeKapasitasLayanan()' }, ', triggered by ', { code: 'onKruDitulis' }, ' / ', { code: 'onLayananDibuat' }, ' / ', { code: 'backfillKapasitasKru' }, ' — is the count of active crew eligible for that service (empty keahlian = generalist, or keahlian includes the serviceId). This becomes the hourly booking capacity.'] },
    { type: 'code', code:
`kapasitas = services.jumlahKru  (fallback 1 if field absent)
terisi >= kapasitas   -> JadwalPenuhException
kapasitas <= 0        -> TidakAdaKruException` },
    { type: 'rich', parts: ['A service with zero eligible crew is fully locked for booking. Cancellation (', { code: 'onOrderCancelled' }, ') decrements ', { code: 'terisi' }, ' via the admin SDK — the only permitted decrement path.'] },
    { type: 'subHeading', text: 'Cash Arrears Guard' },
    { type: 'code', code:
`if (order.tunai && !await bolehTerimaTunai(lead.cleanerId)) {
  throw KruNunggakException(lead.nama);
}` },
    { type: 'rich', parts: ['Before assigning a cash-payment order to a lead crew member, ', { code: 'tugaskanKruMulti()' }, ' checks ', { code: 'kasKru/{lead}.bolehTerimaTunai' }, '. A crew member who has accumulated more than the arrears threshold in un-deposited cash commission cannot be assigned new cash-paying jobs until they settle up.'] },
  ],
};

export const PAYMENTS = {
  slug: 'payments', eyebrow: 'Integrations', title: 'Payments & Gateway',
  description: 'Payment methods are pluggable — a manual verification flow ships by default, with Xendit available as an opt-in dynamic gateway.',
  blocks: [
    { type: 'subHeading', text: 'Gateway Abstraction' },
    { type: 'rich', parts: [{ code: 'packages/tk_core/lib/services/payment_gateway.dart' }, ' defines a ', { code: 'PaymentGateway' }, ' interface to avoid vendor lock-in:'] },
    { type: 'code', code:
`abstract class PaymentGateway {
  Future<InstruksiBayar> buatInstruksi({
    required String orderId,
    required int jumlah,
    required MetodeBayar metode,
  });
  String get nama;
}

class StaticGateway implements PaymentGateway { ... }  // active by default
class XenditGateway implements PaymentGateway { ... }   // opt-in` },
    { type: 'subHeading', text: 'Static vs. Dynamic' },
    { type: 'table', head: ['', 'StaticGateway', 'XenditGateway'], widths: [90, '*', '*'], rows: [
      ['Instructions', 'Fixed bank account / QRIS image from settings/pembayaran', 'Per-order dynamic VA / QRIS from Xendit'],
      ['Verification', 'Manual — customer uploads proof, admin approves/rejects', 'Automatic — settled via webhook'],
      ['Requires', 'Nothing extra (default MVP flow)', 'XENDIT_SECRET_KEY + XENDIT_CALLBACK_TOKEN env vars'],
      ['Status if unconfigured', 'Always available', 'buatTagihanXendit throws failed-precondition; xenditWebhook returns HTTP 501'],
    ] },
    { type: 'callout', kind: 'info', text: "Both paths land on the same payments collection and once terverifikasi, feed into the same commission / payout calculation — they're layered, not competing systems." },
    { type: 'subHeading', text: 'Xendit Flow' },
    { type: 'code', code:
`1. Customer selects a Xendit-backed method at checkout
2. App calls buatTagihanXendit({ orderId, amount })
     -> verifies caller owns the order
     -> POST https://api.xendit.co/v2/invoices  (Basic auth from XENDIT_SECRET_KEY)
     -> persists { gateway, invoiceId, invoiceUrl } on the payment doc
     -> returns invoiceUrl for the app to open
3. Customer completes payment on Xendit's hosted page
4. Xendit calls xenditWebhook with x-callback-token + { external_id: orderId, status }
     -> validates token (401 if wrong)
     -> on PAID/SETTLED: payments.statusBayar = 'terverifikasi', orders.status = 'terverifikasi'` },
    { type: 'subHeading', text: 'Commission vs. Payment Config — Two Different Things' },
    { type: 'rich', parts: ['It\'s easy to confuse ', { code: 'settings/komisi' }, ' and ', { code: 'settings/pembayaran' }, ' because both live under "money settings" in the admin panel — but they govern orthogonal concerns:'] },
    { type: 'table', head: ['Setting', 'Controls'], widths: [110, '*'], rows: [
      ['settings/komisi', "The platform's revenue-share percentage taken from each completed order, used by bagiUpah/onOrderFinalize to split money between platform and crew."],
      ['settings/pembayaran', 'Which customer-facing payment methods are offered and whether each is statis (manual) or dinamis (Xendit).'],
    ] },
    { type: 'paragraph', text: 'A dinamis payment method still goes through the same commission calculation once the order completes — the two systems are layered, not competing.' },
  ],
};

export const AI = {
  slug: 'ai', eyebrow: 'Integrations', title: 'AI Features',
  description: 'Two AI-powered callables — a customer-facing support chat and an admin-facing business analyst — both provider-agnostic.',
  blocks: [
    { type: 'subHeading', text: 'Multi-Provider Config' },
    { type: 'rich', parts: [{ code: 'settings/ai' }, ' (admin-only, read/write) selects which provider is active and holds its key:'] },
    { type: 'table', head: ['Field', 'Notes'], widths: [140, '*'], rows: [
      ['provider', 'gemini | openai | anthropic'],
      ['geminiApiKey / openaiApiKey / anthropicApiKey', 'per-provider key field; falls back to env vars (GEMINI_API_KEY, etc.) if empty'],
      ['model', 'defaults: gemini-2.0-flash, gpt-4o-mini, claude-haiku-4-5'],
      ['aktif', 'master on/off switch'],
    ] },
    { type: 'callout', kind: 'warning', text: 'Because keys fall back to environment variables, a deployed env var can silently supply a key even if the admin panel shows none configured — worth checking both when debugging "AI not responding".' },
    { type: 'rich', parts: ['A single dispatcher, ', { code: 'panggilAi()' }, ", routes to the correct REST endpoint per provider: Gemini's ", { code: 'generateContent' }, " (key in query string), OpenAI's ", { code: '/chat/completions' }, ", or Anthropic's ", { code: '/v1/messages' }, '.'] },
    { type: 'subHeading', text: 'Customer Service AI — csAi' },
    { type: 'code', code: `// onCall, auth required
Input:  { pertanyaan: string, orderId?: string }
Output: { jawaban: string }` },
    { type: 'rich', parts: ['The system prompt is grounded in the live active-service catalog and prices, fixed operating hours (08.00-19.00 WIB), the 3 payment methods, and cancellation policy. If ', { code: 'orderId' }, " is supplied and belongs to the calling uid, that order's current status is injected as additional context — the assistant only ever sees the caller's own data."] },
    { type: 'rich', parts: ["Fallback: if the AI config's key is missing or ", { code: 'aktif' }, ' is false, the function throws ', { code: 'failed-precondition' }, ' ("Asisten AI belum diaktifkan").'] },
    { type: 'subHeading', text: 'Business Analyst AI — analisaBisnisAi' },
    { type: 'code', code: `// onCall, admin-only
Output: { ringkasan: string }` },
    { type: 'rich', parts: ['Purely numeric aggregation is done server-side in TypeScript — the LLM never touches the database directly. Over the trailing 30 days of ', { code: 'orders' }, ', the function computes: total / selesai / dibatalkan counts, omzet (revenue from completed orders), and a per-service order-count breakdown — then hands those numbers to ', { code: 'panggilAi()' }, ' with a prompt capped at 6 bullet points plus 2-3 concrete action suggestions.'] },
    { type: 'subHeading', text: 'Guardrails' },
    { type: 'list', items: [
      'The prompt explicitly forbids fabricating data or leaking other customers\' PII.',
      'analisaBisnisAi is told not to fabricate beyond the numbers it was given.',
      "Both functions require the caller to be authenticated; the business analyst additionally requires role == 'admin'.",
    ] },
  ],
};

export const NOTIFICATIONS = {
  slug: 'notifications', eyebrow: 'Integrations', title: 'Notifications',
  description: 'Two independent notification channels — Firebase Cloud Messaging for push, and WhatsApp via Fonnte for a persistent paper trail.',
  blocks: [
    { type: 'subHeading', text: 'FCM Push Events' },
    { type: 'table', head: ['Function', 'Recipient', 'Trigger'], widths: [110, 100, '*'], rows: [
      ['onOrderAssigned', 'assigned crew', "order enters 'ditugaskan'"],
      ['pushStatusPelanggan', 'customer', 'terverifikasi / ditugaskan / dalam_perjalanan / dikerjakan / selesai / ditolak'],
      ['onChatMessageCreate', 'the other chat participant', 'any new message in orders/{id}/messages'],
      ['reminderKru', 'assigned crew', 'every 30 min, if jadwal is 90-150 min away'],
      ['onBroadcastCreate', 'all pelanggan with a token', 'admin creates a broadcasts/{id} doc'],
    ] },
    { type: 'callout', kind: 'info', text: 'Invalid/expired tokens are cleaned from kru.fcmTokens automatically whenever a push fails with registration-token-not-registered or invalid-argument.' },
    { type: 'subHeading', text: 'WhatsApp (Fonnte) — waNotifOrder' },
    { type: 'rich', parts: ['A thin abstraction, ', { code: 'WaSender' }, ', with ', { code: 'FonnteSender' }, ' as the active implementation — swap the class if you switch WhatsApp providers without touching call sites. Fires on the same order-status transitions as the push notification (terverifikasi / ditugaskan / selesai), sending a formatted text message to the customer\'s phone. No-op — safely, silently — if ', { code: 'FONNTE_TOKEN' }, ' is unset in ', { code: 'firebase/functions/.env' }, '.'] },
    { type: 'subHeading', text: 'In-App Notification Feed' },
    { type: 'rich', parts: ['Every push additionally writes a ', { code: 'notifications' }, ' document (see Data Model) so the customer/crew has a persistent, scrollable history inside the app — not just a transient system notification. Notifications are deep-linkable via the ', { code: 'orderId' }, ' field.'] },
  ],
};

export const DEPLOYMENT = {
  slug: 'deployment', eyebrow: 'Operations', title: 'Deployment',
  description: 'One Firebase project, multiple hosting sites, one Cloud Functions codebase.',
  blocks: [
    { type: 'subHeading', text: 'Hosting Targets' },
    { type: 'rich', parts: [{ code: 'firebase.json' }, ' declares multiple hosting entries, each mapped to a distinct Firebase Hosting site via ', { code: '.firebaserc' }, ' target aliases:'] },
    { type: 'table', head: ['Target', 'Public dir', 'Serves'], widths: [90, 130, '*'], rows: [
      ['admin', 'apps/admin/build/web', 'Admin panel (Flutter web build)'],
      ['manualbook', 'docs-site/manualbook/dist', 'This end-user manual'],
      ['documentation', 'docs-site/documentation/dist', 'This developer reference'],
    ] },
    { type: 'callout', kind: 'info', text: "Site IDs must be globally unique across all Firebase projects. If a bare name like manualbook is taken, Firebase assigns a project-prefixed fallback (e.g. tuntaskilat-manualbook) — check the actual *.web.app URL printed after firebase hosting:sites:create." },
    { type: 'subHeading', text: 'Cloud Functions Env Vars' },
    { type: 'paragraph', text: 'Optional integrations are gated behind environment variables in firebase/functions/.env — every one of them degrades gracefully (no-op, HTTP 501, or a clear failed-precondition) when unset, so partial configuration never breaks the core booking flow.' },
    { type: 'code', title: 'firebase/functions/.env', code:
`# WhatsApp notifications (waNotifOrder) — no-op if unset
FONNTE_TOKEN=

# Xendit dynamic payments — buatTagihanXendit throws if unset
XENDIT_SECRET_KEY=

# Xendit webhook — xenditWebhook returns HTTP 501 if unset
XENDIT_CALLBACK_TOKEN=

# AI fallback keys (settings/ai Firestore fields take precedence)
GEMINI_API_KEY=
OPENAI_API_KEY=
ANTHROPIC_API_KEY=` },
    { type: 'subHeading', text: 'Deploy Commands' },
    { type: 'code', code:
`# Build the docs sites
cd docs-site/manualbook && npm run build && cd ../..
cd docs-site/documentation && npm run build && cd ../..

# Build the admin web app
cd apps/admin && flutter build web --release && cd ../..

# Deploy everything
firebase deploy --only functions,firestore:rules,storage:rules,hosting

# Or scope to just the docs sites
firebase deploy --only hosting:manualbook,hosting:documentation` },
    { type: 'subHeading', text: 'Pre-Deploy Checklist' },
    { type: 'list', items: [
      'flutter analyze clean across all 4 packages (tk_core, admin, pelanggan, kru).',
      'flutter test packages/tk_core apps/admin — all green.',
      'cd firebase/functions && npx tsc -p . — no type errors.',
      'Firestore Security Rules reviewed for any collection touched this release.',
      'New Cloud Functions match the region convention (asia-southeast2).',
    ] },
  ],
};

export const CHANGELOG = {
  slug: 'changelog', eyebrow: 'Operations', title: 'Changelog & Roadmap',
  description: 'Development phases, from the initial thesis-scoped MVP through the current business-layer feature set.',
  blocks: [
    { type: 'timeline', items: [
      { phase: 'FASE 1', title: 'Bug Blockers', items: [
        'Splash/launcher fixes', 'P6 billing blank-screen fix', 'Voucher rules deploy', 'Multi-crew assignment wiring',
        'Profile photos', 'Payment proof + QRIS display', 'Dashboard status chart', 'System bar consistency audit',
      ] },
      { phase: 'FASE 2', title: 'Customer UX', items: [
        'Wizard-style booking form', 'Saved addresses + map picker', 'Reverse-geocoding (Nominatim)', 'Full catalog with category filter',
        'Active-order home card', 'Cancel + CS contact from tracking', 'Granular permissions + Terms', 'Chat + call wiring',
      ] },
      { phase: 'FASE 3', title: 'Crew (Kru)', items: [
        'FCM push + assignment reminders (cron)', 'Real-road OSRM routing', 'Custom notification sound',
      ] },
      { phase: 'FASE 4', title: 'Admin', items: [
        'Full dynamic pricing catalog editor', 'Crew lifecycle (keahlian/tipe/status)', 'Skill-based assignment matching',
        'New-user + per-phone voucher anti-abuse', 'Service area module', 'TOTP 2FA', 'Admin team management (buatAdmin/setNonaktifAdmin)',
      ] },
      { phase: 'FASE 5', title: 'Business Systems', items: [
        'Commission config (global + per-service)', 'Cash deposit ledger (kasKru/setoran)', 'Referral program with anti-abuse',
        'Modular payment gateway (Static + Xendit stub)', 'WhatsApp notifications (Fonnte)',
      ] },
      { phase: 'FASE 6', title: 'Quality & Release', items: [
        'Maintenance mode / forced update (settings/app)', 'Skeleton loading states', 'Memory-leak audit (chat screen controllers)', 'Extended black-box test coverage',
      ] },
      { phase: 'POST-FASE 6', title: 'Business Expansion', items: [
        'Multi-provider AI (Gemini/OpenAI/Anthropic) — CS chat (csAi) + business analyst (analisaBisnisAi)',
        'Xendit dynamic invoicing activated (buatTagihanXendit + xenditWebhook)',
        'Capacity-based booking (replaces boolean slot lock with a live crew-count counter)',
        'A10 Pantau Operasional — live crew map + chat quality monitoring',
        'A9 Kelola Klien — customer roster with spend aggregation',
        'Broadcast push notifications + banner promo content',
        'Auto-cancel unassigned orders after 24h',
        'Server-authoritative review rating aggregation',
      ] },
    ] },
    { type: 'paragraph', text: "For the exact commit history, see the repository's Git log — each feature phase was developed on its own branch and merged via pull request into dev." },
  ],
};

export const CHAPTERS = [HOME, GETTING_STARTED, ARCHITECTURE, DATA_MODEL, FUNCTIONS, SECURITY_RULES, BUSINESS_LOGIC, PAYMENTS, AI, NOTIFICATIONS, DEPLOYMENT, CHANGELOG];
