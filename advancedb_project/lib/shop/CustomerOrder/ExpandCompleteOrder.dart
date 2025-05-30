import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../OrderScreen/OrderScreen.dart';
import '../ProfileShop/ShopProfile.dart';
import '../ShopDashboard/homescreen.dart';
import '../Services/ServiceScreen1.dart';
import 'CustomerOrder.dart';
import 'CompleteDetails.dart';

class ExpandCompleteOrder extends StatefulWidget {
  final int userId;
  final String token;
  final Map<String, dynamic> shopData;

  const ExpandCompleteOrder({
    super.key,
    required this.userId,
    required this.token,
    required this.shopData,
  });

  @override
  State<ExpandCompleteOrder> createState() => _ExpandCompleteOrderState();
}

class _ExpandCompleteOrderState extends State<ExpandCompleteOrder> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _error = '';
  List<Map<String, dynamic>> _completedOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchCompletedOrders();
    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOrders = _completedOrders.where((order) {
        final orderId = order['id']?.toString().toLowerCase() ?? '';
        final userName = order['user_name']?.toString().toLowerCase() ?? '';
        final service = order['service_name']?.toString().toLowerCase() ?? '';
        final address = order['address']?.toString().toLowerCase() ?? '';
        return orderId.contains(query) || 
               userName.contains(query) || 
               service.contains(query) ||
               address.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchCompletedOrders() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/shop_transactions/${widget.shopData['id']}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allOrders = List<Map<String, dynamic>>.from(data['data'] ?? []);
        
        setState(() {
          _completedOrders = allOrders.where((order) => 
            order['status']?.toString().toLowerCase() == 'completed'
          ).toList();
          _filteredOrders = List.from(_completedOrders);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load completed orders');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} mins ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return dateTime;
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerOrders(
                  userId: widget.userId,
                  token: widget.token,
                  shopData: widget.shopData,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Customer Orders',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Completed Orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompleteDetails(
              orderDetails: Map<String, String>.from(order.map(
                (key, value) => MapEntry(key, value?.toString() ?? ''))),
              userId: widget.userId,
              token: widget.token,
              shopData: widget.shopData,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order['id'] ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo[900],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Complete',
                      style: TextStyle(
                        color: Colors.green[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildOrderField('Customer', order['user_name'] ?? 'Unknown'),
              _buildOrderField('Service', order['service_name'] ?? 'Unknown'),
              _buildOrderField('Amount', '₱${order['total_amount'] ?? '0.00'}'),
              _buildOrderField('Address', order['address'] ?? 'No address'),
              _buildOrderField('Date', _formatDate(order['created_at'])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF48006A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchCompletedOrders,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchCompletedOrders,
                        child: _filteredOrders.isEmpty
                          ? ListView(
                              children: const [
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 32.0),
                                    child: Text(
                                      'No Transaction Record',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              itemCount: _filteredOrders.length,
                              itemBuilder: (context, index) => 
                                _buildOrderCard(_filteredOrders[index]),
                            ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 3,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF1A0066),
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  userId: widget.userId,
                  token: widget.token,
                  shopData: widget.shopData,
                ),
              ),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionsScreen(
                  userId: widget.userId,
                  token: widget.token,
                  shopData: widget.shopData,
                ),
              ),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceScreen1(
                  userId: widget.userId,
                  token: widget.token,
                  shopData: widget.shopData,
                ),
              ),
            );
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreenAdmin(
                  userId: widget.userId,
                  token: widget.token,
                  shopData: widget.shopData,
                  onSwitchToUser: () => Navigator.pop(context),
                ),
              ),
            );
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/ProfileScreen/Home.png')),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/ProfileScreen/Orders.png')),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/ProfileScreen/Services.png')),
          label: 'Services',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(
            AssetImage('assets/ProfileScreen/Customers.png'),
            color: Color(0xFF1A0066),
          ),
          label: 'Customers',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/ProfileScreen/Profile.png')),
          label: 'Profile',
        ),
      ],
    );
  }
}