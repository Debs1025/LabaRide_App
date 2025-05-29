import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AcceptingOrder extends StatefulWidget {
  final Map<String, dynamic> orderDetails;
  final int userId;
  final String token;
  final Map<String, dynamic> shopData;

  const AcceptingOrder({
    super.key,
    required this.orderDetails,
    required this.userId,
    required this.token,
    required this.shopData,
  });

  @override
  State<AcceptingOrder> createState() => _AcceptingOrderState();
}

class _AcceptingOrderState extends State<AcceptingOrder> {
  final TextEditingController _priceController = TextEditingController();
  bool _isLoading = false;
  String _error = '';
  Map<String, double> _serviceFees = {};
  double? _minKilo;
  double? _maxKilo;
  double? _pricePerKilo;

  double get _totalServiceFee => 
    _serviceFees.values.fold(0.0, (sum, fee) => sum + fee);

  @override
  void initState() {
    super.initState();
    _fetchAllServiceFees();
    _fetchKiloRangeAndPrice();
    _priceController.addListener(() => setState(() {}));
  }

  Future<void> _fetchKiloRangeAndPrice() async {
    try {
      final shopId = widget.orderDetails['shop_id'];
      final kilo = widget.orderDetails['kilo_amount'];
      final response = await http.get(
        Uri.parse(
          'https://backend-production-5974.up.railway.app/api/shops/$shopId/kilo_price?kilo=$kilo',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _minKilo = double.tryParse(data['min_kilo'].toString());
          _maxKilo = double.tryParse(data['max_kilo'].toString());
          _pricePerKilo = double.tryParse(data['price_per_kilo'].toString());
          _priceController.text = _pricePerKilo?.toStringAsFixed(2) ?? '';
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _fetchAllServiceFees() async {
    try {
      final shopId = widget.orderDetails['shop_id'];
      List<String> services = _getServicesList();

      Map<String, double> fees = {};
      for (var service in services) {
        final encodedService = Uri.encodeComponent(service);
        final response = await http.get(
          Uri.parse(
            'https://backend-production-5974.up.railway.app/api/shops/$shopId/services/$encodedService',
          ),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          fees[service] = double.tryParse(data['price'].toString()) ?? 0.0;
        }
      }
      setState(() => _serviceFees = fees);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  List<String> _getServicesList() {
    List<String> services = [];
    if (widget.orderDetails['services'] != null) {
      if (widget.orderDetails['services'] is List) {
        services = List<String>.from(widget.orderDetails['services']);
      } else if (widget.orderDetails['services'] is String) {
        try {
          final decoded = jsonDecode(widget.orderDetails['services']);
          if (decoded is List) {
            services = List<String>.from(decoded);
          }
        } catch (_) {}
      }
    } else if (widget.orderDetails['service'] != null) {
      services = [widget.orderDetails['service'].toString()];
    }
    return services;
  }

  Future<void> _setOrderPrice(int orderId, String price) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('https://backend-production-5974.up.railway.app/api/orders/$orderId/set_price'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'price_per_kilo': price}),
      );

      if (response.statusCode == 200) {
        double total = (double.tryParse(price) ?? 0) + _totalServiceFee;
        await _updateTotalAmount(orderId, total);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Price set successfully!')),
          );
          Navigator.pop(context, 'accepted');
        }
      } else {
        throw Exception('Failed to set price');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateTotalAmount(int orderId, double totalAmount) async {
    try {
      final response = await http.put(
        Uri.parse('https://backend-production-5974.up.railway.app/api/orders/$orderId/update_total'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'total_amount': totalAmount}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update total');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating total: $e')),
        );
      }
    }
  }

  Future<void> _declineOrder() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse(
          'https://backend-production-5974.up.railway.app/api/orders/${widget.orderDetails['id']}/decline',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order declined successfully!')),
          );
          Navigator.pop(context, 'declined');
        }
      } else {
        throw Exception('Failed to decline order');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $_error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getServiceColor(String service) {
    switch (service.toUpperCase()) {
      case 'WASH ONLY':
        return const Color(0xFF98D8BF);
      case 'DRY CLEAN':
        return const Color(0xFF64B5F6);
      case 'STEAM PRESS':
        return const Color(0xFFBA68C8);
      case 'FULL SERVICE':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFF98D8BF);
    }
  }

  Widget _buildOrderItem(String quantity, String item, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            quantity,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9747FF),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            price,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF1A0066) : Colors.grey[600],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF9747FF) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> services = _getServicesList();
    final items = widget.orderDetails['items'] ?? [];
    final clothesList = (items as List).where((item) => item['category'] == 'clothes').toList();
    final householdList = items.where((item) => item['category'] == 'household').toList();

    double kiloAmount = double.tryParse(widget.orderDetails['kilo_amount'].toString()) ?? 0.0;
    double setPriceForKilo = double.tryParse(_priceController.text.isNotEmpty ? _priceController.text : '0') ?? 0.0;
    double total = setPriceForKilo + _totalServiceFee;

    return Scaffold(
      backgroundColor: const Color(0xFF48006A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                      Text(
                        widget.orderDetails['orderId']?.toString() ?? '#0123456891',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _declineOrder,
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Order details card
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A0066),
                            ),
                          ),
                          Text(
                            widget.orderDetails['orderId']?.toString() ?? '#0123456891',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF9747FF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Service type container
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: services.isNotEmpty 
                                ? _getServiceColor(services.first)
                                : _getServiceColor('WASH ONLY'),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                services.isNotEmpty
                                    ? services.join(', ').toUpperCase()
                                    : 'WASH ONLY',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Items sections
                          if (clothesList.isNotEmpty) ...[
                            const Text(
                              'Types of clothes:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A0066),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...clothesList.map(
                              (item) => _buildOrderItem(
                                '${item['quantity']}x',
                                item['name'].toString(),
                                '₱${item['price']}',
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (householdList.isNotEmpty) ...[
                            const Text(
                              'Household items:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A0066),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...householdList.map(
                              (item) => _buildOrderItem(
                                '${item['quantity']}x',
                                item['name'].toString(),
                                '₱${item['price']}',
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Price section
                          _buildPriceRow(
                            'Kilo',
                            '${kiloAmount.toStringAsFixed(2)} kg',
                          ),
                          if (_serviceFees.isNotEmpty)
                            ..._serviceFees.entries.map(
                              (entry) => _buildPriceRow(
                                '${entry.key} Fee',
                                '₱${entry.value.toStringAsFixed(2)}',
                              ),
                            ),
                          _buildPriceRow(
                            'Service Fee',
                            '₱${_totalServiceFee.toStringAsFixed(2)}',
                          ),
                          _buildPriceRow(
                            _minKilo != null && _maxKilo != null && _pricePerKilo != null
                                ? '${kiloAmount.toStringAsFixed(0)} kilo${kiloAmount > 1 ? "s" : ""} '
                                    '(${_minKilo!.toStringAsFixed(0)} - ${_maxKilo!.toStringAsFixed(0)}kg price: ${_pricePerKilo!.toStringAsFixed(0)})'
                                : '${kiloAmount.toStringAsFixed(0)} kilo${kiloAmount > 1 ? "s" : ""}',
                            setPriceForKilo.toStringAsFixed(2),
                          ),
                          const Divider(height: 24),
                          _buildPriceRow(
                            'Total',
                            '₱${total.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                          const SizedBox(height: 16),
                          // Price setting section
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.purple.shade100),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Set Price for ${kiloAmount.toStringAsFixed(0)} Kilo: ',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: TextField(
                                          controller: _priceController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            hintText: '₱0.00',
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Accept button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _setOrderPrice(
                                        widget.orderDetails['id'],
                                        _priceController.text,
                                      ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Accept',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
}