import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String _name = '';
  String _spiritAnimal = '';
  bool _onboardingComplete = false;

  String get name => _name;
  String get spiritAnimal => _spiritAnimal;
  bool get onboardingComplete => _onboardingComplete;

  String get firstName {
    if (_name.isEmpty) return '';
    return _name.trim().split(' ').first;
  }

  void setName(String name) {
    _name = name.trim();
    notifyListeners();
  }

  void setSpiritAnimal(String animal) {
    _spiritAnimal = animal;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboardingComplete = true;
    notifyListeners();
  }
}