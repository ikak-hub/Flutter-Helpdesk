import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/ticket_service.dart';
import '../models/ticket_model.dart';
import '../models/user_model.dart';

/// Halaman detail tiket universal untuk ketiga role (User/Helpdesk/Admin).
/// Kontrol status & assignment hanya tampil untuk Admin/Helpdesk (FR-006, FR-007).
class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _commentCtrl = TextEditingController();
  String? _ticketId;
  List<TicketCommentModel> _comments = [];
  bool _loadingComments = true;
  bool _sending = false;
  List<UserModel> _helpdeskStaff = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final id = args?['ticketId'] as String?;
    if (id != null && id != _ticketId) {
      _ticketId = id;
      _loadComments();
      TicketService().addListener(_refresh);
    }
    // Admin perlu daftar helpdesk aktif untuk menugaskan tiket (FR-007.4).
    final user = AuthService().currentUser;
    if (user != null && user.isAdmin && _helpdeskStaff.isEmpty) {
      _loadHelpdeskStaff();
    }
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

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadComments() async {
    if (_ticketId == null) return;
    setState(() => _loadingComments = true);
    final comments = await TicketService().fetchComments(_ticketId!);
    if (!mounted) return;
    setState(() {
      _comments = comments;
      _loadingComments = false;
    });
  }

  Future<void> _sendComment() async {
    if (_commentCtrl.text.trim().isEmpty || _ticketId == null) return;
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _sending = true);
    await TicketService().addComment(
      ticketId: _ticketId!,
      authorId: user.id,
      authorName: user.name,
      authorRole: user.roleLabel,
      message: _commentCtrl.text.trim(),
    );
    _commentCtrl.clear();
    await _loadComments();
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _updateStatus(TicketStatus status) async {
    if (_ticketId == null) return;
    await TicketService().updateStatus(_ticketId!, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status diubah ke ${ticketStatusLabel(status)}'),
          backgroundColor: AppColors.statusResolved,
        ),
      );
    }
  }

  Future<void> _assignToMe() async {
    final user = AuthService().currentUser;
    if (user == null || _ticketId == null) return;
    await TicketService().acceptTicket(_ticketId!, user.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tiket berhasil ditugaskan ke Anda'),
            backgroundColor: AppColors.statusResolved),
      );
    }
  }

  /// FR-007.4: Admin menugaskan tiket ke salah satu helpdesk aktif.
  void _showAssignDialog() {
    if (_ticketId == null) return;
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
              : SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _helpdeskStaff
                        .map((h) => RadioListTile<String>(
                              title: Text(h.name),
                              subtitle: Text(h.email,
                                  style: const TextStyle(fontSize: 11)),
                              value: h.id,
                              groupValue: selectedId,
                              onChanged: (v) => setS(() => selectedId = v),
                              activeColor: AppColors.primary,
                            ))
                        .toList(),
                  ),
                ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: selectedId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final error = await TicketService()
                          .assignToHelpdesk(_ticketId!, selectedId!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text(error ?? 'Tiket berhasil ditugaskan'),
                            backgroundColor: error == null
                                ? AppColors.statusResolved
                                : Colors.red,
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

  Future<void> _resolveDialog() async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusResolved),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );

    if (confirmed == true && _ticketId != null) {
      await TicketService().resolveTicket(
        _ticketId!,
        ctrl.text.isNotEmpty ? ctrl.text : 'Masalah telah diselesaikan.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tiket berhasil diselesaikan!'),
              backgroundColor: AppColors.statusResolved),
        );
      }
    }
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

  @override
  void dispose() {
    _commentCtrl.dispose();
    TicketService().removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    TicketModel? foundTicket;
    if (_ticketId != null) {
      for (final t in TicketService().tickets) {
        if (t.id == _ticketId) {
          foundTicket = t;
          break;
        }
      }
    }

    if (foundTicket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tiket')),
        body: const Center(child: Text('Tiket tidak ditemukan')),
      );
    }

    // Variabel final (immutable) agar Dart bisa mempertahankan promosi
    // non-null di dalam closure (onPressed, builder, dll) di bawah ini.
    final TicketModel ticket = foundTicket;

    final statusColor = _statusColor(ticket.status);
    final isStaff = user != null && (user.isAdmin || user.isHelpdesk);
    final isOpen = ticket.status == TicketStatus.open;
    // FR-006: helpdesk bisa menangani tiket open dengan assign ke diri sendiri.
    final canSelfAssign = user != null && user.isHelpdesk && isOpen;
    // FR-007.4: admin menugaskan tiket open ke salah satu helpdesk aktif.
    final canAdminAssign = user != null && user.isAdmin && isOpen;
    final canResolve = isStaff &&
        (ticket.status == TicketStatus.assigned ||
            ticket.status == TicketStatus.inProgress);
    // FR-006.6: Helpdesk (atau admin) menutup tiket yang sudah resolved.
    final canClose = isStaff && ticket.status == TicketStatus.resolved;

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.ticketNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline_rounded),
            tooltip: 'Tracking',
            onPressed: () => Navigator.pushNamed(context, '/ticket-tracking',
                arguments: {'ticketId': ticket.id}),
          ),
          if (isStaff)
            PopupMenuButton<TicketStatus>(
              onSelected: _updateStatus,
              itemBuilder: (_) => TicketStatus.values
                  .map((s) => PopupMenuItem(
                        value: s,
                        child: Text(ticketStatusLabel(s),
                            style: TextStyle(color: _statusColor(s))),
                      ))
                  .toList(),
              icon: const Icon(Icons.more_vert_rounded),
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ticket.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildBadge(
                                  ticketStatusLabel(ticket.status), statusColor),
                              _buildBadge(ticket.priorityLabel,
                                  _priorityColor(ticket.priority)),
                              _buildBadge(ticket.category, AppColors.statusClosed),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.person_outline_rounded,
                              'Diajukan oleh', ticket.userName),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                              Icons.calendar_today_outlined,
                              'Tanggal',
                              DateFormat('d MMM yyyy, HH:mm')
                                  .format(ticket.createdAt)),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.description_outlined,
                              'Deskripsi', ticket.description),
                          if (ticket.assignedHelpdeskName != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.support_agent_outlined,
                                'Ditangani oleh', ticket.assignedHelpdeskName!),
                          ],
                          if (ticket.resolutionNote != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.check_circle_outline,
                                'Catatan Penyelesaian', ticket.resolutionNote!),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (canSelfAssign || canAdminAssign || canResolve || canClose) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kontrol Tiket',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (canSelfAssign)
                                  ElevatedButton.icon(
                                    onPressed: _assignToMe,
                                    icon: const Icon(Icons.inbox_rounded,
                                        size: 14),
                                    label: const Text('Tangani Tiket Ini',
                                        style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.roleHelpdesk),
                                  ),
                                if (canAdminAssign)
                                  ElevatedButton.icon(
                                    onPressed: _showAssignDialog,
                                    icon: const Icon(
                                        Icons.person_add_alt_rounded,
                                        size: 14),
                                    label: const Text('Tugaskan ke Helpdesk',
                                        style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary),
                                  ),
                                if (ticket.status == TicketStatus.assigned)
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _updateStatus(TicketStatus.inProgress),
                                    icon: const Icon(Icons.play_arrow_rounded,
                                        size: 14),
                                    label: const Text('Mulai Kerjakan',
                                        style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.statusInProgress),
                                  ),
                                if (canResolve)
                                  ElevatedButton.icon(
                                    onPressed: _resolveDialog,
                                    icon: const Icon(
                                        Icons.check_circle_outline,
                                        size: 14),
                                    label: const Text('Selesaikan',
                                        style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.statusResolved),
                                  ),
                                // FR-006.6: tombol eksplisit menutup tiket,
                                // muncul setelah tiket berstatus resolved.
                                if (canClose)
                                  ElevatedButton.icon(
                                    onPressed: () => _updateStatus(
                                        TicketStatus.closed),
                                    icon: const Icon(Icons.lock_outline_rounded,
                                        size: 14),
                                    label: const Text('Tutup Tiket',
                                        style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.statusClosed),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Text('Komentar',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),

                  if (_loadingComments)
                    const Center(child: CircularProgressIndicator())
                  else if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Belum ada komentar.'),
                    )
                  else
                    ..._comments.map((c) => _buildComment(c, user)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

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
                        hintText: 'Tulis komentar...', isDense: true),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _sendComment,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded,
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
    return StampBadge(label: label, color: color);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryLight),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondaryLight)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildComment(TicketCommentModel comment, UserModel? currentUser) {
    final isStaff = comment.authorRole == 'Admin' || comment.authorRole == 'Helpdesk';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isStaff
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.accent.withOpacity(0.15),
            child: Icon(
              isStaff ? Icons.support_agent : Icons.person,
              size: 18,
              color: isStaff ? AppColors.primary : AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isStaff
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(comment.authorRole,
                          style: TextStyle(
                              fontSize: 10,
                              color:
                                  isStaff ? AppColors.primary : AppColors.accent,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isStaff
                        ? AppColors.primary.withOpacity(0.06)
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(comment.message,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ),
                const SizedBox(height: 4),
                Text(DateFormat('d MMM yyyy HH:mm').format(comment.createdAt),
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
