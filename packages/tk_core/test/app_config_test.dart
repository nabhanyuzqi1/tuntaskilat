import 'package:flutter_test/flutter_test.dart';
import 'package:tk_core/tk_core.dart';

/// Uji KonfigApp (settings/app): banding semver, perluUpdate, dan blokir gate.
void main() {
  group('perluUpdate (semver)', () {
    test('versi klien lebih lama → perlu update', () {
      const k = KonfigApp(mode: AppMode.updateWajib, versiMin: '1.2.0');
      expect(k.perluUpdate('1.1.9'), isTrue);
      expect(k.perluUpdate('1.2.0'), isFalse);
      expect(k.perluUpdate('1.3.0'), isFalse);
    });

    test('versiMin kosong → tak pernah perlu update', () {
      const k = KonfigApp(mode: AppMode.updateWajib);
      expect(k.perluUpdate('0.0.1'), isFalse);
    });

    test('panjang segmen berbeda ditangani', () {
      const k = KonfigApp(versiMin: '1.2');
      expect(k.perluUpdate('1.2.0'), isFalse);
      expect(k.perluUpdate('1.1.9'), isTrue);
    });
  });

  group('blokir gate', () {
    test('normal → tak pernah blokir', () {
      const k = KonfigApp();
      expect(k.blokir('1.0.0'), isFalse);
    });

    test('maintenance → selalu blokir', () {
      const k = KonfigApp(mode: AppMode.maintenance);
      expect(k.blokir('9.9.9'), isTrue);
    });

    test('updateWajib blokir hanya bila versi kurang', () {
      const k = KonfigApp(mode: AppMode.updateWajib, versiMin: '2.0.0');
      expect(k.blokir('1.5.0'), isTrue);
      expect(k.blokir('2.0.0'), isFalse);
    });
  });

  test('fromMap/toMap round-trip', () {
    const k = KonfigApp(
        mode: AppMode.maintenance, pesan: 'Halo', versiMin: '1.1.0');
    final r = KonfigApp.fromMap(k.toMap());
    expect(r.mode, AppMode.maintenance);
    expect(r.pesan, 'Halo');
    expect(r.versiMin, '1.1.0');
  });

  test('map kosong → default normal', () {
    final k = KonfigApp.fromMap(const {});
    expect(k.mode, AppMode.normal);
    expect(k.blokir('1.0.0'), isFalse);
  });
}
