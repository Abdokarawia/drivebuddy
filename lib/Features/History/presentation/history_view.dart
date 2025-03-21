import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All Time';
  final List<Map<String, dynamic>> _historyItems = [
    {
      'date': DateTime.now(),
      'title': 'Automatic shift lock',
      'subtitle': 'Regular system check completed',
      'time': '08:30 AM',
      'icon': Icons.lock_outline,
    },
    {
      'date': DateTime.now(),
      'title': 'Sport mode indicator',
      'subtitle': 'System response test completed',
      'time': '10:15 AM',
      'icon': Icons.speed,
    },
    {
      'date': DateTime.now().subtract(Duration(days: 1)),
      'title': 'Battery check',
      'subtitle': 'Power system diagnostics completed',
      'time': '03:45 PM',
      'icon': Icons.battery_charging_full,
    },
    {
      'date': DateTime.now().subtract(Duration(days: 1)),
      'title': 'Auto lock system',
      'subtitle': 'Security check completed',
      'time': '05:30 PM',
      'icon': Icons.security,
    },
  ];

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
    return date1.isAfter(startOfWeek) && date1.isBefore(endOfWeek);
  }

  bool _isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  bool _isSameYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF3EE),
      appBar: _buildAppBar(),
      body: _buildBody(),
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
    return CustomScrollView(
      slivers: [
        _buildDateFilter(),
        _buildHistoryList(),
      ],
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

    return groupedItems;
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
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
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
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
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
                color: Colors.grey[600],
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
    );
  }
}