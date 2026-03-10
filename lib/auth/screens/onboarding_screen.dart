import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:routinex/auth/provider/user_provider.dart';
import 'package:routinex/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controllers
  final _nameController = TextEditingController();
  String? _selectedAnimal;

  // Animation controllers per page
  late final List<AnimationController> _animControllers;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  // The funny question options
  static const _animals = [
    (emoji: '🦥', label: 'Sloth',      desc: 'starts at noon, naps at 1'),
    (emoji: '🐝', label: 'Bee',        desc: 'up at 5am, spreadsheets by 6'),
    (emoji: '🦊', label: 'Fox',        desc: 'chaotic but always wins somehow'),
    (emoji: '🐢', label: 'Turtle',     desc: 'slow and steady, never skips leg day'),
    (emoji: '🦄', label: 'Unicorn',    desc: 'perfect habits, suspicious energy'),
    (emoji: '🐙', label: 'Octopus',    desc: 'eight tasks open, zero finished'),
  ];

  @override
  void initState() {
    super.initState();
    _animControllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 550),
      ),
    );
    _fadeAnims = _animControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _slideAnims = _animControllers
        .map((c) => Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)))
        .toList();

    // Kick off first page animation
    _animControllers[0].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    for (final c in _animControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      // Validate nothing on splash — just advance
    } else if (_currentPage == 1) {
      if (_nameController.text.trim().isEmpty) {
        _shake();
        return;
      }
      Provider.of<UserProvider>(context, listen: false)
          .setName(_nameController.text);
    } else if (_currentPage == 2) {
      if (_selectedAnimal == null) {
        _shake();
        return;
      }
      Provider.of<UserProvider>(context, listen: false)
          .setSpiritAnimal(_selectedAnimal!);
      Provider.of<UserProvider>(context, listen: false).completeOnboarding();
      return; // AuthWrapper rebuild handles navigation
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  // Shake the button briefly on validation fail
  final _shakeKey = GlobalKey();
  bool _shaking = false;
  void _shake() async {
    setState(() => _shaking = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _shaking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.only(top: 24, right: 24, left: 24),
              child: Row(
                children: List.generate(3, (i) => _dot(i)),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  _animControllers[i].reset();
                  _animControllers[i].forward();
                },
                children: [
                  _buildSplashPage(),
                  _buildNamePage(),
                  _buildFunnyPage(),
                ],
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: _buildCTA(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 0: Welcome splash ────────────────────────────────────
  Widget _buildSplashPage() {
    return FadeTransition(
      opacity: _fadeAnims[0],
      child: SlideTransition(
        position: _slideAnims[0],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              // Animated logo blob
              _logoBadge(),
              const SizedBox(height: 40),
              const Text(
                'Your life,\nfinally on\ntrack. 🚀',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Build habits that stick. Track every rupee.\nActually show up for yourself.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              // Feature pills
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _pill('✅  Daily habits'),
                  _pill('💸  Expense tracker'),
                  _pill('🔥  Streaks'),
                  _pill('📊  Stats'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page 1: Name ──────────────────────────────────────────────
  Widget _buildNamePage() {
    return FadeTransition(
      opacity: _fadeAnims[1],
      child: SlideTransition(
        position: _slideAnims[1],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              _stepLabel('Step 1 of 2'),
              const SizedBox(height: 16),
              const Text(
                "First things first —\nwhat do we\ncall you?",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We promise not to spam you with\nmotivational quotes at 6am.",
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                autofocus: false,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'Your name...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text('👋', style: TextStyle(fontSize: 20)),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: AppTheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 20),
                ),
                onSubmitted: (_) => _nextPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page 2: Funny question ────────────────────────────────────
  Widget _buildFunnyPage() {
    final name = _nameController.text.trim().split(' ').first;
    return FadeTransition(
      opacity: _fadeAnims[2],
      child: SlideTransition(
        position: _slideAnims[2],
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              _stepLabel('Step 2 of 2  •  The important one'),
              const SizedBox(height: 16),
              Text(
                name.isNotEmpty
                    ? "Okay $name,\nbe honest. 🧐"
                    : "Okay,\nbe honest. 🧐",
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Which animal best represents\nyour current daily routine?",
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              ...List.generate(_animals.length, (i) {
                final a = _animals[i];
                final selected = _selectedAnimal == a.label;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAnimal = a.label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withOpacity(0.15)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.surfaceLight,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primary.withOpacity(0.2)
                                : AppTheme.surfaceLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(a.emoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.label,
                                style: TextStyle(
                                  color: selected
                                      ? AppTheme.primary
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '"${a.desc}"',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: selected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── CTA button ───────────────────────────────────────────────
  Widget _buildCTA() {
    final labels = ["Let's go →", 'Continue →', "I'm ready ✦"];
    final colors = [AppTheme.primary, AppTheme.primary, AppTheme.secondary];

    return AnimatedContainer(
      key: _shakeKey,
      duration: const Duration(milliseconds: 80),
      transform: _shaking
          ? (Matrix4.identity()..translate(6.0, 0.0))
          : Matrix4.identity(),
      child: GestureDetector(
        onTap: _nextPage,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors[_currentPage],
                colors[_currentPage].withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors[_currentPage].withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              labels[_currentPage],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _dot(int index) {
    final active = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 6),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppTheme.primary : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _stepLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _logoBadge() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'RX',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}