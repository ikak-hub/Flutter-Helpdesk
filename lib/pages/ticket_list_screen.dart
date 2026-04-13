import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

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

  final List<Map<String, dynamic>> _allTickets = [
    {
      'id': '#TKT-001',
      'title': 'Koneksi internet tidak stabil di lab A',
      'status': 'Open',
      'date': '13 Apr 2026',
      'priority': 'High',
      'description': 'Koneksi internet di laboratorium A sering putus.',
    },
    {
      'id': '#TKT-002',
      'title': 'Printer tidak bisa digunakan di lantai 2',
      'status': 'In Progress',
      'date': '12 Apr 2026',
      'priority': 'Medium',
      'description': 'Printer lantai 2 tidak terdeteksi oleh komputer.',
    },
    {
      'id': '#TKT-003',
      'title': 'Akses sistem akademik error',
      'status': 'Resolved',
      'date': '10 Apr 2026',
      'priority': 'High',
      'description': 'Tidak bisa login ke portal akademik.',
    },
    {
      'id': '#TKT-004',
      'title': 'Proyektor ruang rapat mati',
      'status': 'Open',
      'date': '9 Apr 2026',
      'priority': 'Low',
      'description': 'Proyektor di ruang rapat tidak menyala.',
    },
    {
      'id': '#TKT-005',
      'title': 'Email kampus tidak bisa diakses',
      'status': 'Closed',
      'date': '8 Apr 2026',
      'priority': 'High',
      'description': 'Tidak bisa masuk ke email @student.unair.ac.id',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(String status) {
    final list = status == 'All'
        ? _allTickets
        : _allTickets.where((t) => t['status'] == status).toList();
    if (_searchQuery.isEmpty) return list;
    return list
        .where((t) =>
            t['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t['id'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return AppColors.statusOpen;
      case 'In Progress':
        return AppColors.statusInProgress;
      case 'Resolved':
        return AppColors.statusResolved;
      default:
        return AppColors.statusClosed;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Open'),
            Tab(text: 'Progress'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
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

          // Tabs Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList('All'),
                _buildList('Open'),
                _buildList('In Progress'),
                _buildList('Resolved'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, '/dashboard');
          if (i == 2) Navigator.pushReplacementNamed(context, '/profile');
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () => Navigator.pushNamed(context, '/create-ticket'),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildList(String status) {
    final list = _filtered(status);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada tiket',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final ticket = list[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/ticket-detail',
                arguments: ticket),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ticket['id'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const Spacer(),
                      // Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _priorityColor(ticket['priority'])
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ticket['priority'],
                          style: TextStyle(
                            color: _priorityColor(ticket['priority']),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ticket['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(ticket['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _statusColor(ticket['status']),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ticket['status'],
                              style: TextStyle(
                                color: _statusColor(ticket['status']),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        ticket['date'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
