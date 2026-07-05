import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tk_core/tk_core.dart';

import 'app_providers.dart';

/// Notifikasi milik pengguna, terbaru dulu (P12).
final notifikasiProvider = StreamProvider<List<NotificationModel>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const []);
  final uid = ref.watch(authServiceProvider).currentUser?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchNotifications(uid).map(
        (list) => (list.toList()
          ..sort((a, b) => b.waktu.compareTo(a.waktu)))
            .toList(growable: false),
      );
});

/// Ada notifikasi belum dibaca? — dot merah di bottom nav & lonceng P3.
final adaNotifBelumDibacaProvider = Provider<bool>((ref) =>
    ref.watch(notifikasiProvider).valueOrNull?.any((n) => !n.dibaca) ??
    false);
