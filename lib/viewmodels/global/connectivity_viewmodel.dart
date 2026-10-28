import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/model/data/connectivity_repository.dart';

class ConnectivityViewModel extends ChangeNotifier {
  ConnectivityViewModel() {
    _subscription = _repository.changes.listen((_) => notifyListeners());
  }

  final _repository = ConnectivityRepository.instance;
  late final StreamSubscription<bool> _subscription;

  bool get isOnline => _repository.isOnline;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
