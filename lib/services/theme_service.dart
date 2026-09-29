import 'dart:async';

import 'package:flutter/material.dart';
import 'package:light/light.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreference { system, light, dark, auto }

class ThemeService extends ChangeNotifier {
  ThemePreference _preference = ThemePreference.system;
  ThemeMode _autoMode = ThemeMode.light;
  StreamSubscription<int>? _luxSubscription;
  static const _prefsKey = 'themePreference';

  ThemePreference get preference => _preference;
  Timer? _pendingSwitch;

  static const _darkBelowLux = 30;
  static const _lightAboveLux = 70;
  static const _switchDelay = Duration(seconds: 2);

  ThemeMode get mode => switch (_preference) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.auto => _autoMode,
  };

  static Future<ThemePreference> loadSaved() async {
    final saved = await SharedPreferencesAsync().getString(_prefsKey);
    return ThemePreference.values.asNameMap()[saved] ?? ThemePreference.system;
  }

  late final AppLifecycleListener _lifecycle;

  ThemeService() {
    _lifecycle = AppLifecycleListener(onHide: _stopSensor, onShow: _syncSensor);
  }

  void _onLux(int lux) {
    var target = _autoMode;
    if (lux < _darkBelowLux) target = ThemeMode.dark;
    if (lux > _lightAboveLux) target = ThemeMode.light;

    if (target == _autoMode) {
      _pendingSwitch?.cancel();
      _pendingSwitch = null;
    } else {
      _pendingSwitch ??= Timer(_switchDelay, () {
        _pendingSwitch = null;
        _autoMode = target;
        notifyListeners();
      });
    }
  }

  void _syncSensor() {
    if (_preference == ThemePreference.auto) {
      _startSensor();
    } else {
      _stopSensor();
    }
  }

  void setPreference(ThemePreference preference) {
    _preference = preference;
    _syncSensor();
    SharedPreferencesAsync().setString(_prefsKey, preference.name);
    notifyListeners();
  }

  void _startSensor() {
    _luxSubscription ??= Light().lightSensorStream.listen(_onLux);
  }

  void _stopSensor() {
    _luxSubscription?.cancel();
    _luxSubscription = null;
    _pendingSwitch?.cancel();
    _pendingSwitch = null;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _stopSensor();
    super.dispose();
  }
}
