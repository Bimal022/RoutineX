import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:routinex/auth/provider/user_provider.dart';
import 'package:routinex/main.dart';
import 'package:routinex/providers/expense_provider.dart';
import 'package:routinex/providers/habit_provider.dart';
import 'phone_auth_screen.dart';
import 'onboarding_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _loadedUid;

  Future<void> _loadUserData(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == _loadedUid) return;
    _loadedUid = uid;

    await Future.wait([
      context.read<UserProvider>().loadProfile(),
      context.read<HabitProvider>().loadHabits(),
      context.read<ExpenseProvider>().loadExpenses(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _splash();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          if (_loadedUid != null) {
            _loadedUid = null;
            context.read<UserProvider>().clear();
            context.read<HabitProvider>().clear();
            context.read<ExpenseProvider>().clear();
          }
          return const PhoneAuthScreen();
        }

        final userProvider = context.watch<UserProvider>();

        if (!userProvider.onboardingComplete) {
          return const OnboardingScreen();
        }

        _loadUserData(context);
        return const MainShell();
      },
    );
  }

  Widget _splash() => const Scaffold(
        backgroundColor: Color(0xFF0F0E17),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF6C63FF)),
          ),
        ),
      );
}