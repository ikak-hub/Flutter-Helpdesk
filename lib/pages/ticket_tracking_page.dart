import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/ticket_service.dart';
import '../models/ticket_model.dart';

/// SRS 5.8 Tracking Tiket Screen — FR-011: Tracking Tiket.
/// Menampilkan status & histori penanganan tiket yang sedang aktif,
/// diambil dari tabel ticket_history (BR-005: History Service).
class TicketTrackingScreen extends StatefulWidget {
  const TicketTrackingScreen({super.key});

  @override
  State<TicketTrackingScreen> createState() => _TicketTrackingScreenState();
}

class _TicketTrackingScreenState extends State<TicketTrackingScreen> {
  List<TicketHistoryModel> _history = [];
  bool _loading = true;
  TicketModel? _ticket;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final ticketId = args?['ticketId'] as String?;
    if (ticketId != null && _ticket == null) {
      _load(ticketId);
    }
  }

  Future<void> _load(String ticketId) async {
    setState(() => _loading = true);
    TicketModel? ticket;
    for (final t in TicketService().tickets) {
      if (t.id == ticketId) {
        ticket = t;
        break;
      }
    }
    final history = await TicketService().fetchHistory(ticketId);
    if (!mounted) return;
    setState(() {
      _ticket = ticket;
      _history = history;
      _loading = false;
    });
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

  String _actionLabel(TicketHistoryModel h) {
    switch (h.action) {
      case 'created':
        return 'Tiket dibuat';
      case 'status_changed':
        return 'Status diubah${h.toStatus != null ? ' menjadi ${ticketStatusLabel(ticketStatusFromString(h.toStatus!))}' : ''}';
      case 'commented':
        return 'Komentar baru';
      case 'resolved':
        return 'Tiket diselesaikan';
      default:
        return h.action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = [
      TicketStatus.open,
      TicketStatus.assigned,
      TicketStatus.inProgress,
      TicketStatus.resolved,
    ];
    final currentIndex =
        _ticket != null ? stages.indexOf(_ticket!.status) : -1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_ticket != null
            ? 'Tracking ${_ticket!.ticketNumber}'
            : 'Tracking Tiket'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ticket == null
              ? const Center(child: Text('Tiket tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_ticket!.title,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _badge(
                                      ticketStatusLabel(_ticket!.status),
                                      _statusColor(_ticket!.status)),
                                  _badge(_ticket!.priorityLabel,
                                      AppColors.accent),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text('Progres Tiket',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: stages.asMap().entries.map((e) {
                              final i = e.key;
                              final stage = e.value;
                              final isDone = currentIndex >= i;
                              final isLast = i == stages.length - 1;
                              return Expanded(
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: isDone
                                                ? _statusColor(stage)
                                                : Colors.grey.shade300,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isDone
                                                ? Icons.check
                                                : Icons.circle,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          ticketStatusLabel(stage)
                                              .split(' ')
                                              .first,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: isDone
                                                ? _statusColor(stage)
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isLast)
                                      Expanded(
                                        child: Container(
                                          height: 2,
                                          margin: const EdgeInsets.only(
                                              bottom: 18),
                                          color: currentIndex > i
                                              ? _statusColor(stage)
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text('Riwayat Aktivitas',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 12),

                      if (_history.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Belum ada riwayat aktivitas.'),
                        )
                      else
                        ..._history.reversed.map((h) => _historyItem(h)),
                    ],
                  ),
                ),
    );
  }

  Widget _badge(String label, Color color) {
    return StampBadge(label: label, color: color);
  }

  Widget _historyItem(TicketHistoryModel h) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_actionLabel(h),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${h.actorName} · ${h.actorRole}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondaryLight)),
                Text(DateFormat('d MMM yyyy, HH:mm').format(h.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
