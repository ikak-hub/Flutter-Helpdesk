enum TicketStatus { open, assigned, inProgress, resolved, closed }

TicketStatus ticketStatusFromString(String value) {
  switch (value) {
    case 'open':
      return TicketStatus.open;
    case 'assigned':
      return TicketStatus.assigned;
    case 'in_progress':
      return TicketStatus.inProgress;
    case 'resolved':
      return TicketStatus.resolved;
    case 'closed':
      return TicketStatus.closed;
    default:
      return TicketStatus.open;
  }
}

String ticketStatusToString(TicketStatus status) {
  switch (status) {
    case TicketStatus.open:
      return 'open';
    case TicketStatus.assigned:
      return 'assigned';
    case TicketStatus.inProgress:
      return 'in_progress';
    case TicketStatus.resolved:
      return 'resolved';
    case TicketStatus.closed:
      return 'closed';
  }
}

String ticketStatusLabel(TicketStatus status) {
  switch (status) {
    case TicketStatus.open:
      return 'Menunggu';
    case TicketStatus.assigned:
      return 'Ditugaskan';
    case TicketStatus.inProgress:
      return 'Sedang Dikerjakan';
    case TicketStatus.resolved:
      return 'Selesai';
    case TicketStatus.closed:
      return 'Ditutup';
  }
}

class TicketModel {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String category;
  final String priority; // low, medium, high
  final TicketStatus status;

  final String userId;
  final String userName;
  final String? assignedHelpdeskId;
  final String? assignedHelpdeskName;

  final String? resolutionNote;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.userId,
    required this.userName,
    this.assignedHelpdeskId,
    this.assignedHelpdeskName,
    this.resolutionNote,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    return TicketModel(
      id: map['id'] as String,
      ticketNumber: map['ticket_number'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      priority: map['priority'] as String? ?? 'medium',
      status: ticketStatusFromString(map['status'] as String? ?? 'open'),
      userId: map['user_id'] as String? ?? '',
      userName: (map['profiles'] is Map)
          ? (map['profiles']['name'] as String? ?? '-')
          : (map['user_name'] as String? ?? '-'),
      assignedHelpdeskId: map['assigned_helpdesk_id'] as String?,
      assignedHelpdeskName: (map['helpdesk_profile'] is Map)
          ? (map['helpdesk_profile']['name'] as String?)
          : map['assigned_helpdesk_name'] as String?,
      resolutionNote: map['resolution_note'] as String?,
      resolvedAt: map['resolved_at'] != null
          ? DateTime.tryParse(map['resolved_at'] as String)
          : null,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  String get priorityLabel {
    switch (priority) {
      case 'high':
        return 'High';
      case 'low':
        return 'Low';
      default:
        return 'Medium';
    }
  }
}

class TicketHistoryModel {
  final String id;
  final String ticketId;
  final String actorName;
  final String actorRole;
  final String action;
  final String? fromStatus;
  final String? toStatus;
  final String? note;
  final DateTime createdAt;

  const TicketHistoryModel({
    required this.id,
    required this.ticketId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    this.fromStatus,
    this.toStatus,
    this.note,
    required this.createdAt,
  });

  factory TicketHistoryModel.fromMap(Map<String, dynamic> map) {
    return TicketHistoryModel(
      id: map['id'] as String,
      ticketId: map['ticket_id'] as String,
      actorName: map['actor_name'] as String? ?? 'System',
      actorRole: map['actor_role'] as String? ?? '-',
      action: map['action'] as String? ?? '',
      fromStatus: map['from_status'] as String?,
      toStatus: map['to_status'] as String?,
      note: map['note'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}

class TicketCommentModel {
  final String id;
  final String ticketId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String message;
  final DateTime createdAt;

  const TicketCommentModel({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.message,
    required this.createdAt,
  });

  factory TicketCommentModel.fromMap(Map<String, dynamic> map) {
    return TicketCommentModel(
      id: map['id'] as String,
      ticketId: map['ticket_id'] as String,
      authorId: map['author_id'] as String,
      authorName: map['author_name'] as String? ?? '-',
      authorRole: map['author_role'] as String? ?? '-',
      message: map['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String? ticketId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.ticketId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      ticketId: map['ticket_id'] as String?,
      type: map['type'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
