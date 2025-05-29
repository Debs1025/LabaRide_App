import 'package:flutter/material.dart';

class DetailTransact extends StatelessWidget {
  final Map<String, dynamic> orderDetails;

  const DetailTransact({
    super.key,
    required this.orderDetails,
  });

  String _formatDateTime(String dateTime) {
    try {
      final DateTime dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error formatting date: $e');
      return dateTime;
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Processing';
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Order has been delivered';
      case 'processing':
        return 'Order is being processed';
      case 'cancelled':
        return 'Order was cancelled';
      default:
        return status;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.black : Colors.grey[600],
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDiscount ? Colors.green : (isTotal ? Colors.black : Colors.grey[600]),
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1A0066)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Transaction Details',
        style: TextStyle(
          color: Color(0xFF1A0066),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Section
          Container(
            color: const Color(0xFF1A0066),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Text(
              orderDetails['status'] ?? 'Order Status',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Order Info Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Order ID', '#${orderDetails['id']?.toString() ?? ''}'),
                _buildDetailRow('Date', _formatDateTime(orderDetails['created_at'] ?? '')),
                _buildDetailRow('Status', _getStatusText(orderDetails['status'])),
                _buildDetailRow('Payment Method', orderDetails['payment_method'] ?? 'Cash on Delivery'),
              ],
            ),
          ),

          // Service Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Service', orderDetails['service_name'] ?? ''),
                _buildDetailRow('Shop', orderDetails['shop_name'] ?? ''),
                _buildDetailRow('Weight', '${orderDetails['kilo_amount']?.toString() ?? '0'} kg'),
              ],
            ),
          ),

          // Order Summary Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  'Subtotal',
                  '₱${(orderDetails['subtotal'] ?? 0.0).toStringAsFixed(2)}'
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Delivery Fee',
                  '₱${(orderDetails['delivery_fee'] ?? 0.0).toStringAsFixed(2)}'
                ),
                if ((orderDetails['voucher_discount'] ?? 0) > 0) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Voucher Discount',
                    '-₱${(orderDetails['voucher_discount'] ?? 0.0).toStringAsFixed(2)}',
                    isDiscount: true,
                  ),
                ],
                const Divider(height: 24),
                _buildSummaryRow(
                  'Total',
                  '₱${(orderDetails['total_amount'] ?? 0.0).toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    ),
  );
 }
}