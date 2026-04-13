import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const ProfileScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.primary,
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.person, color: Colors.white, size: 50),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'john.doe@student.unair.ac.id',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'User',
                      style: TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stats Row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatChip(context, '24', 'Total Tiket'),
                  const SizedBox(width: 12),
                  _buildStatChip(context, '8', 'Open'),
                  const SizedBox(width: 12),
                  _buildStatChip(context, '10', 'Resolved'),
                ],
              ),
            ),

            // Settings Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Akun'),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profil',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.lock_outline_rounded,
                    label: 'Ganti Password',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    label: 'Notifikasi',
                    onTap: () {},
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeThumbColor: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 8),
                  _buildSectionHeader('Tampilan'),
                  _buildMenuItem(
                    context,
                    icon: themeMode == ThemeMode.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    label: themeMode == ThemeMode.dark ? 'Mode Terang' : 'Mode Gelap',
                    onTap: onToggleTheme,
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (_) => onToggleTheme(),
                      activeThumbColor: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 8),
                  _buildSectionHeader('Informasi'),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    label: 'Tentang Aplikasi',
                    onTap: () => _showAboutDialog(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    label: 'Bantuan & FAQ',
                    onTap: () {},
                  ),

                  const SizedBox(height: 8),

                  // Logout
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.logout_rounded,
                          color: Colors.red),
                      title: const Text(
                        'Keluar',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'E-Ticketing Helpdesk v1.0.0\n© 2026 Universitas Airlangga',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, '/dashboard');
          if (i == 1) Navigator.pushReplacementNamed(context, '/tickets');
        },
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.headset_mic_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('E-Ticketing Helpdesk',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Text('Versi 1.0.0',
                style: TextStyle(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 12),
            const Text(
              'Aplikasi mobile helpdesk untuk DIV Teknik Informatika Universitas Airlangga',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
