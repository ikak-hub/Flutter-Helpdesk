import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

/// SRS 5.12 Setting Screen — pengaturan tampilan, akun, dan notifikasi.
class SettingScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const SettingScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _pushNotifEnabled = true;
  bool _emailNotifEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Tampilan'),
          Card(
            child: ListTile(
              leading: Icon(
                widget.themeMode == ThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Mode Gelap'),
              subtitle: Text(widget.themeMode == ThemeMode.dark
                  ? 'Aktif'
                  : 'Tidak aktif'),
              trailing: Switch(
                value: widget.themeMode == ThemeMode.dark,
                onChanged: (_) => widget.onToggleTheme(),
                activeThumbColor: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 16),
          _sectionHeader('Notifikasi'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined,
                      color: AppColors.primary),
                  title: const Text('Notifikasi Push'),
                  subtitle: const Text(
                      'Terima notifikasi perubahan status & komentar tiket'),
                  value: _pushNotifEnabled,
                  onChanged: (v) => setState(() => _pushNotifEnabled = v),
                  activeThumbColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.email_outlined,
                      color: AppColors.primary),
                  title: const Text('Notifikasi Email'),
                  subtitle:
                      const Text('Terima ringkasan aktivitas tiket via email'),
                  value: _emailNotifEnabled,
                  onChanged: (v) => setState(() => _emailNotifEnabled = v),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _sectionHeader('Akun'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded,
                      color: AppColors.primary),
                  title: const Text('Informasi Akun'),
                  subtitle: Text(user?.email ?? '-'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_outlined,
                      color: AppColors.primary),
                  title: const Text('Keamanan & Privasi'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _sectionHeader('Tentang'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary),
                  title: const Text('Versi Aplikasi'),
                  trailing: const Text('3.0.0',
                      style: TextStyle(color: AppColors.textSecondaryLight)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded,
                      color: AppColors.primary),
                  title: const Text('Bantuan & FAQ'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: AppColors.primary),
                  title: const Text('Kebijakan Privasi'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'HelpPoint v3.0.0\n© 2026 Universitas Airlangga',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textSecondaryLight)),
    );
  }
}
