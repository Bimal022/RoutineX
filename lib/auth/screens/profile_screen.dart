import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routinex/auth/provider/user_provider.dart';
import 'package:routinex/providers/expense_provider.dart';
import 'package:routinex/providers/habit_provider.dart';
import 'package:routinex/theme.dart';

// ── Animal metadata (mirrors onboarding) ─────────────────────────
class _Animal {
  final String emoji;
  final String label;
  final String desc;
  final Color color;
  final Color bg;

  const _Animal({
    required this.emoji,
    required this.label,
    required this.desc,
    required this.color,
    required this.bg,
  });
}

const _animals = [
  _Animal(
    emoji: '🦥', label: 'Sloth',
    desc: 'starts at noon, naps at 1',
    color: Color(0xFFB39DDB), bg: Color(0xFF2D2040),
  ),
  _Animal(
    emoji: '🐝', label: 'Bee',
    desc: 'up at 5am, spreadsheets by 6',
    color: Color(0xFFFFD54F), bg: Color(0xFF2D2700),
  ),
  _Animal(
    emoji: '🦊', label: 'Fox',
    desc: 'chaotic but always wins somehow',
    color: Color(0xFFFF8A65), bg: Color(0xFF2D1500),
  ),
  _Animal(
    emoji: '🐢', label: 'Turtle',
    desc: 'slow and steady, never skips leg day',
    color: Color(0xFF81C784), bg: Color(0xFF0D2010),
  ),
  _Animal(
    emoji: '🦄', label: 'Unicorn',
    desc: 'perfect habits, suspicious energy',
    color: Color(0xFFF48FB1), bg: Color(0xFF2D0A1A),
  ),
  _Animal(
    emoji: '🐙', label: 'Octopus',
    desc: 'eight tasks open, zero finished',
    color: Color(0xFF4DD0E1), bg: Color(0xFF001F26),
  ),
];

_Animal _animalFor(String label) =>
    _animals.firstWhere(
      (a) => a.label == label,
      orElse: () => _animals[0],
    );


// ────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Logout ───────────────────────────────────────────────────
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800)),
        content: const Text(
          "You will need to verify your phone number again to sign back in."
          ,style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    context.read<UserProvider>().clear();
    context.read<HabitProvider>().clear();
    context.read<ExpenseProvider>().clear();
    await FirebaseAuth.instance.signOut();
    // AuthWrapper will detect the sign-out and show PhoneAuthScreen
  }

  // ── Edit name ────────────────────────────────────────────────
  void _editName(BuildContext context, UserProvider user) {
    final ctrl = TextEditingController(text: user.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Edit name',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 17),
                decoration: InputDecoration(
                  hintText: 'Your name',
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppTheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final v = ctrl.text.trim();
                    if (v.isNotEmpty) user.updateName(v);
                    Navigator.pop(context);
                  },
                  child: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Change spirit animal ─────────────────────────────────────
  void _changeAnimal(BuildContext context, UserProvider user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnimalPickerSheet(currentAnimal: user.spiritAnimal),
    );
  }
  // ── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final habits = context.watch<HabitProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final animal = _animalFor(user.spiritAnimal);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              // ── Hero header ──────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHero(context, user, animal),
              ),

              // ── Stats row ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _buildStatsRow(habits, expenses),
                ),
              ),

              // ── Spirit animal card ───────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildAnimalCard(context, user, animal),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Menu items ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildMenu(context, user),
                ),
              ),

              // ── Sign out ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: _buildSignOutButton(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero section ─────────────────────────────────────────────
  Widget _buildHero(
      BuildContext context, UserProvider user, _Animal animal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            animal.color.withOpacity(0.2),
            AppTheme.bg,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: () => _changeAnimal(context, user),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: animal.bg,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: animal.color.withOpacity(0.6), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: animal.color.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(animal.emoji,
                        style: const TextStyle(fontSize: 52)),
                  ),
                ),
              ),
              // Edit badge
              GestureDetector(
                onTap: () => _changeAnimal(context, user),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: animal.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.bg, width: 2),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      size: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name row
          GestureDetector(
            onTap: () => _editName(context, user),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : 'Your Name',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_outlined,
                    size: 16, color: AppTheme.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Phone
          if (user.phoneNumber != null)
            Text(
              user.phoneNumber!,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14),
            ),
          const SizedBox(height: 8),

          // Spirit animal tag
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: animal.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: animal.color.withOpacity(0.4)),
            ),
            child: Text(
              '${animal.emoji}  Spirit animal: ${animal.label}',
              style: TextStyle(
                color: animal.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ────────────────────────────────────────────────
  Widget _buildStatsRow(HabitProvider habits, ExpenseProvider expenses) {
    return Row(
      children: [
        Expanded(
            child: _statCard(
          '${habits.todaysHabits.length}',
          'Habits',
          '📋',
          AppTheme.primary,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(
          '${habits.currentStreak}d',
          'Streak',
          '🔥',
          AppTheme.warning,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(
          '₹${expenses.weekTotal().toStringAsFixed(0)}',
          'This week',
          '💸',
          AppTheme.accent,
        )),
      ],
    );
  }

  Widget _statCard(
      String value, String label, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  // ── Spirit animal card ───────────────────────────────────────
  Widget _buildAnimalCard(
      BuildContext context, UserProvider user, _Animal animal) {
    return GestureDetector(
      onTap: () => _changeAnimal(context, user),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: animal.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: animal.color.withOpacity(0.35), width: 1.5),
        ),
        child: Row(
          children: [
            Text(animal.emoji,
                style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Spirit Animal: ${animal.label}',
                        style: TextStyle(
                          color: animal.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '"${animal.desc}"',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.swap_horiz_rounded,
                color: animal.color.withOpacity(0.6), size: 20),
          ],
        ),
      ),
    );
  }

  // ── Menu ─────────────────────────────────────────────────────
  Widget _buildMenu(BuildContext context, UserProvider user) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          _menuItem(
            icon: Icons.person_outline_rounded,
            label: 'Edit name',
            onTap: () => _editName(context, user),
          ),
          _divider(),
          _menuItem(
            icon: Icons.pets_rounded,
            label: 'Change spirit animal',
            onTap: () => _changeAnimal(context, user),
          ),
          _divider(),
          _menuItem(
            icon: Icons.copy_outlined,
            label: 'Copy phone number',
            onTap: () {
              if (user.phoneNumber != null) {
                Clipboard.setData(
                    ClipboardData(text: user.phoneNumber!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phone number copied'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppTheme.textPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary.withOpacity(0.5),
                size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        color: AppTheme.surfaceLight,
        indent: 18,
        endIndent: 18,
      );

  // ── Sign-out button ──────────────────────────────────────────
  Widget _buildSignOutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _logout(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.25)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Text(
              'Sign out',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ── Animal picker bottom sheet ────────────────────────────────────
class _AnimalPickerSheet extends StatefulWidget {
  final String currentAnimal;
  const _AnimalPickerSheet({required this.currentAnimal});

  @override
  State<_AnimalPickerSheet> createState() => _AnimalPickerSheetState();
}

class _AnimalPickerSheetState extends State<_AnimalPickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentAnimal;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Change spirit animal',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pick the one that truly speaks to your soul right now.',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ..._animals.map((a) {
            final selected = _selected == a.label;
            return GestureDetector(
              onTap: () => setState(() => _selected = a.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      selected ? a.bg : AppTheme.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? a.color.withOpacity(0.6)
                        : AppTheme.surfaceLight,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? a.color.withOpacity(0.2)
                            : AppTheme.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(a.emoji,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.label,
                              style: TextStyle(
                                color: selected
                                    ? a.color
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              )),
                          Text('"${a.desc}"',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              )),
                        ],
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: selected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: a.color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context
                    .read<UserProvider>()
                    .setSpiritAnimal(_selected);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _animalFor(_selected).color,
                foregroundColor: Colors.black87,
              ),
              child: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}