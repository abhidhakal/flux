import 'package:flutter/material.dart';
import '../../../shared/widgets/premium_page_hero.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/background_task_service.dart';
import '../../../core/services/enhanced_notification_service.dart';
import '../../auth/auth_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _notificationsEnabled = false;

  // Notification type preferences
  bool _budgetAlerts = true;
  bool _goalMilestones = true;
  bool _spendingAlerts = true;

  // Scheduled notifications
  bool _dailyReminders = false;
  bool _morningGreetings = false;
  bool _backgroundHealthChecks = true;

  int _dailyReminderHour = 20;
  int _dailyReminderMinute = 0;
  String _dailyReminderType = 'expense_log';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        final enabled = await _notificationService.areNotificationsEnabled();

        // Load user preferences from Firestore
        final userDoc =
            await _firestore.collection('users').doc(user.user.id).get();
        final data = userDoc.data() ?? {};
        final prefs =
            data['notificationPreferences'] as Map<String, dynamic>? ?? {};
        final schedules =
            data['notificationSchedules'] as Map<String, dynamic>? ?? {};

        if (!mounted) return;
        setState(() {
          _notificationsEnabled = enabled;

          // Load notification type preferences
          _budgetAlerts = prefs['budgetAlerts'] ?? true;
          _goalMilestones = prefs['goalMilestones'] ?? true;
          _spendingAlerts = prefs['spendingAlerts'] ?? true;

          // Load schedule preferences
          _dailyReminders = schedules['daily_reminder']?['enabled'] ?? false;
          _morningGreetings =
              schedules['morning_greeting']?['enabled'] ?? false;
          _backgroundHealthChecks =
              schedules['background_health_check']?['enabled'] ?? true;

          if (schedules['daily_reminder'] != null) {
            _dailyReminderHour = schedules['daily_reminder']['hour'] ?? 20;
            _dailyReminderMinute = schedules['daily_reminder']['minute'] ?? 0;
            _dailyReminderType =
                schedules['daily_reminder']['type'] ?? 'expense_log';
          }
        });
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.showError(context, message: 'Failed to load settings: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        await _firestore.collection('users').doc(user.user.id).set({
          'notificationPreferences': {
            'budgetAlerts': _budgetAlerts,
            'goalMilestones': _goalMilestones,
            'spendingAlerts': _spendingAlerts,
          },
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context,
            message: 'Failed to save preferences: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.pageSurface(context),
      body: Column(
        children: [
          const PremiumPageHero(
            title: 'Notifications',
            subtitle: 'Choose which alerts Flux can send',
            showBackButton: true,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPushNotificationCard(colorScheme),
                        const SizedBox(height: 16),
                        _buildAutomaticAlertsCard(colorScheme),
                        const SizedBox(height: 16),
                        _buildScheduledNotificationsCard(colorScheme),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPushNotificationCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_notificationsEnabled
                          ? AppColors.primary
                          : colorScheme.onSurfaceVariant)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _notificationsEnabled
                      ? LucideIcons.bellRing
                      : LucideIcons.bellOff,
                  color: _notificationsEnabled
                      ? AppColors.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Push Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _notificationsEnabled
                          ? 'Notifications are enabled'
                          : 'Enable to receive alerts',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                onChanged: (value) => _toggleNotifications(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutomaticAlertsCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automatic Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'These alerts are triggered automatically based on your activity',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          _buildAlertToggle(
            'Budget Alerts',
            'When you reach 80%, 90%, or exceed your budget',
            LucideIcons.coins,
            _budgetAlerts,
            (value) {
              setState(() => _budgetAlerts = value);
              _savePreferences();
            },
            colorScheme,
          ),
          const Divider(height: 24),
          _buildAlertToggle(
            'Goal Milestones',
            'When you reach 25%, 50%, 90%, or complete a goal',
            LucideIcons.goal,
            _goalMilestones,
            (value) {
              setState(() => _goalMilestones = value);
              _savePreferences();
            },
            colorScheme,
          ),
          const Divider(height: 24),
          _buildAlertToggle(
            'Spending Alerts',
            'When unusual spending patterns are detected',
            LucideIcons.trendingUp,
            _spendingAlerts,
            (value) {
              setState(() => _spendingAlerts = value);
              _savePreferences();
            },
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertToggle(
    String title,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: _notificationsEnabled ? onChanged : null,
        ),
      ],
    );
  }

  Widget _buildScheduledNotificationsCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduled Reminders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set up recurring reminders to stay on track',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),

          // Daily Reminder
          _buildScheduleItem(
            'Daily Reminder',
            'Reminder at ${_formatTime(_dailyReminderHour, _dailyReminderMinute)}',
            LucideIcons.alarmClock,
            _dailyReminders,
            (value) async {
              setState(() => _dailyReminders = value);
              if (value) {
                await _scheduleDailyReminder();
              } else {
                await _cancelDailyReminder();
              }
            },
            colorScheme,
            onConfigure: _dailyReminders
                ? () => _showDailyReminderConfig(colorScheme)
                : null,
          ),
          const Divider(height: 24),
          _buildScheduleItem(
            'Morning Greeting',
            'Start your day with a quick financial status at 8:00 AM',
            LucideIcons.sun,
            _morningGreetings,
            (value) async {
              setState(() => _morningGreetings = value);
              if (value) {
                await _scheduleMorningGreeting();
              } else {
                await _cancelMorningGreeting();
              }
            },
            colorScheme,
          ),
          const Divider(height: 24),
          _buildScheduleItem(
            'Background Checks',
            'Allow periodic health checks of your budgets and goals',
            LucideIcons.shieldCheck,
            _backgroundHealthChecks,
            (value) async {
              setState(() => _backgroundHealthChecks = value);
              await _toggleBackgroundChecks(value);
            },
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
    String title,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    ColorScheme colorScheme, {
    VoidCallback? onConfigure,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (onConfigure != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onConfigure,
                      child: Icon(
                        LucideIcons.settings,
                        size: 18,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: _notificationsEnabled ? onChanged : null,
        ),
      ],
    );
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDailyReminderTime(ColorScheme colorScheme) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _dailyReminderHour, minute: _dailyReminderMinute),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: AppColors.primary,
              surface: colorScheme.surface,
              onSurface: colorScheme.onSurface,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dailyReminderHour = picked.hour;
        _dailyReminderMinute = picked.minute;
      });
    }
  }

  void _showDailyReminderConfig(ColorScheme colorScheme) {
    AppBottomSheet.show(
      context,
      radius: 24,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Reminder Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Text('Reminder Type',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _dailyReminderType,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'expense_log', child: Text('Log your expenses')),
                DropdownMenuItem(
                    value: 'budget_check', child: Text('Check your budget')),
                DropdownMenuItem(
                    value: 'goal_update', child: Text('Update goal progress')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setModalState(() => _dailyReminderType = value);
                  setState(() => _dailyReminderType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Text('Time',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                await _pickDailyReminderTime(colorScheme);
                setModalState(() {});
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.clock, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _formatTime(_dailyReminderHour, _dailyReminderMinute),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      LucideIcons.chevronDown,
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  _scheduleDailyReminder();
                  Navigator.pop(sheetContext);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleNotifications() async {
    try {
      if (_notificationsEnabled) {
        await _notificationService.cancelAllScheduledNotifications();
        if (!mounted) return;
        setState(() => _notificationsEnabled = false);
        AppSnackbar.showInfo(context, message: 'Notifications disabled');
      } else {
        final enabled = await _notificationService.requestPermissions();
        if (!mounted) return;
        if (enabled) {
          setState(() => _notificationsEnabled = true);
          final user = context.read<AuthBloc>().state;
          if (user is AuthAuthenticated) {
            if (_dailyReminders) {
              await _scheduleDailyReminder();
            }
            if (_morningGreetings) {
              await _scheduleMorningGreeting();
            }
            if (_backgroundHealthChecks) {
              await BackgroundTaskService()
                  .registerDailyHealthCheck(user.user.id);
            }
            if (!mounted) return;
          }
          AppSnackbar.showSuccess(context, message: 'Notifications enabled');
        } else {
          AppSnackbar.showError(context,
              message: 'Please enable notifications in settings');
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(context,
          message: 'Failed to toggle notifications: $e');
    }
  }

  Future<void> _scheduleDailyReminder() async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        await _notificationService.scheduleDailyReminder(
          userId: user.user.id,
          hour: _dailyReminderHour,
          minute: _dailyReminderMinute,
          reminderType: _dailyReminderType,
        );
        if (!mounted) {
          return;
        }
        AppSnackbar.showSuccess(context, message: 'Daily reminder scheduled');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(context, message: 'Failed to schedule: $e');
    }
  }

  Future<void> _cancelDailyReminder() async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        await _notificationService.cancelDailyReminder(user.user.id);
        if (!mounted) {
          return;
        }
        AppSnackbar.showInfo(context, message: 'Daily reminder disabled');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(context, message: 'Failed to disable: $e');
    }
  }

  Future<void> _scheduleMorningGreeting() async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        await _notificationService.scheduleMorningGreeting(user.user.id,
            force: true);
        if (!mounted) {
          return;
        }
        AppSnackbar.showSuccess(context, message: 'Morning greeting scheduled');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(context,
          message: 'Failed to schedule greeting: $e');
    }
  }

  Future<void> _cancelMorningGreeting() async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        await _notificationService.cancelMorningGreeting(user.user.id);
        if (!mounted) {
          return;
        }
        AppSnackbar.showInfo(context, message: 'Morning greeting disabled');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(context, message: 'Failed to disable: $e');
    }
  }

  Future<void> _toggleBackgroundChecks(bool enabled) async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        await _firestore.collection('users').doc(user.user.id).set({
          'notificationSchedules': {
            'background_health_check': {'enabled': enabled},
          },
        }, SetOptions(merge: true));

        if (enabled) {
          await BackgroundTaskService().registerDailyHealthCheck(user.user.id);
        } else {
          await BackgroundTaskService().cancelTasks(user.user.id);
        }

        final msg = enabled
            ? 'Background checks enabled'
            : 'Background checks disabled';
        if (!mounted) {
          return;
        }
        AppSnackbar.showInfo(context, message: msg);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(context, message: 'Failed to update: $e');
    }
  }
}
