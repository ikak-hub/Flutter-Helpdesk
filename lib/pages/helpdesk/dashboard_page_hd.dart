import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/ticket_service.dart';
import '../../models/ticket_model.dart';
import '../notification_page.dart';

/// Helpdesk Dashboard sesuai SRS FR-006: Helpdesk menangani tiket yang
/// ditugaskan, memberi tanggapan, mengubah status, dan menutup tiket.
/// (Role 'Technical Support' yang tidak ada di SRS telah dihapus —
/// helpdesk sekarang menangani tiket langsung sampai selesai.)
class HelpdeskDashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  const HelpdeskDashboardScreen(
      {super.key, required this.onToggleTheme, required this.themeMode});

  @override
  State<HelpdeskDashboardScreen> createState() =>
      _HelpdeskDashboardScreenState();
}

class _HelpdeskDashboardScreenState extends State<HelpdeskDashboardScreen> {
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

  Future<void> _acceptTicket(TicketModel ticket) async {
    final user = AuthService().currentUser!;
    final error = await TicketService().acceptTicket(ticket.id, user.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Tiket diterima'),
          backgroundColor:
              error == null ? AppColors.statusResolved : Colors.red,
        ),
      );
    }
  }

  Future<void> _startHandling(TicketModel ticket) async {
    await TicketService().updateStatus(ticket.id, TicketStatus.inProgress);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mulai menangani tiket'),
            backgroundColor: AppColors.statusInProgress),
      );
    }
  }

  void _resolveDialog(TicketModel ticket) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Selesaikan Tiket',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tuliskan ringkasan penyelesaian:'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                  hintText: 'Masalah telah diselesaikan dengan...'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.statusResolved),
            onPressed: () async {
              Navigator.pop(context);
              await TicketService().resolveTicket(
                ticket.id,
                ctrl.text.isNotEmpty ? ctrl.text : 'Masalah telah diselesaikan.',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Tiket berhasil diselesaikan!'),
                      backgroundColor: AppColors.statusResolved),
                );
              }
            },
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
  }

  void _addComment(TicketModel ticket) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Komentar'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Tulis komentar...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final user = AuthService().currentUser!;
              if (ctrl.text.trim().isNotEmpty) {
                await TicketService().addComment(
                  ticketId: ticket.id,
                  authorId: user.id,
                  authorName: user.name,
                  authorRole: 'Helpdesk',
                  message: ctrl.text.trim(),
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 2) {
      return Scaffold(
        body: const NotificationScreen(),
        bottomNavigationBar: _buildNavBar(),
      );
    }

    final store = TicketService();
    final user = AuthService().currentUser!;
    final myTickets = store.ticketsForHelpdesk(user.id);

    final pages = [
      _buildDashboard(myTickets, user),
      _buildTicketList(myTickets),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Helpdesk Dashboard'),
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
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) {
        if (i == 3) {
          Navigator.pushNamed(context, '/profile');
          return;
        }
        setState(() => _currentIndex = i);
      },
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard'),
        BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt_rounded),
            label: 'Tiket Saya'),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Notifikasi'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil'),
      ],
    );
  }

  Widget _buildDashboard(List<TicketModel> myTickets, user) {
    final waiting =
        myTickets.where((t) => t.status == TicketStatus.open).length;
    final handling =
        myTickets.where((t) => t.status == TicketStatus.assigned).length;
    final inProgress =
        myTickets.where((t) => t.status == TicketStatus.inProgress).length;

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
                color: AppColors.primaryLight,
                shape: TicketNotchBorder(radius: 16, notch: 26),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Halo, ${user.name}',
                            style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Menangani tiket yang ditugaskan',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12.5)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('TIM HELPDESK',
                              style: TextStyle(
                                  color: Colors.white,
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
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.roleHelpdesk.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.roleHelpdesk.withOpacity(0.3)),
              ),
              child: const Text(
                'Tugas Helpdesk:\n1. Terima tiket yang masuk\n2. Tangani & beri tanggapan\n3. Selesaikan & tutup tiket',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                _miniStat('Menunggu', '$waiting', AppColors.statusOpen),
                const SizedBox(width: 10),
                _miniStat('Ditugaskan', '$handling', AppColors.roleHelpdesk),
                const SizedBox(width: 10),
                _miniStat('Diproses', '$inProgress', AppColors.statusInProgress),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Tiket Menunggu Tindakan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),

            if (TicketService().isLoading && myTickets.isEmpty)
              const Center(child: CircularProgressIndicator())
            else ...[
              ...myTickets
                  .where((t) =>
                      t.status == TicketStatus.open ||
                      t.status == TicketStatus.assigned ||
                      t.status == TicketStatus.inProgress)
                  .map((t) => _ticketCard(t)),
              if (myTickets
                  .where((t) =>
                      t.status == TicketStatus.open ||
                      t.status == TicketStatus.assigned ||
                      t.status == TicketStatus.inProgress)
                  .isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child:
                        Text('Tidak ada tiket aktif', style: TextStyle(color: AppColors.textSecondaryLight)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(List<TicketModel> myTickets) {
    if (myTickets.isEmpty) {
      return const Center(child: Text('Belum ada tiket yang ditugaskan'));
    }
    return RefreshIndicator(
      onRefresh: () => TicketService().loadTickets(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myTickets.length,
        itemBuilder: (_, i) => _ticketCard(myTickets[i]),
      ),
    );
  }

  Widget _ticketCard(TicketModel ticket) {
    final fc = _statusColor(ticket.status);
    final canAccept = ticket.status == TicketStatus.open;
    final canStart = ticket.status == TicketStatus.assigned;
    final canResolve = ticket.status == TicketStatus.inProgress;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(ticket.ticketNumber,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                _badge(ticketStatusLabel(ticket.status), fc),
              ],
            ),
            const SizedBox(height: 6),
            Text(ticket.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Oleh: ${ticket.userName} · ${ticket.category}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canAccept)
                  ElevatedButton.icon(
                    onPressed: () => _acceptTicket(ticket),
                    icon: const Icon(Icons.inbox_rounded, size: 14),
                    label: const Text('Terima', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.roleHelpdesk,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (canStart)
                  ElevatedButton.icon(
                    onPressed: () => _startHandling(ticket),
                    icon: const Icon(Icons.play_arrow_rounded, size: 14),
                    label: const Text('Mulai Tangani', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusInProgress,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (canResolve)
                  ElevatedButton.icon(
                    onPressed: () => _resolveDialog(ticket),
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    label: const Text('Selesaikan', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusResolved,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _addComment(ticket),
                  icon: const Icon(Icons.comment_outlined, size: 14),
                  label: const Text('Komentar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/ticket-detail',
                      arguments: {'ticketId': ticket.id}),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('Detail', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
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
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: color)),
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
