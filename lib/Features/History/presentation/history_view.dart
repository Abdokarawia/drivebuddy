import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyItems = [];

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _historyItems = [];
        });
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('history')
          .where('userId', isEqualTo: user.uid)
      // Removed the isShow filter as requested
          .orderBy('timestamp', descending: true)
          .get();

      final items = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Handle deduplication based on title
      final Map<String, Map<String, dynamic>> deduplicated = {};

      for (var item in items) {
        final title = item['title'] ?? 'Unknown Issue';

        if (deduplicated.containsKey(title)) {
          // Increment count for duplicates
          deduplicated[title]!['count'] = (deduplicated[title]!['count'] ?? 1) + 1;

          // Keep the most recent timestamp
          final currentTimestamp = deduplicated[title]!['timestamp'] as Timestamp?;
          final newTimestamp = item['timestamp'] as Timestamp?;

          if (currentTimestamp != null && newTimestamp != null) {
            if (newTimestamp.compareTo(currentTimestamp) > 0) {
              deduplicated[title]!['timestamp'] = newTimestamp;
            }
          }

          // Store all document IDs for this issue
          if (!deduplicated[title]!.containsKey('relatedIds')) {
            // Explicitly create a String list
            deduplicated[title]!['relatedIds'] = <String>[deduplicated[title]!['id']];
          }
          // Explicitly add as String
          (deduplicated[title]!['relatedIds'] as List).add(item['id']);

        } else {
          // First occurrence of this title
          item['count'] = 1;
          deduplicated[title] = item;
        }
      }

      setState(() {
        _historyItems = deduplicated.values.toList();
        _historyItems.sort((a, b) {
          final aTimestamp = a['timestamp'] as Timestamp?;
          final bTimestamp = b['timestamp'] as Timestamp?;
          if (aTimestamp == null || bTimestamp == null) return 0;
          return bTimestamp.compareTo(aTimestamp); // Keep in descending order
        });
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching history data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteHistoryItem(String documentId, dynamic relatedIds) async {
    // Add debug logs to understand the data
    print('Document ID to delete: $documentId');
    print('Related IDs type: ${relatedIds?.runtimeType}');
    print('Related IDs content: $relatedIds');

    // Show confirmation dialog before deleting
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Issue'),
          content: const Text('Are you sure you want to remove this issue from your history?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) return;

    try {
      // Handle different types of relatedIds
      List<String> idsToDelete = [];

      if (relatedIds != null) {
        if (relatedIds is List) {
          for (var id in relatedIds) {
            idsToDelete.add(id.toString());
          }
        }
      }

      // If no related IDs were found or list is empty, just delete the current document
      if (idsToDelete.isEmpty) {
        idsToDelete.add(documentId);
      }

      print('Deleting ${idsToDelete.length} documents: $idsToDelete');

      // Use batch delete for all IDs
      final batch = FirebaseFirestore.instance.batch();
      for (final id in idsToDelete) {
        batch.delete(FirebaseFirestore.instance.collection('history').doc(id));
      }
      await batch.commit();

      // Refresh data after deletion
      _fetchHistoryData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Issue removed from history'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting issue: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting issue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showIssueDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 6,
                  margin: const EdgeInsets.only(top: 12, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 36),
                    Text(
                      'Issue Details - ${item['title'] ?? 'Unknown'}',
                      textAlign: TextAlign.center,
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
                      // Warning icon section
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

                      // Issue info card
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
                                  'Count: ${item['count'] ?? 1}',
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
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Status: Active Issue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description section
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

                      // Action button - Delete only
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close details modal first
                          _deleteHistoryItem(item['id'], item['relatedIds']);
                        },
                        icon: const Icon(Iconsax.trash),
                        label: const Text('Delete Issue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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

    Color badgeColor;
    String statusText;
    IconData statusIcon;

    if (count >= 3) {
      badgeColor = Colors.red;
      statusText = 'Critical';
      statusIcon = Iconsax.danger;
    } else {
      badgeColor = Colors.orange;
      statusText = 'Active';
      statusIcon = Iconsax.warning_2;
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
          'History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _fetchHistoryData,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historyItems.isEmpty
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
                    'No active issues found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Active issues detected during scan will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _fetchHistoryData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _historyItems.length,
                itemBuilder: (context, index) {
                  final item = _historyItems[index];
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
                                // Warning icon
                                Container(
                                  width: 60,
                                  height: 60,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.asset(
                                    item['imageAsset'] ?? 'assets/images/warning.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Issue info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['title'] ?? 'Unknown Issue',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          _buildStatusBadge(item),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Occurrence #${item['count'] ?? 1} • ${_formatTimestamp(item['timestamp'])}',
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
                          ),

                          // Action row - Only View Details
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                // View details button
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _showIssueDetails(item),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
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

                                // Delete button
                                Container(
                                  height: 24,
                                  width: 1,
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _deleteHistoryItem(item['id'], item['relatedIds']),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Iconsax.trash,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Delete',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.red,
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