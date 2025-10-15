import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MessagingService {
  static final _fm = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> initForUser(User user) async {
    // Request permissions (Android 13+/iOS) and get current token
    await _fm.requestPermission();
    final token = await _fm.getToken();
    if (token != null) {
      await _saveToken(user.uid, token);
    }

    // Listen for token refresh
    _fm.onTokenRefresh.listen((newToken) async {
      await _saveToken(user.uid, newToken);
    });

    // Subscribe to a general topic for app-wide announcements
    await _fm.subscribeToTopic('prontuarios');
  }

  static Future<void> _saveToken(String uid, String token) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('tokens')
        .doc(token);
    await ref.set({
      'token': token,
      'platform': Platform.operatingSystem,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
