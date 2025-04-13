import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All Time';
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyItems = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _historyItems = [];
        });
        return;
      }

      final userId = currentUser.uid;
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('scanHistory')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> items = [];

      // Process each document
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        final date = timestamp?.toDate() ?? DateTime.now();

        // Get appropriate icon based on scan type
        IconData icon = Icons.search;
        final scanType = data['scanType'] as String? ?? '';

        if (scanType == 'dashboard') {
          icon = Icons.dashboard;
        } else if (scanType.contains('battery')) {
          icon = Icons.battery_charging_full;
        } else if (scanType.contains('lock')) {
          icon = Icons.lock_outline;
        } else if (scanType.contains('security')) {
          icon = Icons.security;
        }

        // Format time from timestamp
        final timeString = timestamp != null
            ? DateFormat('hh:mm a').format(date)
            : 'Unknown time';

        items.add({
          'date': date,
          'title': data['title'] ?? 'Scan Result',
          'subtitle': data['body'] ?? 'No details available',
          'time': timeString,
          'icon': icon,
          'read': data['read'] ?? false,
          'docId': doc.id,
        });
      }

      setState(() {
        _historyItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching history data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String docId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('scanHistory')
          .doc(docId)
          .update({'read': true});

      // Update local state
      setState(() {
        final index = _historyItems.indexWhere((item) => item['docId'] == docId);
        if (index != -1) {
          _historyItems[index]['read'] = true;
        }
      });
    } catch (e) {
      print('Error marking item as read: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredHistoryItems {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'This Week':
        return _historyItems.where((item) => _isSameWeek(item['date'], now)).toList();
      case 'This Month':
        return _historyItems.where((item) => _isSameMonth(item['date'], now)).toList();
      case 'This Year':
        return _historyItems.where((item) => _isSameYear(item['date'], now)).toList();
      default: // 'All Time'
        return _historyItems;
    }
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final startOfWeek = date2.subtract(Duration(days: date2.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    return date1.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
        date1.isBefore(endOfWeek.add(Duration(days: 1)));
  }

  bool _isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  bool _isSameYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year;
  }

  Future<void> _refreshHistory() async {
    await _fetchHistoryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF3EE),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      leading: Container(),
      backgroundColor: Color(0xFFE67E5E),
      title: Text(
        'All History',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_historyItems.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        _buildDateFilter(),
        _buildHistoryList(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE67E5E)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading history...',
            style: TextStyle(
              color: Color(0xFFE67E5E),
              fontSize: 16,
            ),
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
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No history found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your scan history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE67E5E),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Refresh',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: EdgeInsets.symmetric(vertical: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildDateChip('All Time', isSelected: _selectedFilter == 'All Time'),
            _buildDateChip('This Week', isSelected: _selectedFilter == 'This Week'),
            _buildDateChip('This Month', isSelected: _selectedFilter == 'This Month'),
            _buildDateChip('This Year', isSelected: _selectedFilter == 'This Year'),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, {bool isSelected = false}) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (bool selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        selectedColor: Color(0xFFE67E5E),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final groupedItems = _groupHistoryItemsByDate(_filteredHistoryItems);

    if (groupedItems.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          child: Center(
            child: Text(
              'No history items match your filter',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final date = groupedItems.keys.elementAt(index);
          final items = groupedItems[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHistoryGroup(DateFormat('MMMM d, y').format(date)),
              ...items.map((item) => _buildHistoryItem(
                title: item['title'],
                subtitle: item['subtitle'],
                time: item['time'],
                icon: item['icon'],
                isRead: item['read'] ?? false,
                docId: item['docId'],
              )),
            ],
          );
        },
        childCount: groupedItems.length,
      ),
    );
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupHistoryItemsByDate(List<Map<String, dynamic>> items) {
    final Map<DateTime, List<Map<String, dynamic>>> groupedItems = {};

    for (var item in items) {
      final date = DateTime(item['date'].year, item['date'].month, item['date'].day);
      if (!groupedItems.containsKey(date)) {
        groupedItems[date] = [];
      }
      groupedItems[date]!.add(item);
    }

    // Sort dates in descending order
    final sortedDates = groupedItems.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final sortedGroupedItems = Map.fromEntries(
      sortedDates.map((date) => MapEntry(date, groupedItems[date]!)),
    );

    return sortedGroupedItems;
  }

  Widget _buildHistoryGroup(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required bool isRead,
    required String docId,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _markAsRead(docId);
        }
        // TODO: Navigate to detailed view if needed
      },
      child: Container(
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
          border: !isRead
              ? Border.all(color: Color(0xFFE67E5E), width: 2)
              : null,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFFF3EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Color(0xFFE67E5E),
                  size: 24,
                ),
              ),
              if (!isRead)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(0xFFE67E5E),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: isRead ? Colors.grey[600] : Colors.black87,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}