import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/ticket_service.dart';
import '../../models/ticket_model.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../notification_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const AdminDashboardScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    TicketService().addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    TicketService().removeListener(_refresh);
    super.dispose();
  }

  Color _statusColor(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return AppColors.statusOpen;
      case TicketStatus.assigned:
        return AppColors.roleHelpdesk;
      case TicketStatus.inProgress:
        return AppColors.statusInProgress;
      case TicketStatus.resolved:
        return AppColors.statusResolved;
      case TicketStatus.closed:
        return AppColors.statusClosed;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 3) {
      return Scaffold(
        body: const NotificationScreen(),
        bottomNavigationBar: AdminBottomNav(
          currentIndex: _currentIndex,
          onTap: _handleNavTap,
        ),
      );
    }

    final user = AuthService().currentUser;
    final store = TicketService();
    final pending = store.pendingTickets.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(widget.themeMode == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => store.loadTickets(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const ShapeDecoration(
                  color: AppColors.primary,
                  shape: TicketNotchBorder(radius: 16, notch: 26),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${user?.name ?? 'Admin'}',
                            style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text('Mengawasi seluruh tiket sistem',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 12.5)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('ADMINISTRATOR',
                                style: TextStyle(
                                    color: AppColors.accentLight,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6)),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 4, height: 56, color: AppColors.accent),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Statistik Sistem',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.15,
                children: [
                  _buildStatCard(context, 'Total Tiket', '${store.totalCount}',
                      Icons.confirmation_num_outlined, AppColors.primary),
                  _buildStatCard(context, 'Menunggu', '${store.openCount}',
                      Icons.hourglass_empty_rounded, AppColors.statusOpen),
                  _buildStatCard(context, 'Diproses',
                      '${store.inProgressCount}', Icons.autorenew_rounded,
                      AppColors.statusInProgress),
                  _buildStatCard(context, 'Selesai', '${store.resolvedCount}',
                      Icons.check_circle_outline, AppColors.statusResolved),
                ],
              ),
              const SizedBox(height: 24),

              Text('Menu Admin',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: [
                  _buildAdminMenu(context,
                      icon: Icons.list_alt_rounded,
                      label: 'Kelola Tiket',
                      subtitle: 'Lihat & proses tiket',
                      color: AppColors.primary,
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin-tickets')),
                  _buildAdminMenu(context,
                      icon: Icons.people_rounded,
                      label: 'Kelola User',
                      subtitle: 'Manajemen pengguna',
                      color: AppColors.statusResolved,
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin-users')),
                  _buildAdminMenu(context,
                      icon: Icons.bar_chart_rounded,
                      label: 'Laporan',
                      subtitle: 'Statistik tiket',
                      color: AppColors.statusInProgress,
                      onTap: () {}),
                  _buildAdminMenu(context,
                      icon: Icons.settings_rounded,
                      label: 'Pengaturan',
                      subtitle: 'Konfigurasi sistem',
                      color: AppColors.statusClosed,
                      onTap: () => Navigator.pushNamed(
                            context,
                            '/settings',
                            arguments: {
                              'onToggleTheme': widget.onToggleTheme,
                              'themeMode': widget.themeMode,
                            },
                          )),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tiket Perlu Tindakan',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/admin-tickets'),
                    child: const Text('Lihat Semua',
                        style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (store.isLoading && pending.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator()))
              else if (pending.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Tidak ada tiket pending',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                )
              else
                ...pending.map((t) => _buildTicketItem(context, t)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: _currentIndex,
        onTap: _handleNavTap,
      ),
    );
  }

  void _handleNavTap(int i) {
    if (i == 1) {
      Navigator.pushNamed(context, '/admin-tickets');
      return;
    }
    if (i == 2) {
      Navigator.pushNamed(context, '/admin-users');
      return;
    }
    if (i == 4) {
      Navigator.pushNamed(context, '/profile');
      return;
    }
    setState(() => _currentIndex = i);
  }

  Widget _buildStatCard(BuildContext context, String label, String count,
      IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 26),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count,
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w700, color: color)),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenu(BuildContext context,
      {required IconData icon,
      required String label,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 26),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                Text(subtitle,
                    style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketItem(BuildContext context, TicketModel ticket) {
    final statusColor = _statusColor(ticket.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.confirmation_num_outlined,
              color: statusColor, size: 20),
        ),
        title: Text(ticket.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Oleh: ${ticket.userName}', style: const TextStyle(fontSize: 11)),
            Row(
              children: [
                StampBadge(label: ticketStatusLabel(ticket.status), color: statusColor),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/ticket-detail',
              arguments: {'ticketId': ticket.id}),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 11),
          ),
          child: const Text('Proses'),
        ),
        onTap: () => Navigator.pushNamed(context, '/ticket-detail',
            arguments: {'ticketId': ticket.id}),
      ),
    );
  }
}
