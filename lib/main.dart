import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:routinex/widgets/layout/stats_screen.dart';

import 'providers/habit_provider.dart';
import 'providers/expense_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: const RoutineXApp(),
    ),
  );
}

class RoutineXApp extends StatelessWidget {
  const RoutineXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoutineX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
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

  final List<Widget> _screens = const [HomeScreen(), StatsScreen()];

  @override
  Widget build(BuildContext context) {
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: "Stats",
            ),
          ],
        ),
      ),
    );
  }
}
