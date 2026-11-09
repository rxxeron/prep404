class AppNotification {
  final String id;
  final String? userId;
  final String? campaignId;
  final String title;
  final String body;
  final String? imageUrl;
  final String eventType;
  final String actionType; // 'app_open', 'deep_link', 'web_link'
  final String? targetRoute;
  final String? externalUrl;
  final List<Map<String, dynamic>> actions;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    this.userId,
    this.campaignId,
    required this.title,
    required this.body,
    this.imageUrl,
    this.eventType = 'announcement',
    this.actionType = 'deep_link',
    this.targetRoute,
    this.externalUrl,
    this.actions = const [],
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final List<Map<String, dynamic>> parsedActions = [];
    if (json['actions'] is List) {
      for (final a in json['actions']) {
        if (a is Map<String, dynamic>) {
          parsedActions.add(a);
        }
      }
    }

    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString(),
      campaignId:
          json['campaignId']?.toString() ?? json['campaign_id']?.toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      eventType: json['eventType']?.toString() ??
          json['event_type']?.toString() ??
          'announcement',
      actionType: json['actionType']?.toString() ??
          json['action_type']?.toString() ??
          'deep_link',
      targetRoute:
          json['targetRoute']?.toString() ?? json['target_route']?.toString(),
      externalUrl:
          json['externalUrl']?.toString() ?? json['external_url']?.toString(),
      actions: parsedActions,
      isRead: json['isRead'] == true || json['is_read'] == true,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AppNotification copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      campaignId: campaignId,
      title: title,
      body: body,
      imageUrl: imageUrl,
      eventType: eventType,
      actionType: actionType,
      targetRoute: targetRoute,
      externalUrl: externalUrl,
      actions: actions,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
