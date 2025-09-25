import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/notification_helper.dart';
import '../themes/app_theme.dart';

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
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                      _showSnackbar(
                        context,
                        'Tema berhasil diubah ke ${value ? 'gelap' : 'terang'}',
                      );
                    },
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    inactiveThumbColor: Theme.of(context).colorScheme.outline,
                    inactiveTrackColor: Theme.of(
                      context,
                    ).colorScheme.outline.withAlpha(51),
                  ),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Pengingat Harian',
                  subtitle: _notificationHelper.isPlatformSupported
                      ? (themeProvider.isDailyReminderEnabled
                            ? 'Notifikasi makan siang aktif (11:00 WIB)'
                            : 'Notifikasi pengingat nonaktif')
                      : 'Tidak tersedia di platform ini (Windows/Web)',
                  trailing: Switch(
                    value:
                        _notificationHelper.isPlatformSupported &&
                        themeProvider.isDailyReminderEnabled,
                    onChanged: _notificationHelper.isPlatformSupported
                        ? (value) async {
                            await _handleReminderToggle(value, themeProvider);
                          }
                        : null,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    inactiveThumbColor: Theme.of(context).colorScheme.outline,
                    inactiveTrackColor: Theme.of(
                      context,
                    ).colorScheme.outline.withAlpha(51),
                  ),
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
                  onTap: () => _showAboutDialog(context),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Test Notifikasi',
                  subtitle: _notificationHelper.isPlatformSupported
                      ? 'Uji coba notifikasi pengingat'
                      : 'Tidak tersedia di platform ini',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: _notificationHelper.isPlatformSupported
                          ? 0.4
                          : 0.2,
                    ),
                  ),
                  onTap: _notificationHelper.isPlatformSupported
                      ? () async => await _handleTestNotification()
                      : null,
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space8,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          height: 1.4,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
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
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                'Tentang Pengingat Harian',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            'Fitur pengingat harian akan mengirimkan notifikasi setiap hari pada pukul 11:00 WIB untuk mengingatkan Anda makan siang. Notifikasi berisi saran restoran acak dari daftar favorit atau restoran populer.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              height: 1.5,
            ),
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

  Future<void> _handleTestNotification() async {
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

      // Initialize notifications first
      final initialized = await _notificationHelper.initNotifications();
      if (!initialized) {
        if (mounted) {
          _showSnackbar(context, 'Gagal menginisialisasi notifikasi');
        }
        return;
      }

      // Show test notification
      final success = await _notificationHelper.showNotification(
        'Test Notifikasi Restaurant App',
        '🍽️ Sudah saatnya makan siang! Cek restoran favorit Anda.',
      );

      if (mounted) {
        if (success) {
          _showSnackbar(context, 'Notifikasi test berhasil dikirim');
        } else {
          _showSnackbar(
            context,
            'Gagal mengirim notifikasi - periksa izin aplikasi',
          );
        }
      }
    } catch (e) {
      debugPrint('Gagal mengirim notifikasi test: $e');
      if (mounted) {
        _showSnackbar(context, 'Gagal mengirim notifikasi: ${e.toString()}');
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

  String _getNotificationSubtitle(bool isEnabled) {
    if (!_notificationHelper.isPlatformSupported) {
      return 'Tidak tersedia di platform ini (Windows/Web)';
    }
    return isEnabled
        ? 'Notifikasi makan siang aktif (11:00 WIB)'
        : 'Notifikasi pengingat nonaktif';
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
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
