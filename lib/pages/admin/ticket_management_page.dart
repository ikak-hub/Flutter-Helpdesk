import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../services/ticket_service.dart';
import '../../models/ticket_model.dart';
import '../../models/user_model.dart';

class AdminTicketManagementScreen extends StatefulWidget {
  const AdminTicketManagementScreen({super.key});

  @override
  State<AdminTicketManagementScreen> createState() =>
      _AdminTicketManagementScreenState();
}

class _AdminTicketManagementScreenState
    extends State<AdminTicketManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  List<UserModel> _helpdeskStaff = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    TicketService().addListener(_refresh);
    _loadHelpdeskStaff();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadHelpdeskStaff() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', 'helpdesk')
          .eq('is_active', true);
      if (!mounted) return;
      setState(() {
        _helpdeskStaff =
            (data as List).map((e) => UserModel.fromMap(e)).toList();
      });
    } catch (e) {
      debugPrint('loadHelpdeskStaff error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    TicketService().removeListener(_refresh);
    super.dispose();
  }

  List<TicketModel> _filtered(TicketStatus? status) {
    final all = TicketService().tickets;
    final list =
        status == null ? all : all.where((t) => t.status == status).toList();
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.ticketNumber.toLowerCase().contains(q) ||
            t.userName.toLowerCase().contains(q))
        .toList();
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

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  void _showAssignDialog(TicketModel ticket) {
    String? selectedId;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tugaskan ke Helpdesk',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: _helpdeskStaff.isEmpty
              ? const Text('Belum ada staff helpdesk aktif.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _helpdeskStaff
                      .map((h) => RadioListTile<String>(
                            title: Text(h.name),
                            subtitle: Text(h.email, style: const TextStyle(fontSize: 11)),
                            value: h.id,
                            groupValue: selectedId,
                            onChanged: (v) => setS(() => selectedId = v),
                            activeColor: AppColors.primary,
                          ))
                      .toList(),
                ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: selectedId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final error = await TicketService()
                          .assignToHelpdesk(ticket.id, selectedId!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error ??
                                'Tiket ${ticket.ticketNumber} berhasil ditugaskan'),
                            backgroundColor:
                                error == null ? AppColors.statusResolved : Colors.red,
                          ),
                        );
                      }
                    },
              child: const Text('Tugaskan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Tiket'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Menunggu'),
            Tab(text: 'Ditugaskan'),
            Tab(text: 'Proses'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Cari tiket atau nama user...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(null),
                _buildList(TicketStatus.open),
                _buildList(TicketStatus.assigned),
                _buildList(TicketStatus.inProgress),
                _buildList(TicketStatus.resolved),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, '/admin-dashboard');
          if (i == 2) Navigator.pushReplacementNamed(context, '/admin-users');
          if (i == 3) Navigator.pushNamed(context, '/notifications');
          if (i == 4) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }

  Widget _buildList(TicketStatus? status) {
    final list = _filtered(status);
    if (TicketService().isLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Tidak ada tiket',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => TicketService().loadTickets(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final ticket = list[i];
          final statusColor = _statusColor(ticket.status);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(ticket.ticketNumber,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryLight)),
                      const Spacer(),
                      StampBadge(
                          label: ticket.priorityLabel,
                          color: _priorityColor(ticket.priority)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(ticket.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(ticket.userName,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondaryLight)),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(DateFormat('d MMM yyyy').format(ticket.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                  if (ticket.assignedHelpdeskName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                          'Helpdesk: ${ticket.assignedHelpdeskName}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.roleHelpdesk,
                              fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      StampBadge(
                        label: ticketStatusLabel(ticket.status),
                        color: statusColor,
                        leading: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: statusColor, shape: BoxShape.circle),
                        ),
                      ),
                      const Spacer(),
                      if (ticket.status == TicketStatus.open)
                        OutlinedButton.icon(
                          onPressed: () => _showAssignDialog(ticket),
                          icon: const Icon(Icons.person_add_alt_rounded, size: 14),
                          label: const Text('Tugaskan', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/ticket-detail',
                            arguments: {'ticketId': ticket.id}),
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Detail'),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _confirmDelete(ticket),
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.red, size: 20),
                        tooltip: 'Hapus Tiket',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(TicketModel ticket) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tiket',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Tiket ${ticket.ticketNumber} "${ticket.title}" akan dihapus permanen beserta riwayat dan lampirannya. Lanjutkan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final error = await TicketService().deleteTicket(ticket.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ??
                        'Tiket ${ticket.ticketNumber} berhasil dihapus'),
                    backgroundColor: error == null
                        ? AppColors.statusResolved
                        : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
