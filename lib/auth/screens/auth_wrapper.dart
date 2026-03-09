import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:routinex/auth/provider/user_provider.dart';
import 'package:routinex/main.dart';
import 'package:routinex/providers/expense_provider.dart';
import 'package:routinex/providers/habit_provider.dart';
import 'phone_auth_screen.dart';
import 'onboarding_screen.dart';

/// Flow: PhoneAuth → Onboarding (first time) → MainShell
/// Triggers Firestore data load once the user is fully ready.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Track which UID we've already loaded data for — avoids re-fetching
  // on spurious rebuilds.
  String? _loadedUid;

  Future<void> _loadUserData(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == _loadedUid) return;
    _loadedUid = uid;

    await Future.wait([
      context.read<HabitProvider>().loadHabits(),
      context.read<ExpenseProvider>().loadExpenses(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Waiting for Firebase to respond
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _splash();
        }

        // ── Not signed in ──────────────────────────────────────
        if (!snapshot.hasData || snapshot.data == null) {
          // Clear cached data when the user signs out
          if (_loadedUid != null) {
            _loadedUid = null;
            context.read<HabitProvider>().clear();
            context.read<ExpenseProvider>().clear();
          }
          return const PhoneAuthScreen();
        }

        // ── Signed in ──────────────────────────────────────────
        final userProvider = context.watch<UserProvider>();

        if (!userProvider.onboardingComplete) {
          return const OnboardingScreen();
        }

        // Load Firestore data (runs once per UID)
        _loadUserData(context);

        return const MainShell();
      },
    );
  }

  Widget _splash() {
    return const Scaffold(
      backgroundColor: Color(0xFF0F0E17),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFF6C63FF)),
        ),
      ),
    );
  }
}