import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
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
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () {},
      ),
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
          icon: Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildNotificationList() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {},
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
          delegate: SliverChildListDelegate([
            _buildNotificationSection('Today'),
            _buildNotificationItem(
              title: 'Automatic Shift Lock',
              message: 'The Automatic Shift Lock shows up When the ignition is on',
              urgencyLevel: 'Medium',
              time: '2 min ago',
              icon: Icons.lock_outline,
              isUnread: true,
            ),
            _buildNotificationItem(
              title: 'Sport Mode Indicator',
              message: "Sport mode indicator lights up when the vehicle responds to a driver's input",
              urgencyLevel: 'Medium',
              time: '15 min ago',
              icon: Icons.speed,
              isUnread: true,
            ),
            _buildNotificationSection('Yesterday'),
            _buildNotificationItem(
              title: 'Battery Check Required',
              message: "You have battery problems, and your car isn't getting enough power. You need to operate manually",
              urgencyLevel: 'High',
              time: '1 day ago',
              icon: Icons.battery_alert,
              isUnread: false,
              urgencyColor: Colors.red,
            ),
            _buildNotificationItem(
              title: 'Oil Level Warning',
              message: "Your vehicle's oil level is below recommended levels. Please check and refill if necessary",
            urgencyLevel: 'Medium',
              time: '1 day ago',
              icon: Icons.opacity,
              isUnread: false,
            ),
            _buildNotificationSection('Earlier this week'),
            _buildNotificationItem(
              title: 'Tire Pressure Alert',
              message: 'Right front tire pressure is low. Recommended pressure is 32 PSI',
              urgencyLevel: 'Low',
              time: '3 days ago',
              icon: Icons.tire_repair,
              isUnread: false,
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required String urgencyLevel,
    required String time,
    required IconData icon,
    bool isUnread = false,
    Color? urgencyColor,
  }) {
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
          if (isUnread)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFE67E5E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
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
                        icon,
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
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            time,
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
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (urgencyColor ?? Color(0xFFE67E5E)).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 16,
                            color: urgencyColor ?? Color(0xFFE67E5E),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Urgency: $urgencyLevel',
                            style: TextStyle(
                              fontSize: 12,
                              color: urgencyColor ?? Color(0xFFE67E5E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Example usage of custom animated notification indicator
class AnimatedNotificationDot extends StatefulWidget {
  @override
  _AnimatedNotificationDotState createState() => _AnimatedNotificationDotState();
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
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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