import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/notification_helper.dart';
import '../themes/app_theme.dart';
import '../debug_notification.dart';
import '../debug_notification_test.dart';
import '../test_immediate_notification.dart';
import '../debug_daily_reminder_test.dart';
import '../test_daily_reminder_real.dart';
import '../enhanced_daily_test.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationHelper _notificationHelper = NotificationHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Debug Tools',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Basic Debug'),
                    subtitle: const Text('Original notification debug'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationDebugScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.science),
                    title: const Text('Comprehensive Test'),
                    subtitle: const Text('Detailed notification testing'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationTestScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Immediate Test'),
                    subtitle: const Text('Test notifications for today'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImmediateNotificationTestScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Daily Reminder Debug'),
                    subtitle: const Text('Debug daily reminder issues'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DailyReminderDebugScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Real Daily Test'),
                    subtitle: const Text('Test real daily reminder scenarios'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RealDailyReminderTestScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.enhanced_encryption),
                    title: const Text('Enhanced Daily Test'),
                    subtitle: const Text('Advanced daily reminder testing'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EnhancedDailyTestScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.science,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space24,
              vertical: AppTheme.space16,
            ),
            children: [
              // App Preferences Section
              _buildSectionHeader('Preferensi Aplikasi'),
              const SizedBox(height: AppTheme.space16),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Tema Gelap',
                  subtitle: themeProvider.isDarkMode
                      ? 'Tema gelap aktif'
                      : 'Tema terang aktif',
                  trailing: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        themeProvider.toggleTheme();
                        _showSnackbar(
                          context,
                          'Tema berhasil diubah ke ${value ? 'gelap' : 'terang'}',
                        );
                      },
                      activeColor: Theme.of(context).colorScheme.secondary,
                      activeTrackColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.3),
                      inactiveThumbColor: Theme.of(context).colorScheme.outline,
                      inactiveTrackColor: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Pengingat Harian',
                  subtitle: _notificationHelper.isPlatformSupported
                      ? (themeProvider.isDailyReminderEnabled
                            ? 'Notifikasi makan siang aktif (${themeProvider.notificationTime.hour.toString().padLeft(2, '0')}:${themeProvider.notificationTime.minute.toString().padLeft(2, '0')} WIB)'
                            : 'Notifikasi pengingat nonaktif')
                      : 'Tidak tersedia di platform ini (Windows/Web)',
                  trailing: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Switch(
                      value:
                          _notificationHelper.isPlatformSupported &&
                          themeProvider.isDailyReminderEnabled,
                      onChanged: _notificationHelper.isPlatformSupported
                          ? (value) async {
                              HapticFeedback.lightImpact();
                              await _handleReminderToggle(value, themeProvider);
                            }
                          : null,
                      activeColor: Theme.of(context).colorScheme.secondary,
                      activeTrackColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.3),
                      inactiveThumbColor: Theme.of(context).colorScheme.outline,
                      inactiveTrackColor: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                if (_notificationHelper.isPlatformSupported &&
                    themeProvider.isDailyReminderEnabled)
                  _buildDivider(),
                if (_notificationHelper.isPlatformSupported &&
                    themeProvider.isDailyReminderEnabled)
                  _buildSettingsTile(
                    icon: Icons.schedule_outlined,
                    title: 'Waktu Pengingat',
                    subtitle:
                        'Atur jam notifikasi harian (${themeProvider.notificationTime.hour.toString().padLeft(2, '0')}:${themeProvider.notificationTime.minute.toString().padLeft(2, '0')} WIB)',
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showTimePicker(context, themeProvider);
                    },
                  ),
              ]),

              const SizedBox(height: AppTheme.space32),

              // App Information Section
              _buildSectionHeader('Informasi Aplikasi'),
              const SizedBox(height: AppTheme.space16),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'Tentang Aplikasi',
                  subtitle: 'Restaurant App v1.0.0',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showAboutDialog(context);
                  },
                ),
              ]),

              const SizedBox(height: AppTheme.space32),

              // Daily Reminder Info Section
              if (_notificationHelper.isPlatformSupported) _buildInfoCard(),

              if (!_notificationHelper.isPlatformSupported)
                _buildPlatformWarningCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.space4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          highlightColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.05),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space20,
              vertical: AppTheme.space12,
            ),
            child: Row(
              children: [
                // Icon container dengan hover effect
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.space16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.65),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppTheme.space12),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
      indent: AppTheme.space20,
      endIndent: AppTheme.space20,
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                'Tentang Pengingat Harian',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Text(
                'Fitur pengingat harian akan mengirimkan notifikasi setiap hari pada pukul ${themeProvider.notificationTime.hour.toString().padLeft(2, '0')}:${themeProvider.notificationTime.minute.toString().padLeft(2, '0')} WIB untuk mengingatkan Anda makan siang. Notifikasi berisi saran restoran acak dari daftar favorit atau restoran populer.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformWarningCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: AppTheme.space8),
              Text(
                'Fitur Notifikasi Tidak Tersedia',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            'Notifikasi pengingat harian hanya tersedia di platform Android, iOS, Linux, dan macOS. Platform Windows dan Web saat ini tidak mendukung fitur notifikasi lokal.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.orange.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReminderToggle(
    bool value,
    ThemeProvider themeProvider,
  ) async {
    try {
      if (!_notificationHelper.isPlatformSupported) {
        if (mounted) {
          _showSnackbar(
            context,
            'Notifikasi hanya tersedia di Android, iOS, dan Linux',
          );
        }
        return;
      }

      if (value) {
        // Initialize notifications and request permissions
        final initialized = await _notificationHelper.initNotifications();
        if (!initialized) {
          if (mounted) {
            _showSnackbar(context, 'Gagal menginisialisasi notifikasi');
          }
          return;
        }

        // Request permissions for iOS
        if (Theme.of(context).platform == TargetPlatform.iOS) {
          final permitted = await _notificationHelper.requestIOSPermissions();
          if (!permitted) {
            if (mounted) {
              _showSnackbar(
                context,
                'Izin notifikasi diperlukan untuk fitur ini',
              );
            }
            return;
          }
        }

        // Schedule daily reminder
        await _notificationHelper.scheduleDailyReminder();
        await themeProvider.setDailyReminder(true);

        if (mounted) {
          _showSnackbar(
            context,
            'Pengingat harian diaktifkan untuk pukul 11:00 WIB',
          );
        }
      } else {
        // Cancel daily reminder
        await _notificationHelper.cancelDailyReminder();
        await themeProvider.setDailyReminder(false);

        if (mounted) {
          _showSnackbar(context, 'Pengingat harian dinonaktifkan');
        }
      }
    } catch (e) {
      debugPrint('Gagal mengatur toggle pengingat: $e');
      if (mounted) {
        _showSnackbar(context, 'Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey[900],
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? Colors.grey[850] : Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    ThemeProvider themeProvider,
  ) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: themeProvider.notificationTime,
      helpText: 'Pilih Waktu Pengingat Harian',
      cancelText: 'Batal',
      confirmText: 'Simpan',
      hourLabelText: 'Jam',
      minuteLabelText: 'Menit',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              // Background dengan kontras tinggi
              backgroundColor: isDark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.white,

              // Hour/Minute containers dengan readability tinggi
              hourMinuteColor: isDark
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.8)
                  : Theme.of(context).colorScheme.primaryContainer,
              hourMinuteTextColor: isDark
                  ? Colors.white
                  : Theme.of(context).colorScheme.onPrimaryContainer,

              // Dial dengan kontras optimal
              dialBackgroundColor: isDark
                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              dialHandColor: Theme.of(context).colorScheme.primary,
              dialTextColor: isDark
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,

              // Numbers pada dial
              dayPeriodTextColor: isDark
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,

              // Entry mode icons
              entryModeIconColor: Theme.of(context).colorScheme.onSurface,

              // Help text dengan readability tinggi
              helpTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),

              // Input decoration untuk entry mode
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: isDark
                    ? Theme.of(context).colorScheme.surfaceContainerHigh
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            // Dialog theme untuk shadow dan elevation
            dialogTheme: DialogThemeData(
              backgroundColor: isDark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: isDark
                  ? Colors.black.withOpacity(0.8)
                  : Colors.black.withOpacity(0.3),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != themeProvider.notificationTime) {
      try {
        final success = await themeProvider.setNotificationTime(pickedTime);

        if (success && mounted) {
          // Re-schedule reminder with new time if it's currently enabled
          if (themeProvider.isDailyReminderEnabled) {
            await _notificationHelper.cancelDailyReminder();
            await _notificationHelper.scheduleDailyReminder();
          }

          _showSnackbar(
            context,
            'Waktu pengingat diubah ke ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')} WIB',
          );
        } else if (mounted) {
          _showSnackbar(context, 'Gagal mengubah waktu pengingat');
        }
      } catch (e) {
        debugPrint('Error setting notification time: $e');
        if (mounted) {
          _showSnackbar(context, 'Terjadi kesalahan: ${e.toString()}');
        }
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Restaurant App',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Icon(
          Icons.restaurant,
          size: 32,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      children: [
        const SizedBox(height: AppTheme.space16),
        Text(
          'Aplikasi pencarian restoran dengan fitur favorit dan pengingat harian untuk menemukan tempat makan terbaik.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        Text(
          'Dibuat untuk submission Dicoding Flutter Fundamental dengan implementasi database, notifikasi, dan state management.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
