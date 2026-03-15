import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:routinex/auth/provider/user_provider.dart';
import 'package:routinex/auth/screens/auth_wrapper.dart';
import 'package:routinex/auth/screens/profile_screen.dart';
import 'package:routinex/services/notification_service.dart';
import 'package:routinex/widgets/layout/stats_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'providers/habit_provider.dart';
import 'providers/expense_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void init() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  await GoogleSignIn.instance.initialize();
  await NotificationService.requestPermission();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const RoutineXApp(),
    ),
  );
}

class RoutineXApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  const RoutineXApp({super.key});

  @override
  State<RoutineXApp> createState() => _RoutineXAppState();
}

class _RoutineXAppState extends State<RoutineXApp> {
  @override
  void initState() {
    super.initState();

    // ② Wire the "Done" button action to HabitProvider.toggleHabit
    NotificationService.setListeners(
      onDoneAction: (habitId) async {
        // Access the provider without a BuildContext using the navigator key
        final context = RoutineXApp.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final provider = Provider.of<HabitProvider>(context, listen: false);
          // Only toggle if not already completed (avoids un-doing from notif)
          if (!provider.isCompleted(habitId)) {
            await provider.toggleHabit(habitId);
            await provider.loadHabits(); // Refresh to sync with Firestore after toggle
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoutineX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthWrapper(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final animal = user.spiritAnimal.isNotEmpty ? user.spiritAnimal : '';

    // Find the emoji for the current animal for the nav tab
    const animalEmojis = {
      'Sloth': '🦥',
      'Bee': '🐝',
      'Fox': '🦊',
      'Turtle': '🐢',
      'Unicorn': '🦄',
      'Octopus': '🐙',
    };
    final avatarEmoji = animalEmojis[animal] ?? '👤';

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.surfaceLight, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Text(avatarEmoji, style: const TextStyle(fontSize: 20)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
