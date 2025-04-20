import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All Time';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Full _getRecommendation function from previous context
  String _getRecommendation(String detectedClass) {
    final recommendations = {
      'check engine': [
        'Visit a mechanic to diagnose the engine issue. This could indicate problems with emissions, fuel system, or engine performance.',
        'Run an OBD-II scan to identify specific error codes and consult a professional for repairs.',
        'Check for loose or damaged gas cap, as it can trigger this light. Tighten or replace if necessary.',
      ],
      'oil pressure': [
        'Stop driving immediately and check oil levels. Low oil pressure can cause severe engine damage if ignored.',
        'Inspect for oil leaks under the vehicle and have a mechanic address any issues found.',
        'Ensure the oil pump is functioning correctly; a faulty pump may require replacement.',
      ],
      'battery warning': [
        'Check battery connections and have the charging system tested. Your battery or alternator may need replacement.',
        'Clean battery terminals to ensure a good connection and test the battery’s charge.',
        'Inspect the alternator belt for wear or looseness, as it could affect charging.',
      ],
      'abs warning': [
        'Have your Anti-lock Braking System inspected. This affects your vehicle\'s ability to brake safely, especially in emergency situations.',
        'Check wheel speed sensors for dirt or damage, as they can trigger ABS issues.',
        'Ensure ABS module and pump are functioning; a professional diagnostic is recommended.',
      ],
      'brake system': [
        'Check brake fluid levels and have your brake system inspected immediately. Do not drive if brakes feel unresponsive.',
        'Inspect brake pads and rotors for wear; replace if they are below recommended thickness.',
        'Look for leaks in the brake lines or master cylinder, and have them repaired promptly.',
      ],
      'airbag warning': [
        'Have your airbag system diagnosed. In an accident, airbags may not deploy properly with this warning active.',
        'Check the airbag system’s fuse and connections for issues; replace or repair as needed.',
        'Ensure the supplemental restraint system (SRS) module is functioning; professional repair may be required.',
      ],
      'temperature warning': [
        'Safely pull over and let your engine cool down. Check coolant levels when safe. Continuing to drive may cause engine damage.',
        'Inspect the radiator for blockages or damage and clear any debris.',
        'Check the thermostat and water pump; a failure in either can cause overheating.',
      ],
      'tire pressure': [
        'Check all tire pressures and inflate to the recommended levels. Inspect tires for damage or punctures.',
        'Rotate tires if uneven wear is detected and check alignment to prevent future issues.',
        'Consider replacing tires if tread depth is low or damage is irreparable.',
      ],
      'traction control': [
        'Have the traction control system inspected, as it may affect vehicle stability in slippery conditions.',
        'Check wheel speed sensors, as they are often linked to traction control issues.',
        'Ensure the traction control module is functioning; a diagnostic scan is recommended.',
      ],
      'fuel system': [
        'Inspect the fuel pump and filter; a clogged filter or failing pump may need replacement.',
        'Check for contaminated fuel; drain and replace if necessary.',
        'Have a mechanic diagnose fuel injectors, as issues here can trigger warnings.',
      ],
    };

    String key = detectedClass.toLowerCase();
    if (recommendations.containsKey(key)) {
      final random = Random();
      final recommendationList = recommendations[key]!;
      return recommendationList[random.nextInt(recommendationList.length)];
    }
    return 'Have a professional mechanic inspect this warning light to determine the exact issue and recommended repairs.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to scan screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Start a new scan')),
          );
        },
        backgroundColor: const Color(0xFFE67E5E),
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFE67E5E),
      title: const Text(
        'Scan History',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final user = _auth.currentUser;
    if (user == null) {
      return _buildEmptyState(message: 'Please sign in to view history.');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('scanHistory')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildEmptyState(message: 'Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final items = _processHistoryItems(snapshot.data!.docs);
        final filteredItems = _filterHistoryItems(items);

        return CustomScrollView(
          slivers: [
            _buildSearchBar(),
            _buildDateFilter(),
            if (filteredItems.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(
                    message: 'No history items match your filter.'),
              )
            else
              _buildHistoryList(filteredItems),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _processHistoryItems(
      List<QueryDocumentSnapshot> docs) {
    final items = <Map<String, dynamic>>[];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;
      final date = timestamp?.toDate() ?? DateTime.now();
      final scanType = data['scanType'] as String? ?? '';
      final detections = (data['data'] as Map<String, dynamic>?)?['detections']
      as List<dynamic>? ??
          [];

      IconData icon = Icons.search;
      if (scanType == 'dashboard') {
        icon = Icons.dashboard;
      } else if (scanType.contains('battery')) {
        icon = Icons.battery_charging_full;
      } else if (scanType.contains('lock')) {
        icon = Icons.lock_outline;
      } else if (scanType.contains('security')) {
        icon = Icons.security;
      }

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
        'detections': detections,
      });
    }
    return items;
  }

  List<Map<String, dynamic>> _filterHistoryItems(
      List<Map<String, dynamic>> items) {
    final now = DateTime.now();
    var filtered = items;

    switch (_selectedFilter) {
      case 'This Week':
        filtered = filtered.where((item) => _isSameWeek(item['date'], now)).toList();
        break;
      case 'This Month':
        filtered = filtered.where((item) => _isSameMonth(item['date'], now)).toList();
        break;
      case 'This Year':
        filtered = filtered.where((item) => _isSameYear(item['date'], now)).toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final title = item['title'].toString().toLowerCase();
        final subtitle = item['subtitle'].toString().toLowerCase();
        return title.contains(_searchQuery) || subtitle.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE67E5E)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading history...',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 100,
            color: Colors.grey[400],
          ).animate().fadeIn(duration: 500.ms).scale(),
          const SizedBox(height: 16),
          Text(
            message ?? 'No scan history found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your scan history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E5E),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
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

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search history...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildDateChip('All Time', Icons.history,
                isSelected: _selectedFilter == 'All Time'),
            _buildDateChip('This Week', Icons.calendar_today,
                isSelected: _selectedFilter == 'This Week'),
            _buildDateChip('This Month', Icons.calendar_month,
                isSelected: _selectedFilter == 'This Month'),
            _buildDateChip('This Year', Icons.date_range,
                isSelected: _selectedFilter == 'This Year'),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, IconData icon, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black87),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (bool selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        selectedColor: const Color(0xFFE67E5E),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: isSelected ? 2 : 0,
      ),
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> items) {
    final groupedItems = _groupHistoryItemsByDate(items);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final date = groupedItems.keys.elementAt(index);
          final items = groupedItems[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHistoryGroup(DateFormat('MMMM d, y').format(date)),
              ...items.map((item) => _buildHistoryItem(item)),
            ],
          );
        },
        childCount: groupedItems.length,
      ),
    );
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupHistoryItemsByDate(
      List<Map<String, dynamic>> items) {
    final Map<DateTime, List<Map<String, dynamic>>> groupedItems = {};

    for (var item in items) {
      final date = DateTime(item['date'].year, item['date'].month, item['date'].day);
      if (!groupedItems.containsKey(date)) {
        groupedItems[date] = [];
      }
      groupedItems[date]!.add(item);
    }

    final sortedDates = groupedItems.keys.toList()..sort((a, b) => b.compareTo(a));
    return Map.fromEntries(
      sortedDates.map((date) => MapEntry(date, groupedItems[date]!)),
    );
  }

  Widget _buildHistoryGroup(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final isRead = item['read'] as bool;
    final docId = item['docId'] as String;

    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          await _markAsRead(docId);
        }
        _showDetailDialog(item);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: !isRead
              ? Border.all(color: const Color(0xFFE67E5E), width: 2)
              : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: const Color(0xFFE67E5E),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFE67E5E),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            item['title'],
            style: TextStyle(
              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[900],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                item['subtitle'],
                style: TextStyle(
                  color: isRead ? Colors.grey[600] : Colors.black87,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item['time'],
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Future<void> _markAsRead(String docId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('scanHistory')
          .doc(docId)
          .update({'read': true});
    } catch (e) {
      print('Error marking item as read: $e');
    }
  }

  void _showDetailDialog(Map<String, dynamic> item) {
    final detections = item['detections'] as List<dynamic>;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          item['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['subtitle'],
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              const Text(
                'Detected Issues:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (detections.isEmpty)
                const Text('No issues detected in this scan.')
              else
                ...detections.map((detection) {
                  final detectedClass =
                      detection['predicted_class'] as String? ?? 'Unknown';
                  final confidence =
                      detection['confidence'] as double? ?? 0.0;
                  final recommendation = _getRecommendation(detectedClass);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detectedClass,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Recommendation: $recommendation',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFE67E5E)),
            ),
          ),
        ],
      ),
    );
  }
}