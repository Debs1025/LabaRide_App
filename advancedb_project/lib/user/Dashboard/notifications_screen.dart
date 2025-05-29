import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsScreen extends StatefulWidget {
  final int userId;
  final String token;
  const NotificationsScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      final response = await http.get(
        Uri.parse('https://backend-production-5974.up.railway.app/api/notifications/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          notifications = jsonDecode(response.body)['notifications'];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load notifications';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Add action handling functionality
  Future<void> _handleAction(dynamic notification, String action) async {
    try {
      final response = await http.post(
        Uri.parse('https://backend-production-5974.up.railway.app/api/notifications/$action/${notification['id']}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${action[0].toUpperCase()}${action.substring(1)}ed!')),
          );
          await fetchNotifications();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to $action: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildNotificationItem({
    required String name,
    required String message,
    required String time,
    required dynamic notification,
    bool isUnread = false,
  }) {
    final status = notification['status']?.toString() ?? '';
    final isActionable = status != 'accepted' && status != 'cancelled';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Icon
          Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF1E54AB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          // Notification Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF4D3E8C),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                // Add action buttons
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: isActionable ? () => _handleAction(notification, 'accept') : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Accept'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isActionable ? () => _handleAction(notification, 'decline') : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Decline'),
                    ),
                    if (!isActionable)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Text(
                          status == 'accepted' ? 'Order accepted' : 
                          status == 'cancelled' ? 'Order declined' : '',
                          style: TextStyle(
                            color: status == 'accepted' ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isUnread)
            Container(
              height: 20,
              width: 20,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Update ListView.builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... existing header code ...
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error.isNotEmpty
                      ? Center(child: Text(error))
                      : notifications.isEmpty
                          ? const Center(child: Text('No notifications found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final n = notifications[index];
                                return _buildNotificationItem(
                                  name: n['from_name'] ?? 'Shop',
                                  message: n['message'] ?? '',
                                  time: _formatTime(n['created_at']),
                                  notification: n,
                                  isUnread: n['is_read'] == 0,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '';
    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateTime;
    }
  }
}