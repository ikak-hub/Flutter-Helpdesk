import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _commentCtrl = TextEditingController();

  final List<Map<String, dynamic>> _comments = [
    {
      'user': 'Helpdesk Tim',
      'role': 'Helpdesk',
      'message': 'Tiket Anda telah diterima. Kami akan segera menindaklanjuti.',
      'time': '13 Apr 2026 09:00',
      'isHelpdesk': true,
    },
    {
      'user': 'John Doe',
      'role': 'User',
      'message': 'Masalah sudah berlangsung sejak kemarin pagi.',
      'time': '13 Apr 2026 09:15',
      'isHelpdesk': false,
    },
    {
      'user': 'Helpdesk Tim',
      'role': 'Helpdesk',
      'message': 'Kami sedang investigasi permasalahan jaringan di area tersebut.',
      'time': '13 Apr 2026 10:30',
      'isHelpdesk': true,
    },
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _sendComment() {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() {
      _comments.add({
        'user': 'John Doe',
        'role': 'User',
        'message': _commentCtrl.text.trim(),
        'time': '13 Apr 2026 Baru saja',
        'isHelpdesk': false,
      });
    });
    _commentCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = (ModalRoute.of(context)?.settings.arguments as Map?) ??
        {
          'id': '#TKT-001',
          'title': 'Koneksi internet tidak stabil di lab A',
          'status': 'Open',
          'date': '13 Apr 2026',
          'priority': 'High',
          'description': 'Koneksi internet di laboratorium A sering putus dan sangat mengganggu aktivitas perkuliahan.',
        };

    Color statusColor = _statusColor(ticket['status'] ?? 'Open');

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket['id'] ?? '#TKT-001'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ticket Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ticket['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildBadge(
                                ticket['status'] ?? 'Open',
                                statusColor,
                              ),
                              _buildBadge(
                                ticket['priority'] ?? 'High',
                                _priorityColor(ticket['priority'] ?? 'High'),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.calendar_today_outlined,
                              'Tanggal', ticket['date'] ?? '-'),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.person_outline_rounded,
                              'Diajukan oleh', 'John Doe'),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.support_agent_outlined,
                              'Ditangani oleh', 'Tim Helpdesk IT'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deskripsi',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ticket['description'] ?? '-',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Attachments
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lampiran',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildAttachmentChip('screenshot.png', Icons.image_outlined),
                              const SizedBox(width: 8),
                              _buildAttachmentChip('laporan.pdf', Icons.picture_as_pdf_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tracking Timeline
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tracking Status',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTimeline(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Comments
                  const Text(
                    'Komentar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._comments.map((c) => _buildComment(c)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Comment Input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Tulis komentar...',
                      isDense: true,
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendComment,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryLight),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentChip(String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final events = [
      {'label': 'Tiket Dibuat', 'date': '13 Apr 09:00', 'done': true},
      {'label': 'Tiket Diterima', 'date': '13 Apr 09:05', 'done': true},
      {'label': 'Sedang Diproses', 'date': '13 Apr 10:00', 'done': true},
      {'label': 'Selesai', 'date': '-', 'done': false},
    ];

    return Column(
      children: events.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        final isLast = i == events.length - 1;
        final done = e['done'] as bool;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: done ? AppColors.statusResolved : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    done ? Icons.check : Icons.circle,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: done
                        ? AppColors.statusResolved.withOpacity(0.3)
                        : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['label'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: done ? null : Colors.grey,
                      ),
                    ),
                    Text(
                      e['date'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildComment(Map<String, dynamic> comment) {
    final isHelpdesk = comment['isHelpdesk'] as bool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isHelpdesk
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.accent.withOpacity(0.15),
            child: Icon(
              isHelpdesk ? Icons.support_agent : Icons.person,
              size: 18,
              color: isHelpdesk ? AppColors.primary : AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['user'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isHelpdesk
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        comment['role'],
                        style: TextStyle(
                          fontSize: 10,
                          color: isHelpdesk ? AppColors.primary : AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHelpdesk
                        ? AppColors.primary.withOpacity(0.06)
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    comment['message'],
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment['time'],
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(Icons.edit_outlined, 'Edit Tiket', () {}),
            _buildOption(Icons.close_rounded, 'Tutup Tiket', () {}),
            _buildOption(
                Icons.delete_outline_rounded, 'Hapus Tiket', () {},
                color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
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

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
