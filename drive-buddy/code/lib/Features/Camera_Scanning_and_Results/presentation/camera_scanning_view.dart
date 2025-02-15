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
      'status': 'Checked',
      'statusColor': Colors.green,
    },
    {
      'date': DateTime.now(),
      'title': 'Sport mode indicator',
      'subtitle': 'System response test completed',
      'time': '10:15 AM',
      'icon': Icons.speed,
      'status': 'Warning',
      'statusColor': Colors.orange,
    },
    {
      'date': DateTime.now().subtract(Duration(days: 1)),
      'title': 'Battery check',
      'subtitle': 'Power system diagnostics completed',
      'time': '03:45 PM',
      'icon': Icons.battery_charging_full,
      'status': 'Critical',
      'statusColor': Colors.red,
    },
    {
      'date': DateTime.now().subtract(Duration(days: 1)),
      'title': 'Auto lock system',
      'subtitle': 'Security check completed',
      'time': '05:30 PM',
      'icon': Icons.security,
      'status': 'Checked',
      'statusColor': Colors.green,
    },
  ];

  List<Map<String, dynamic>> get _filteredHistoryItems {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return _historyItems.where((item) => _isSameDay(item['date'], now)).toList();
      case 'Yesterday':
        return _historyItems.where((item) => _isSameDay(item['date'], now.subtract(Duration(days: 1)))).toList();
      case 'This Week':
        return _historyItems.where((item) => _isSameWeek(item['date'], now)).toList();
      case 'This Month':
        return _historyItems.where((item) => _isSameMonth(item['date'], now)).toList();
      default:
        return _historyItems;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final startOfWeek = date2.subtract(Duration(days: date2.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    return date1.isAfter(startOfWeek) && date1.isBefore(endOfWeek);
  }

  bool _isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
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
      backgroundColor: Color(0xFFE67E5E),
      title: Text(
        'All History',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.filter_list, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.search, color: Colors.white),
          onPressed: () {},
        ),
      ],
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
            _buildDateChip('Today', isSelected: _selectedFilter == 'Today'),
            _buildDateChip('Yesterday', isSelected: _selectedFilter == 'Yesterday'),
            _buildDateChip('This Week', isSelected: _selectedFilter == 'This Week'),
            _buildDateChip('This Month', isSelected: _selectedFilter == 'This Month'),
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
                status: item['status'],
                statusColor: item['statusColor'],
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
    required String status,
    required Color statusColor,
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: () {},
      ),
    );
  }
}

class CustomTabIndicator extends Decoration {
  final double radius;
  final Color color;

  const CustomTabIndicator({
    this.radius = 8,
    this.color = const Color(0xFFE67E5E),
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomPainter(
      radius: radius,
      color: color,
    );
  }
}

class _CustomPainter extends BoxPainter {
  final double radius;
  final Color color;

  _CustomPainter({
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Rect rect = offset & configuration.size!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left,
          rect.bottom - radius,
          rect.width,
          radius,
        ),
        Radius.circular(radius),
      ),
      paint,
    );
  }
}