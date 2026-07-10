import 'package:flutter_test/flutter_test.dart';
import 'package:tk_core/tk_core.dart';

/// Uji modul cakupan wilayah (siap ekspansi multi-cabang).
void main() {
  group('Validators.jarakKm (haversine)', () {
    test('jarak ~0 untuk titik sama', () {
      expect(Validators.jarakKm(-2.5329, 112.9508, -2.5329, 112.9508),
          closeTo(0, 0.001));
    });

    test('jarak wajar antar titik Sampit (< 5 km)', () {
      final d = Validators.jarakKm(-2.5329, 112.9508, -2.5400, 112.9600);
      expect(d, greaterThan(0));
      expect(d, lessThan(5));
    });
  });

  group('Validators.dalamWilayah', () {
    test('daftar kosong → fallback bounding box Sampit', () {
      expect(Validators.dalamWilayah(-2.5329, 112.9508, const []), isTrue);
      expect(Validators.dalamWilayah(-6.2, 106.8, const []), isFalse); // Jakarta
    });

    test('dalam radius cabang → true; di luar → false', () {
      const cabang = [(lat: -2.5329, lng: 112.9508, radiusKm: 10.0)];
      expect(Validators.dalamWilayah(-2.55, 112.96, cabang), isTrue);
      expect(Validators.dalamWilayah(-2.9, 113.4, cabang), isFalse);
    });
  });
}
