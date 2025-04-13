import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

// Firebase notification model
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String icon;
  final bool isRead;
  final String? urgencyLevel;
  final Color? urgencyColor;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.isRead,
    this.urgencyLevel,
    this.urgencyColor,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Determine icon based on type or specific field
    IconData getIconData() {
      switch (data['type'] ?? '') {
        case 'lock':
          return Icons.lock_outline;
        case 'battery':
          return Icons.battery_alert;
        case 'oil':
          return Icons.opacity;
        case 'tire':
          return Icons.tire_repair;
        case 'speed':
          return Icons.speed;
        case 'scan_result':
          return Icons.document_scanner;
        default:
          return Icons.notifications;
      }
    }

    // Determine urgency color
    Color? getUrgencyColor() {
      switch (data['urgencyLevel'] ?? '') {
        case 'high':
          return Colors.red;
        case 'medium':
          return Colors.orange;
        case 'low':
          return Colors.green;
        default:
          return null;
      }
    }

    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? 'Notification',
      message: data['body'] ?? data['message'] ?? 'No message content',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      icon: data['icon'] ?? getIconData().codePoint.toString(),
      isRead: data['read'] ?? false,
      urgencyLevel: data['urgencyLevel'],
      urgencyColor: getUrgencyColor(),
    );
  }

  IconData get iconData {
    // Convert string to IconData or use a default
    try {
      return IconData(int.parse(icon), fontFamily: 'MaterialIcons');
    } catch (e) {
      return Icons.notifications;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  NotificationService(this._userId);

  Stream<List<NotificationModel>> getNotifications() {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationModel.fromFirestore(doc))
                  .toList(),
        );
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> markAllAsRead() async {
    WriteBatch batch = _firestore.batch();

    QuerySnapshot querySnapshot =
        await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: _userId)
            .where('read', isEqualTo: false)
            .get();

    querySnapshot.docs.forEach((doc) {
      batch.update(doc.reference, {'read': true});
    });

    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  Future<void> createTestNotification({
    String? title,
    String? message,
    String? type,
    String? urgencyLevel,
  }) async {
    await _firestore.collection('notifications').add({
      'title': title ?? 'Test Notification',
      'body': message ?? 'This is a test notification body',
      'timestamp': Timestamp.now(),
      'userId': _userId,
      'read': false,
      'type': type ?? 'battery',
      'urgencyLevel': urgencyLevel,
    });
  }
}

class NotificationScreen extends StatefulWidget {
  final String userId;

  const NotificationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  late NotificationService _notificationService;
  late AnimationController _slideController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(widget.userId);
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    // Start animation when the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate a refresh delay
    await Future.delayed(Duration(milliseconds: 1500));

    setState(() {
      _isRefreshing = false;
    });
  }

  void _viewNotificationDetails(NotificationModel notification) {
    // Mark the notification as read
    _notificationService.markAsRead(notification.id);

    // Show enhanced detail dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(notification.iconData, color: Color(0xFFE67E5E)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.urgencyLevel != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:
                        notification.urgencyColor?.withOpacity(0.1) ??
                        Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Priority: ${notification.urgencyLevel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: notification.urgencyColor ?? Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Text(
                notification.message,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              SizedBox(height: 16),
              Text(
                'Received: ${DateFormat('MMM d, yyyy - h:mm a').format(notification.timestamp)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _notificationService.deleteNotification(notification.id);
                Navigator.pop(context);
              },
              child: Text('Delete', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close', style: TextStyle(color: Color(0xFFE67E5E))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF3EE),
      appBar: _buildAppBar(),
      body: _buildNotificationList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Color(0xFFE67E5E),

      title: Text(
        'Notifications',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon:
              _isRefreshing
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Icon(Icons.refresh, color: Colors.white),
          onPressed: _isRefreshing ? null : _refreshNotifications,
        ),
      ],
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      color: Color(0xFFE67E5E),
      onRefresh: _refreshNotifications,
      child: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          // Count unread notifications
          int unreadCount = notifications.where((n) => !n.isRead).length;

          return CustomScrollView(
            physics: BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Recent Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: EdgeInsets.only(left: 8),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFE67E5E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount new',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (unreadCount > 0)
                        TextButton(
                          onPressed: () {
                            _notificationService.markAllAsRead();
                          },
                          child: Text(
                            'Mark all as read',
                            style: TextStyle(
                              color: Color(0xFFE67E5E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final notification = notifications[index];
                  return AnimatedBuilder(
                    animation: _slideController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(1, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _slideController,
                            curve: Interval(
                              index / notifications.length,
                              (index + 1) / notifications.length,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: child,
                      );
                    },
                    child: Dismissible(
                      key: Key(notification.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.0),
                        color: Colors.red,
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Confirm"),
                              content: Text(
                                "Are you sure you want to delete this notification?",
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: Text("Delete"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        _notificationService.deleteNotification(
                          notification.id,
                        );
                      },
                      child: GestureDetector(
                        onTap: () => _viewNotificationDetails(notification),
                        child: _buildNotificationItem(notification),
                      ),
                    ),
                  );
                }, childCount: notifications.length),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder:
            (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We couldn\'t load your notifications',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE67E5E),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => setState(() {}),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Color(0xFFE67E5E).withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'When you receive notifications, they will appear here. You can try creating a test notification using the + button.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (!notification.isRead)
            Positioned(top: 12, right: 12, child: AnimatedNotificationDot()),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFF3EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        notification.iconData,
                        color: Color(0xFFE67E5E),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notification.urgencyLevel != null) SizedBox(height: 12),
                if (notification.urgencyLevel != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          notification.urgencyColor?.withOpacity(0.1) ??
                          Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notification.urgencyLevel!,
                      style: TextStyle(
                        fontSize: 12,
                        color: notification.urgencyColor ?? Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Animated notification dot widget
class AnimatedNotificationDot extends StatefulWidget {
  @override
  _AnimatedNotificationDotState createState() =>
      _AnimatedNotificationDotState();
}

class _AnimatedNotificationDotState extends State<AnimatedNotificationDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Color(0xFFE67E5E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
