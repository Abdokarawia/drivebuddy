import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notificationItems = [];

  @override
  void initState() {
    super.initState();
    _fetchNotificationData();
  }

  Future<void> _fetchNotificationData() async {
    setState(() {
      _isLoading = true;
      _notificationItems.clear();
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _notificationItems = [];
        });
        return;
      }

      Query query = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true);

      final querySnapshot = await query.get();

      final items = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Remove the filtering logic to show all notifications regardless of count
      setState(() {
        _notificationItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching notification data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotificationItem(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(documentId)
          .delete();
      _fetchNotificationData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification removed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showIssueDetails(Map<String, dynamic> item) {
    final count = item['count'] as int? ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                spreadRadius: 2,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 6,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 36),
                    Text(
                      'Issue Details - ${item['title'] ?? 'Unknown'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            item['imageAsset'] ?? 'assets/images/warning.png',
                            width: 60,
                            height: 60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.calendar,
                                  size: 20,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Detected on: ${_formatTimestamp(item['timestamp'])}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.chart,
                                  size: 20,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Confidence: ${item['confidence'] ?? 1}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.warning_2,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Status: Critical Issue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            // Keep the warning message for notifications with count >= 3
                            if (count >= 3)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Iconsax.danger,
                                      size: 16,
                                      color: Colors.red[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'This issue has been detected multiple times and requires immediate attention',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Iconsax.info_circle,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Issue Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item['description'] ?? 'No description available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _deleteNotificationItem(item['id']),
                        icon: const Icon(Iconsax.trash),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
    }
    return 'Unknown date';
  }

  Widget _buildStatusBadge(Map<String, dynamic> item) {
    final count = item['count'] as int? ?? 1;

    // Determine status based on count
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    if (count >= 3) {
      badgeColor = Colors.red;
      statusText = 'Critical';
      statusIcon = Iconsax.danger;
    } else if (count == 2) {
      badgeColor = Colors.orange;
      statusText = 'Warning';
      statusIcon = Iconsax.warning_2;
    } else {
      badgeColor = Colors.blue;
      statusText = 'Notice';
      statusIcon = Iconsax.info_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: badgeColor, size: 12),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _fetchNotificationData,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notificationItems.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Iconsax.clipboard_close,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifications will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _fetchNotificationData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notificationItems.length,
                itemBuilder: (context, index) {
                  final item = _notificationItems[index];
                  return GestureDetector(
                    onTap: () => _showIssueDetails(item),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: Image.asset(
                                    item['imageAsset'] ??
                                        'assets/images/warning.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['warningMessage'] ??
                                            'Unknown Issue',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                        maxLines: 3,
                                        overflow:
                                        TextOverflow.ellipsis,
                                      ),

                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _showIssueDetails(item),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Iconsax.document,
                                            size: 16,
                                            color: Colors.blue[700],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'View Details',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}