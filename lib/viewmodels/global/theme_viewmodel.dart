import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/theme_repository.dart';
import 'package:plansync/model/models/theme_preferences.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel(this._preference) {
    _lifecycle = AppLifecycleListener(onHide: _stopSensor, onShow: _syncSensor);
    _syncSensor();
  }

  static const _darkBelowLux = 30;
  static const _lightAboveLux = 70;
  static const _switchDelay = Duration(seconds: 2);

  final _repository = ThemeRepository();
  late final AppLifecycleListener _lifecycle;
  ThemePreference _preference;
  ThemeMode _autoMode = ThemeMode.light;
  StreamSubscription<int>? _luxSubscription;
  Timer? _pendingSwitch;

  ThemePreference get preference => _preference;

  ThemeMode get mode => switch (_preference) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.auto => _autoMode,
  };

  void setPreference(ThemePreference preference) {
    _preference = preference;
    _syncSensor();
    _repository.savePreference(preference);
    notifyListeners();
  }

  void _startSensor() {
    _luxSubscription ??= _repository.lux.listen(_onLux);
  }

  void _stopSensor() {
    _luxSubscription?.cancel();
    _luxSubscription = null;
    _pendingSwitch?.cancel();
    _pendingSwitch = null;
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

  @override
  void dispose() {
    _lifecycle.dispose();
    _stopSensor();
    super.dispose();
  }
}
