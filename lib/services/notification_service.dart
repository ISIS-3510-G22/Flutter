import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  StreamSubscription<String>? _tokenRefreshSubscription;
  Future<void> _pendingTokenWrite = Future<void>.value();
  String? _activeUserId;
  String? _lastError;

  String? get lastError => _lastError;

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<bool> requestPermissionAndRegisterToken(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Must not be empty.');
    }

    _lastError = null;
    if (_activeUserId != userId) {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      _activeUserId = userId;
    }

    final allowed = await requestPermission();
    if (!allowed) return false;

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
      (token) {
        unawaited(_queueTokenSave(userId, token).catchError((_) {}));
      },
      onError: (Object error) {
        _lastError = 'Could not listen for FCM token updates: $error';
      },
    );

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        _lastError = 'Firebase Messaging did not return a device token.';
        return false;
      }
      await _queueTokenSave(userId, token);
      return true;
    } catch (error) {
      _lastError = 'Could not register this device for notifications: $error';
      return false;
    }
  }

  Future<void> unregisterForUser(String userId) async {
    if (_activeUserId == userId) {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      _activeUserId = null;
    }

    final preferences = await SharedPreferences.getInstance();
    final key = _preferenceKey(userId);
    final token = preferences.getString(key) ?? await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _tokenCollection(userId).doc(_tokenDocumentId(token)).delete();
    }
    await preferences.remove(key);
  }

  Future<void> _queueTokenSave(String userId, String token) {
    final write = _pendingTokenWrite.then((_) => _saveToken(userId, token));
    _pendingTokenWrite = write.catchError((Object error) {
      _lastError = 'Could not save the FCM token: $error';
    });
    return write;
  }

  Future<void> _saveToken(String userId, String token) async {
    final preferences = await SharedPreferences.getInstance();
    final preferenceKey = _preferenceKey(userId);
    final previousToken = preferences.getString(preferenceKey);

    await _tokenCollection(userId).doc(_tokenDocumentId(token)).set({
      'token': token,
      'platform': 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (previousToken != null && previousToken != token) {
      await _tokenCollection(
        userId,
      ).doc(_tokenDocumentId(previousToken)).delete();
    }
    await preferences.setString(preferenceKey, token);
    _lastError = null;
  }

  CollectionReference<Map<String, dynamic>> _tokenCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('fcmTokens');

  String _preferenceKey(String userId) => 'fcm_token_$userId';

  String _tokenDocumentId(String token) =>
      base64Url.encode(utf8.encode(token)).replaceAll('=', '');

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _activeUserId = null;
  }
}
