import 'package:light/light.dart';

class LightSensorService {
  final _light = Light();

  Stream<int> get lux => _light.lightSensorStream;
}
