import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routinex/main.dart';
import 'phone_auth_screen.dart';

/// Listens to Firebase auth state and routes to the correct screen.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still waiting for Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0E17),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF6C63FF)),
              ),
            ),
          );
        }

        // Signed in → show app
        if (snapshot.hasData && snapshot.data != null) {
          return const MainShell();
        }

        // Not signed in → show auth
        return const PhoneAuthScreen();
      },
    );
  }
}