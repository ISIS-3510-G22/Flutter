import 'package:plansync/model/models/theme_preferences.dart';
import 'package:plansync/model/services/light_sensor_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeRepository {
  static const _prefsKey = 'themePreference';

  final _prefs = SharedPreferencesAsync();
  final _sensor = LightSensorService();

  Future<ThemePreference> loadPreference() async {
    final saved = await _prefs.getString(_prefsKey);
    return ThemePreference.values.asNameMap()[saved] ?? ThemePreference.system;
  }

  Future<void> savePreference(ThemePreference preference) =>
      _prefs.setString(_prefsKey, preference.name);

  Stream<int> get lux => _sensor.lux;
}
