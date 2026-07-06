import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/ticket_service.dart';
import '../models/ticket_model.dart';
import '../widgets/bottom_nav.dart';
import 'notification_page.dart';
import 'create_ticket_page.dart';

class UserDashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  const UserDashboardScreen(
      {super.key, required this.onToggleTheme, required this.themeMode});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
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
    final user = AuthService().currentUser!;
    final myTickets = TicketService().ticketsForUser(user.id);

    final pages = [
      _buildHome(myTickets, user),
      _buildTicketList(myTickets),
      const NotificationScreen(),
      _buildProfileTab(user),
    ];

    return Scaffold(
      appBar: _currentIndex == 2 || _currentIndex == 3
          ? null
          : AppBar(
              title: const Text('HelpPoint'),
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
      body: pages[_currentIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton(
              backgroundColor: AppColors.accent,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateTicketScreen()),
                );
              },
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHome(List<TicketModel> myTickets, user) {
    return RefreshIndicator(
      onRefresh: () => TicketService().loadTickets(),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Halo, ${user.name}',
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Pelapor · ${user.username}',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 36,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                      'Sampaikan keluhan IT Anda, tim kami yang menindaklanjuti.',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.72), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.statusOpen.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.statusOpen.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alur Layanan',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  _flowStep('1', 'Buat Tiket', 'Ajukan permasalahan Anda',
                      AppColors.primary),
                  _flowStep('2', 'Ditugaskan ke Helpdesk',
                      'Tim helpdesk menangani tiket', AppColors.roleHelpdesk),
                  _flowStep('3', 'Sedang Dikerjakan',
                      'Helpdesk memproses masalah', AppColors.statusInProgress),
                  _flowStep('4', 'Selesai', 'Masalah terselesaikan',
                      AppColors.statusResolved,
                      isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                _miniStat('Total', '${myTickets.length}', AppColors.primary),
                const SizedBox(width: 10),
                _miniStat(
                    'Proses',
                    '${myTickets.where((t) => t.status != TicketStatus.resolved && t.status != TicketStatus.closed).length}',
                    AppColors.statusInProgress),
                const SizedBox(width: 10),
                _miniStat(
                    'Selesai',
                    '${myTickets.where((t) => t.status == TicketStatus.resolved || t.status == TicketStatus.closed).length}',
                    AppColors.statusResolved),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tiket Terbaru',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: const Text('Lihat Semua',
                      style: TextStyle(color: AppColors.accent)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (TicketService().isLoading && myTickets.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (myTickets.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined,
                        size: 48, color: AppColors.textSecondaryLight),
                    const SizedBox(height: 8),
                    const Text('Belum ada tiket'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CreateTicketScreen()),
                        );
                      },
                      child: const Text('Buat Tiket Sekarang'),
                    ),
                  ],
                ),
              )
            else
              ...myTickets.take(3).map((t) => _ticketItem(t)),
          ],
        ),
      ),
    );
  }

  Widget _flowStep(String num, String title, String desc, Color color,
      {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(num,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 24, color: color.withOpacity(0.3)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: color)),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketList(List<TicketModel> myTickets) {
    if (myTickets.isEmpty) {
      return const Center(child: Text('Belum ada tiket'));
    }
    return RefreshIndicator(
      onRefresh: () => TicketService().loadTickets(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myTickets.length,
        itemBuilder: (_, i) => _ticketItem(myTickets[i]),
      ),
    );
  }

  Widget _ticketItem(TicketModel ticket) {
    final fc = _statusColor(ticket.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, '/ticket-detail',
            arguments: {'ticketId': ticket.id}),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(ticket.ticketNumber,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  _badge(ticketStatusLabel(ticket.status), fc),
                ],
              ),
              const SizedBox(height: 6),
              Text(ticket.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                  '${ticket.category} · ${DateFormat('d MMM yyyy').format(ticket.createdAt)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondaryLight)),
              if (ticket.assignedHelpdeskName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Ditangani: ${ticket.assignedHelpdeskName}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.roleHelpdesk,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(user) {
    // Profile tab inline ringan; detail lengkap tetap di ProfileScreen via route.
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.person, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 12),
            Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(user.email, style: const TextStyle(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              child: const Text('Lihat Profil Lengkap'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(val,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 20, color: color)),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return StampBadge(label: label, color: color);
  }
}
