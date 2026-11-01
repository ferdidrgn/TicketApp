import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notif_prefs.dart';

/// Üretim saklaması: `User/{uid}.notifPrefs` (noktalı yol güncellemesi — diğer
/// alanlar ve cihaza ait `loudAlarm` ezilmez).
class FirestoreNotifPrefsRemote implements NotifPrefsRemote {
  DocumentReference<Map<String, dynamic>>? _ref() {
    final User? u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous) return null;
    return FirebaseFirestore.instance.collection('User').doc(u.uid);
  }

  @override
  Future<NotifPrefs?> read() async {
    final ref = _ref();
    if (ref == null) return null;
    final snap = await ref.get();
    return NotifPrefs.fromMap(snap.data()?['notifPrefs']);
  }

  @override
  Future<void> write(final NotifPrefs p) async {
    final ref = _ref();
    if (ref == null) return;
    await ref.update(<String, Object?>{
      'notifPrefs.reminders': p.reminders,
      'notifPrefs.changes': p.changes,
      'notifPrefs.thankYou': p.thankYou,
      'notifPrefs.newShows': p.newShows,
      'notifPrefs.marketing': p.marketing,
      'notifPrefs.quietStart': p.hasQuiet ? p.quietStart : FieldValue.delete(),
      'notifPrefs.quietEnd': p.hasQuiet ? p.quietEnd : FieldValue.delete(),
    });
  }
}

/// Testte geçersiz kılınır.
final Provider<NotifPrefsRemote> notifPrefsRemoteProvider =
    Provider<NotifPrefsRemote>((final ref) => FirestoreNotifPrefsRemote());

/// `null` veri = oturum yok (bölüm gizlenir).
class NotifPrefsNotifier extends AsyncNotifier<NotifPrefs?> {
  @override
  Future<NotifPrefs?> build() => ref.read(notifPrefsRemoteProvider).read();

  /// İyimser güncelleme; yazım başarısızsa eski değere döner ve `false` verir.
  Future<bool> change(final NotifPrefs Function(NotifPrefs) fn) async {
    final NotifPrefs? old = state.value;
    if (old == null) return false;
    final NotifPrefs next = fn(old);
    if (next == old) return true;
    state = AsyncData<NotifPrefs?>(next);
    try {
      await ref.read(notifPrefsRemoteProvider).write(next);
      return true;
    } catch (_) {
      state = AsyncData<NotifPrefs?>(old);
      return false;
    }
  }
}

final AsyncNotifierProvider<NotifPrefsNotifier, NotifPrefs?> notifPrefsProvider =
    AsyncNotifierProvider<NotifPrefsNotifier, NotifPrefs?>(
        NotifPrefsNotifier.new);
