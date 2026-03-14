import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  String _name = '';
  String _spiritAnimal = '';
  bool _onboardingComplete = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get name => _name;
  String get spiritAnimal => _spiritAnimal;
  bool get onboardingComplete => _onboardingComplete;

  String get firstName {
    if (_name.isEmpty) return '';
    return _name.trim().split(' ').first;
  }

  // ── Google account fields ─────────────────────────────────────
  String? get email => FirebaseAuth.instance.currentUser?.email;

  String? get photoUrl => FirebaseAuth.instance.currentUser?.photoURL;

  // ── Load from Firestore ───────────────────────────────────────
  Future<void> loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _name = data['name'] as String? ?? '';
        _spiritAnimal = data['spiritAnimal'] as String? ?? '';
        _onboardingComplete = data['onboardingComplete'] as bool? ?? false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('UserProvider.loadProfile error: $e');
    }
  }

  // ── Setters ───────────────────────────────────────────────────
  void setName(String name) {
    _name = name.trim();
    notifyListeners();
  }

  void setSpiritAnimal(String animal) {
    _spiritAnimal = animal;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'name': _name,
        'spiritAnimal': _spiritAnimal,
        'onboardingComplete': true,
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('UserProvider.completeOnboarding error: $e');
    }
  }

  Future<void> updateName(String name) async {
    _name = name.trim();
    notifyListeners();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({'name': _name});
  }

  // ── Clear on sign-out ─────────────────────────────────────────
  void clear() {
    _name = '';
    _spiritAnimal = '';
    _onboardingComplete = false;
    notifyListeners();
  }
}
