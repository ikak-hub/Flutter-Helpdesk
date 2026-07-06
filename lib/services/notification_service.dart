import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';

/// NotificationService mengimplementasikan FR-008 (Notifikasi) dan BR-003
/// (Notification Service) menggunakan Supabase Realtime sebagai sumber data
/// dan flutter_local_notifications untuk menampilkan notifikasi di device.
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  bool _initializedLocalNotif = false;

  /// Panggil sekali di main() sebelum runApp.
  Future<void> initLocalNotifications() async {
    if (_initializedLocalNotif) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localNotif.initialize(initSettings);
    _initializedLocalNotif = true;
  }

  Future<void> _showLocalNotification(NotificationModel n) async {
    const androidDetails = AndroidNotificationDetails(
      'helpdesk_channel',
      'HelpPoint',
      channelDescription: 'Notifikasi perubahan status & komentar tiket',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotif.show(
      n.createdAt.millisecondsSinceEpoch ~/ 1000 % 100000,
      n.title,
      n.body,
      details,
    );
  }

  /// Memuat notifikasi milik user yang sedang login (dibatasi RLS).
  Future<void> loadNotifications() async {
    try {
      final data = await _client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      _notifications = (data as List)
          .map((e) => NotificationModel.fromMap(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadNotifications error: $e');
    }
  }

  /// Subscribe Realtime: setiap notifikasi baru masuk untuk user ini,
  /// tampilkan local notification + refresh list (FR-008 flow 1 & 2).
  void subscribeRealtime(String userId) {
    _sub?.cancel();
    _sub = _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((rows) async {
      final fresh =
          rows.map((e) => NotificationModel.fromMap(e)).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Deteksi notifikasi baru yang belum pernah kita lihat untuk dipush.
      final existingIds = _notifications.map((n) => n.id).toSet();
      final newOnes =
          fresh.where((n) => !existingIds.contains(n.id)).toList();

      _notifications = fresh;
      notifyListeners();

      for (final n in newOnes) {
        await _showLocalNotification(n);
      }
    });
  }

  void unsubscribeRealtime() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        final old = _notifications[idx];
        _notifications[idx] = NotificationModel(
          id: old.id,
          userId: old.userId,
          ticketId: old.ticketId,
          type: old.type,
          title: old.title,
          body: old.body,
          isRead: true,
          createdAt: old.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      await loadNotifications();
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
    }
  }

  @override
  void dispose() {
    unsubscribeRealtime();
    super.dispose();
  }
}
