import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../services/auth_service.dart';
import '../services/ticket_service.dart';
import '../services/notification_service.dart';
import '../models/ticket_model.dart';
import 'edit_profile_page.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const ProfileScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _openEditProfile(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (result == true && mounted) {
      setState(() {}); // refresh tampilan nama/foto setelah update
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthService().currentUser;

    // Statistik disesuaikan per role:
    // - User: tiket yang dia buat sendiri (sebagai pelapor).
    // - Helpdesk: tiket yang ditugaskan kepadanya untuk ditangani.
    // - Admin: seluruh tiket di sistem (mengawasi semua).
    final List<TicketModel> myTickets;
    if (user == null) {
      myTickets = <TicketModel>[];
    } else if (user.isAdmin) {
      myTickets = TicketService().tickets;
    } else if (user.isHelpdesk) {
      myTickets = TicketService().ticketsForHelpdesk(user.id);
    } else {
      myTickets = TicketService().ticketsForUser(user.id);
    }

    final onToggleTheme = widget.onToggleTheme;
    final themeMode = widget.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                        backgroundImage: user?.avatarUrl != null
                            ? NetworkImage(user!.avatarUrl!)
                            : null,
                        child: user?.avatarUrl == null
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 50)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _openEditProfile(context),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? '-',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '-',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  StampBadge(
                    label: user?.roleLabel.toUpperCase() ?? '-',
                    color: AppColors.accentLight,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatChip(context, '${myTickets.length}', 'Total Tiket'),
                  const SizedBox(width: 12),
                  _buildStatChip(
                      context,
                      '${myTickets.where((t) => t.status == TicketStatus.open).length}',
                      'Open'),
                  const SizedBox(width: 12),
                  _buildStatChip(
                      context,
                      '${myTickets.where((t) => t.status == TicketStatus.resolved).length}',
                      'Resolved'),
                ],
              ),
            ),

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
                    onTap: () => _openEditProfile(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.lock_outline_rounded,
                    label: 'Ganti Password',
                    onTap: () =>
                        Navigator.pushNamed(context, '/forgot-password'),
                  ),

                  const SizedBox(height: 8),
                  _buildSectionHeader('Pengaturan'),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    label: 'Pengaturan Aplikasi',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/settings',
                      arguments: {
                        'onToggleTheme': onToggleTheme,
                        'themeMode': themeMode,
                      },
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: themeMode == ThemeMode.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    label:
                        themeMode == ThemeMode.dark ? 'Mode Terang' : 'Mode Gelap',
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

                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.logout_rounded, color: Colors.red),
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
                      'HelpPoint v3.0.0\n© 2026 Universitas Airlangga',
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
      bottomNavigationBar: (user?.isUser ?? true)
          ? AppBottomNav(
              currentIndex: 3,
              onTap: (i) {
                if (i == 0) Navigator.pushReplacementNamed(context, '/dashboard');
                if (i == 1) Navigator.pushReplacementNamed(context, '/tickets');
                if (i == 2) Navigator.pushNamed(context, '/notifications');
              },
            )
          : null,
    );
  }

  Widget _buildStatChip(BuildContext context, String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11)),
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
        title:
            const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              TicketService().unsubscribeRealtime();
              NotificationService().unsubscribeRealtime();
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset('assets/images/logo_mark.png'),
            ),
            const SizedBox(height: 16),
            const Text('HelpPoint',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Text('Versi 3.0.0',
                style: TextStyle(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 12),
            const Text(
              'Layanan keluhan IT kampus untuk DIV Teknik Informatika Universitas Airlangga',
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
