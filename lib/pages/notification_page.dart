import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/ticket_model.dart';

/// SRS 5.10 Notification Screen — FR-008: Notifikasi.
/// Flow: 1) Menampilkan pemberitahuan status tiket 2) Navigasi ke halaman terkait.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService().addListener(_refresh);
    NotificationService().loadNotifications();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    NotificationService().removeListener(_refresh);
    super.dispose();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'ticket_created':
        return Icons.confirmation_num_outlined;
      case 'ticket_assigned':
        return Icons.assignment_ind_outlined;
      case 'ticket_status_changed':
        return Icons.sync_alt_rounded;
      case 'ticket_commented':
        return Icons.comment_outlined;
      case 'ticket_resolved':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'ticket_created':
        return AppColors.statusOpen;
      case 'ticket_assigned':
        return AppColors.roleHelpdesk;
      case 'ticket_status_changed':
        return AppColors.statusInProgress;
      case 'ticket_commented':
        return AppColors.accent;
      case 'ticket_resolved':
        return AppColors.statusResolved;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('d MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = NotificationService().notifications;
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () {
                if (user != null) {
                  NotificationService().markAllAsRead(user.id);
                }
              },
              child: const Text('Tandai semua dibaca',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => NotificationService().loadNotifications(),
        child: notifications.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('Belum ada notifikasi',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (_, i) {
                  final n = notifications[i];
                  final color = _colorFor(n.type);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: n.isRead
                        ? null
                        : color.withOpacity(0.06),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_iconFor(n.type), color: color, size: 22),
                      ),
                      title: Text(n.title,
                          style: TextStyle(
                              fontWeight: n.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              fontSize: 13.5)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(n.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(_timeAgo(n.createdAt),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondaryLight)),
                        ],
                      ),
                      trailing: !n.isRead
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle),
                            )
                          : null,
                      onTap: () async {
                        // Flow 1: tandai dibaca. Flow 2: navigasi ke halaman terkait.
                        await NotificationService().markAsRead(n.id);
                        if (n.ticketId != null && mounted) {
                          Navigator.pushNamed(
                            context,
                            '/ticket-detail',
                            arguments: {'ticketId': n.ticketId},
                          );
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
