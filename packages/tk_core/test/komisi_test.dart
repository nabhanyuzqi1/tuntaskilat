import 'package:flutter_test/flutter_test.dart';
import 'package:tk_core/tk_core.dart';

/// Uji konfigurasi komisi (settings/komisi): global, override per layanan,
/// klem 0–100, dan integrasinya dengan bagiUpah (invarian tetap terjaga).
void main() {
  group('KonfigKomisi.persenUntuk', () {
    test('pakai global bila tak ada override', () {
      const k = KonfigKomisi(komisiPersen: 25);
      expect(k.persenUntuk('apa_saja'), 25);
      expect(k.persenUntuk(null), 25);
    });

    test('override per layanan menang atas global', () {
      const k = KonfigKomisi(komisiPersen: 20, perLayanan: {'ac': 30});
      expect(k.persenUntuk('ac'), 30);
      expect(k.persenUntuk('cleaning'), 20);
    });

    test('klem nilai di luar 0–100', () {
      const k = KonfigKomisi(komisiPersen: 150, perLayanan: {'x': -5});
      expect(k.persenUntuk('lain'), 100);
      expect(k.persenUntuk('x'), 0);
    });

    test('fromMap/toMap round-trip', () {
      const k = KonfigKomisi(komisiPersen: 18, perLayanan: {'a': 10, 'b': 22});
      final round = KonfigKomisi.fromMap(k.toMap());
      expect(round.komisiPersen, 18);
      expect(round.perLayanan['a'], 10);
      expect(round.perLayanan['b'], 22);
    });

    test('default (map kosong) = 20%, tanpa override', () {
      final k = KonfigKomisi.fromMap(const {});
      expect(k.komisiPersen, 20);
      expect(k.persenUntuk('apapun'), 20);
    });
  });

  group('upahUntuk + bagiUpah (invarian tetap terjaga)', () {
    test('override 30% dipakai bagiUpah, Σ == total', () {
      const k = KonfigKomisi(komisiPersen: 20, perLayanan: {'ac': 30});
      final penugasan = [
        const Penugasan(cleanerId: 'A', nama: 'A', peran: PeranKru.worker),
        const Penugasan(cleanerId: 'B', nama: 'B', peran: PeranKru.helper),
      ];
      final r = bagiUpah(200000, penugasan, konfig: k.upahUntuk('ac'));
      expect(r.komisi, 60000); // 30%
      expect(r.pool, 140000);
      expect(r.totalTerbagi, 200000);
    });
  });
}
