import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:routinex/models/habit.dart';
import 'package:routinex/providers/habit_provider.dart';

import '../../theme.dart';

class AddHabitSheet extends StatefulWidget {
  const AddHabitSheet({super.key});

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _controller = TextEditingController();
  String _selectedEmoji = '✅';
  HabitType _type = HabitType.recurring;

  // For recurring: selected weekdays (1=Mon..7=Sun). Empty = every day.
  final Set<int> _selectedDays = {};

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<String> _emojis = [
    '✅', '💪', '🏃', '📚', '🧘', '💧',
    '🥗', '😴', '✍️', '🎯', '🧹', '💊',
    '🎵', '🌿', '🚴', '🙏',
  ];

  // Reminder state
  // null = no reminder, true = all day, false = specific time
  bool? _reminderMode; // null=none, true=allDay, false=specificTime
  int? _hour;
  int? _minute;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final bool allDay = _reminderMode == true;
    final int? hour = (_reminderMode == false) ? _hour : null;
    final int? minute = (_reminderMode == false) ? _minute : null;
    log('NotiTest Submitting habit with reminderMode=$_reminderMode, allDay=$allDay, hour=$hour, minute=$minute');
    Provider.of<HabitProvider>(context, listen: false).addHabit(
      text,
      _selectedEmoji,
      type: _type,
      weekdays: _selectedDays.toList()..sort(),
      allDay: allDay,
      hour: hour,
      minute: minute,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "New Habit",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // ── Type selector ──────────────────────────────────
              const Text(
                "Habit type",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _typeChip(
                    label: "Recurring",
                    icon: Icons.repeat_rounded,
                    value: HabitType.recurring,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  _typeChip(
                    label: "One-time",
                    icon: Icons.looks_one_outlined,
                    value: HabitType.oneTime,
                    color: AppTheme.accent,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Weekday picker (only for recurring) ────────────
              if (_type == HabitType.recurring) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Repeat on",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedDays.clear()),
                      child: Text(
                        _selectedDays.isEmpty ? "Every day ✓" : "Every day",
                        style: TextStyle(
                          color: _selectedDays.isEmpty
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final selected = _selectedDays.contains(day);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedDays.remove(day);
                        } else {
                          _selectedDays.add(day);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.surfaceLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? AppTheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _dayLabels[i],
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                if (_selectedDays.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _buildScheduleLabel(),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              if (_type == HabitType.oneTime) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.accent, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "This habit will only appear today and won't show up tomorrow.",
                          style: TextStyle(color: AppTheme.accent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Emoji picker ───────────────────────────────────
              const Text(
                "Choose an emoji",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojis.map((e) {
                  final selected = e == _selectedEmoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary.withOpacity(0.25)
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppTheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Reminder section ───────────────────────────────
              const Text(
                "Reminder",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),

              // Three-option reminder selector
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _reminderChip(
                      label: "None",
                      icon: Icons.notifications_off_outlined,
                      value: null,
                    ),
                    _reminderChip(
                      label: "All day",
                      icon: Icons.wb_sunny_outlined,
                      value: true,
                    ),
                    _reminderChip(
                      label: "Set time",
                      icon: Icons.access_time_rounded,
                      value: false,
                    ),
                  ],
                ),
              ),

              // Time picker row — only shown when "Set time" is selected
              if (_reminderMode == false) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _hour != null
                          ? TimeOfDay(hour: _hour!, minute: _minute!)
                          : TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _hour = time.hour;
                        _minute = time.minute;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hour != null
                            ? AppTheme.primary.withOpacity(0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _hour == null
                              ? "Tap to set reminder time"
                              : "${_hour!.toString().padLeft(2, '0')}:${_minute!.toString().padLeft(2, '0')}",
                          style: TextStyle(
                            color: _hour == null
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                            fontWeight: _hour != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // All day info pill
              if (_reminderMode == true) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.25),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        color: AppTheme.primary,
                        size: 15,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "This habit will stay visible all day until you complete it.",
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Name input ─────────────────────────────────────
              TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: "e.g. Drink 8 glasses of water",
                  labelText: "Habit name",
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == HabitType.oneTime
                        ? AppTheme.accent
                        : AppTheme.primary,
                  ),
                  child: const Text(
                    "Add Habit",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Three-way reminder mode chip (None / All day / Set time)
  Widget _reminderChip({
    required String label,
    required IconData icon,
    required bool? value,
  }) {
    final selected = _reminderMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _reminderMode = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required IconData icon,
    required HabitType value,
    required Color color,
  }) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? color : AppTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildScheduleLabel() {
    final sorted = _selectedDays.toList()..sort();
    return "Repeats on: ${sorted.map((d) => _dayNames[d - 1]).join(', ')}";
  }
}