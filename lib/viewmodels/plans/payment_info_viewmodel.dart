import 'package:flutter/material.dart';
import 'package:plansync/data/payment_info_repository.dart';
import 'package:plansync/models/payment_info.dart';

class PaymentInfoViewModel extends ChangeNotifier {
  PaymentInfoViewModel(this._planId, this._userId) {
    _load();
  }

  final String _planId;
  final String _userId;
  final _repository = PaymentInfoRepository();

  final detailsController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool hasExisting = false;
  String? errorMessage;

  Future<void> _load() async {
    try {
      final existing = await _repository.paymentInfoBy(_planId, _userId);
      if (existing != null) {
        detailsController.text = existing.details;
        hasExisting = true;
      }
    } catch (_) {
      errorMessage = 'Could not load your info. Try again.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> save() async {
    final details = detailsController.text.trim();
    if (details.isEmpty) {
      errorMessage = 'Write your Bre-B key or account.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.save(
        _planId,
        PaymentInfo(userId: _userId, details: details),
      );
      return true;
    } catch (_) {
      errorMessage = 'Something went wrong. Try again.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    detailsController.dispose();
    super.dispose();
  }
}
