import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../services/auth_service.dart';
import '../services/ticket_service.dart';
import '../models/ticket_model.dart';
import 'create_ticket_page.dart';

/// SRS 5.6 List Tiket Screen — menampilkan daftar tiket sesuai role:
/// User melihat tiketnya sendiri, Helpdesk melihat open+assigned ke dia,
/// Admin melihat semua (filter dilakukan di TicketService berdasarkan RLS).
class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    TicketService().addListener(_onStoreChange);
  }

  void _onStoreChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    TicketService().removeListener(_onStoreChange);
    super.dispose();
  }

  List<TicketModel> _baseList() {
    final user = AuthService().currentUser;
    if (user == null) return [];
    if (user.isUser) return TicketService().ticketsForUser(user.id);
    if (user.isHelpdesk) return TicketService().ticketsForHelpdesk(user.id);
    return TicketService().tickets; // admin: semua (sudah dibatasi RLS)
  }

  List<TicketModel> _filtered(TicketStatus? status) {
    final base = _baseList();
    final list =
        status == null ? base : base.where((t) => t.status == status).toList();

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

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isUserRole = user?.isUser ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
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
                hintText: 'Cari tiket...',
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
      bottomNavigationBar: isUserRole
          ? AppBottomNav(
              currentIndex: 1,
              onTap: (i) {
                if (i == 0) {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                }
                if (i == 2) {
                  Navigator.pushNamed(context, '/notifications');
                }
                if (i == 3) {
                  Navigator.pushReplacementNamed(context, '/profile');
                }
              },
            )
          : null,
      floatingActionButton: isUserRole
          ? FloatingActionButton(
              backgroundColor: AppColors.accent,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final ticket = list[i];
          final statusColor = _statusColor(ticket.status);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/ticket-detail',
                  arguments: {'ticketId': ticket.id}),
              borderRadius: BorderRadius.circular(16),
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
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondaryLight)),
                        const Spacer(),
                        StampBadge(
                            label: ticket.priorityLabel,
                            color: _priorityColor(ticket.priority)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(ticket.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(ticket.category,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondaryLight)),
                    if (AuthService().currentUser?.isUser == false)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Oleh: ${ticket.userName}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondaryLight)),
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
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(DateFormat('d MMM yyyy').format(ticket.createdAt),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
