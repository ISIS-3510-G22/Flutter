import 'package:flutter/material.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/models/reimbursement_method.dart';
import 'package:plansync/model/models/user.dart';

class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this.user)
    : nameController = TextEditingController(text: user.name),
      lastNameController = TextEditingController(text: user.lastName),
      phoneController = TextEditingController(text: user.phone),
      reimbursementMethods = List.of(user.reimbursementMethods);

  final User user;
  final TextEditingController nameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final List<ReimbursementMethod> reimbursementMethods;
  final _userRepository = UserRepository();
  bool isSaving = false;
  bool queued = false;

  void addMethod(ReimbursementMethod method) {
    reimbursementMethods.add(method);
    notifyListeners();
  }

  Future<bool> saveChanges() async {
    isSaving = true;
    notifyListeners();

    try {
      final updated = User(
        id: user.id,
        name: nameController.text.trim(),
        lastName: lastNameController.text.trim(),
        username: user.username,
        email: user.email,
        phone: phoneController.text.trim(),
        photoUrl: user.photoUrl,
        reimbursementMethods: reimbursementMethods,
      );
      final sent = await _userRepository.saveProfile(updated);
      queued = !sent;
      return true;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
