const admin = require('firebase-admin');

// 1. Download Service Account Key dari Firebase Console > Project Settings > Service Accounts
// 2. Simpan di folder yang sama dengan nama `serviceAccountKey.json`
// 3. Jalankan: `npm install firebase-admin` lalu `node seed_users.js`

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function clearData() {
  console.log('Menghapus data users & kru yang lama (jika ada)...');
  const collections = ['users', 'kru', 'orders', 'notifications', 'payments'];
  for (const coll of collections) {
    const snapshot = await db.collection(coll).get();
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    if (!snapshot.empty) await batch.commit();
  }
}

async function createAccounts() {
  await clearData();

  const accounts = [
    {
      uid: 'pelanggan_test',
      email: 'pelanggan@tuntaskilat.id',
      password: 'Pelanggan123',
      displayName: 'Pelanggan Uji',
      role: 'pelanggan'
    },
    {
      uid: 'admin_test',
      email: 'admin@tuntaskilat.id',
      password: 'AdminTuntas123',
      displayName: 'Admin TuntasKilat',
      role: 'admin'
    },
    {
      uid: 'kru_test',
      email: 'kru@tuntaskilat.id',
      password: 'KruTuntas123',
      displayName: 'Kru Andal',
      role: 'kru'
    }
  ];

  for (const acc of accounts) {
    try {
      // Create or update Auth user
      try {
        await auth.createUser({
          uid: acc.uid,
          email: acc.email,
          password: acc.password,
          displayName: acc.displayName,
        });
      } catch (e) {
        if (e.code === 'auth/uid-already-exists' || e.code === 'auth/email-already-exists') {
          await auth.updateUser(acc.uid, {
            email: acc.email,
            password: acc.password,
            displayName: acc.displayName,
          });
        } else {
          throw e;
        }
      }

      // Create User Document
      await db.collection('users').doc(acc.uid).set({
        userId: acc.uid,
        email: acc.email,
        nama: acc.displayName,
        role: acc.role,
        noTelepon: '081234567890',
        alamat: acc.role === 'pelanggan' ? 'Jl. MT Haryono, Ketapang' : ''
      });

      // If Kru, create Kru Document
      if (acc.role === 'kru') {
        await db.collection('kru').doc(acc.uid).set({
          cleanerId: acc.uid,
          nama: acc.displayName,
          noTelepon: '081234567890',
          statusKetersediaan: true,
          rataRating: 4.8,
          jumlahUlasan: 12
        });
      }

      console.log(`✅ Berhasil membuat akun: ${acc.email} (${acc.role})`);
    } catch (err) {
      console.error(`❌ Gagal membuat ${acc.email}:`, err.message);
    }
  }
}

createAccounts().then(() => {
  console.log('Selesai!');
  process.exit(0);
});
