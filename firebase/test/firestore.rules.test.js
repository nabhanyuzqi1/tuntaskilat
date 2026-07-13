// Tes unit Security Rules Firestore Tuntaskilat.
// Jalankan: cd firebase/test && npm install && npm test
// (membutuhkan Firebase CLI + Java untuk emulator Firestore).
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ID = 'tuntaskilat-test';

let env;

// Konteks admin yang menembus rules — untuk menaruh data awal (services,
// vouchers, dokumen milik user lain) tanpa terganjal rules.
async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

// Order valid minimal sesuai rules create (uang berjangkar ke katalog).
function orderValid(uid, over = {}) {
  return {
    userId: uid,
    serviceId: 'home_cleaning',
    hargaSatuan: 90000,
    kuantitas: 1,
    subtotal: 90000,
    potongan: 0,
    totalHarga: 90000,
    status: 'menunggu_penugasan',
    ...over,
  };
}

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(join(__dirname, '..', 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  // Katalog & voucher acuan.
  await seed('services/home_cleaning', { harga: 90000, aktif: true });
  await seed('vouchers/HEMAT20', { tipe: 'persen', nilai: 20 });
  // Profil peran.
  await seed('users/admin1', { role: 'admin' });
  await seed('users/pel1', { role: 'pelanggan' });
  await seed('users/pel2', { role: 'pelanggan' });
});

const auth = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

describe('services (katalog publik)', () => {
  it('boleh dibaca tanpa login (guest mode)', async () => {
    await assertSucceeds(getDoc(doc(anon(), 'services/home_cleaning')));
  });
  it('hanya admin yang boleh menulis', async () => {
    await assertFails(setDoc(doc(auth('pel1'), 'services/x'), { harga: 1 }));
    await assertSucceeds(
      setDoc(doc(auth('admin1'), 'services/x'), { harga: 1, aktif: true }),
    );
  });
});

describe('orders create — uang berjangkar ke katalog', () => {
  it('order valid (tanpa potongan) diterima', async () => {
    await assertSucceeds(
      setDoc(doc(auth('pel1'), 'orders/o1'), orderValid('pel1')),
    );
  });
  it('hargaSatuan != services.harga ditolak', async () => {
    await assertFails(
      setDoc(doc(auth('pel1'), 'orders/o2'),
        orderValid('pel1', { hargaSatuan: 50000, subtotal: 50000, totalHarga: 50000 })),
    );
  });
  it('total != subtotal - potongan ditolak', async () => {
    await assertFails(
      setDoc(doc(auth('pel1'), 'orders/o3'),
        orderValid('pel1', { totalHarga: 80000 })),
    );
  });
  it('potongan tanpa voucher yang ada ditolak', async () => {
    await assertFails(
      setDoc(doc(auth('pel1'), 'orders/o4'),
        orderValid('pel1', {
          potongan: 18000, totalHarga: 72000, voucherKode: 'TIDAKADA',
        })),
    );
  });
  it('potongan dengan voucher valid diterima', async () => {
    await assertSucceeds(
      setDoc(doc(auth('pel1'), 'orders/o5'),
        orderValid('pel1', {
          potongan: 18000, totalHarga: 72000, voucherKode: 'HEMAT20',
        })),
    );
  });
  it('userId bukan diri sendiri ditolak', async () => {
    await assertFails(
      setDoc(doc(auth('pel1'), 'orders/o6'), orderValid('pel2')),
    );
  });
});

describe('orders get/list — hanya peserta', () => {
  beforeEach(async () => {
    await seed('orders/ox', { ...orderValid('pel1'), cleanerId: 'kru1', kruIds: ['kru1'] });
  });
  it('pemilik boleh baca', async () => {
    await assertSucceeds(getDoc(doc(auth('pel1'), 'orders/ox')));
  });
  it('kru tertugas boleh baca', async () => {
    await assertSucceeds(getDoc(doc(auth('kru1'), 'orders/ox')));
  });
  it('pelanggan lain tidak boleh baca (anti-enumerasi)', async () => {
    await assertFails(getDoc(doc(auth('pel2'), 'orders/ox')));
  });
  it('admin boleh baca', async () => {
    await assertSucceeds(getDoc(doc(auth('admin1'), 'orders/ox')));
  });
});

describe('orders update — pembatalan bergantung status', () => {
  it('batal dari menunggu_penugasan (pra-penugasan) diterima', async () => {
    await seed('orders/oc1', orderValid('pel1', { status: 'menunggu_penugasan' }));
    await assertSucceeds(
      updateDoc(doc(auth('pel1'), 'orders/oc1'), { status: 'dibatalkan' }),
    );
  });
  it('batal dari ditugaskan ditolak (wewenang admin)', async () => {
    await seed('orders/oc2', orderValid('pel1', { status: 'ditugaskan' }));
    await assertFails(
      updateDoc(doc(auth('pel1'), 'orders/oc2'), { status: 'dibatalkan' }),
    );
  });
  it('klien tidak boleh mengubah totalHarga', async () => {
    await seed('orders/oc3', orderValid('pel1'));
    await assertFails(
      updateDoc(doc(auth('pel1'), 'orders/oc3'), { totalHarga: 1 }),
    );
  });
});

describe('slots — kunci publik-boolean', () => {
  it('boleh dibaca pengguna login', async () => {
    await seed('slots/s1', { userId: 'pel1', taken: true });
    await assertSucceeds(getDoc(doc(auth('pel2'), 'slots/s1')));
  });
  it('dibuat oleh pemilik order', async () => {
    await assertSucceeds(
      setDoc(doc(auth('pel1'), 'slots/s2'), { userId: 'pel1', taken: true }),
    );
  });
  it('tidak boleh dibuat atas nama orang lain', async () => {
    await assertFails(
      setDoc(doc(auth('pel1'), 'slots/s3'), { userId: 'pel2', taken: true }),
    );
  });
  it('hanya admin yang boleh menghapus (membebaskan slot)', async () => {
    await seed('slots/s4', { userId: 'pel1', taken: true });
    await assertFails(setDoc(doc(auth('pel1'), 'slots/s4'), { taken: false }));
  });
});

describe('banners — publik baca, admin tulis', () => {
  beforeEach(async () => {
    await seed('banners/b1', { judul: 'Promo', aktif: true, urutan: 0 });
  });
  it('boleh dibaca tanpa login (tampil di guest mode)', async () => {
    await assertSucceeds(getDoc(doc(anon(), 'banners/b1')));
  });
  it('pelanggan tidak boleh menulis', async () => {
    await assertFails(
      setDoc(doc(auth('pel1'), 'banners/b2'), { judul: 'X', aktif: true }),
    );
  });
  it('admin boleh menulis', async () => {
    await assertSucceeds(
      setDoc(doc(auth('admin1'), 'banners/b3'), { judul: 'X', aktif: true }),
    );
  });
});

describe('broadcasts — admin-only', () => {
  it('pelanggan tidak boleh membuat broadcast', async () => {
    await assertFails(
      setDoc(doc(auth('pel1'), 'broadcasts/x'), { judul: 'X', pesan: 'Y' }),
    );
  });
  it('admin boleh membuat broadcast', async () => {
    await assertSucceeds(
      setDoc(doc(auth('admin1'), 'broadcasts/y'), { judul: 'X', pesan: 'Y' }),
    );
  });
});
