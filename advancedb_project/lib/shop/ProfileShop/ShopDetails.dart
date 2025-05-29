import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShopDetails extends StatefulWidget {
  final int userId;
  final String token;
  final Map<String, dynamic> shopData;

  const ShopDetails({
    super.key,
    required this.userId,
    required this.token,
    required this.shopData,
  });

  @override
  State<ShopDetails> createState() => _ShopDetailsState();
}

class _ShopDetailsState extends State<ShopDetails> {
  late final TextEditingController _shopNameController;
  late final TextEditingController _businessHoursController;
  late final TextEditingController _contactController;
  late final TextEditingController _shopIdController;
  late final TextEditingController _zoneController;
  late final TextEditingController _streetController;
  late final TextEditingController _barangayController;
  late final TextEditingController _buildingController;
  
  bool _isShopNameEditing = false;
  bool _isBusinessHoursEditing = false;
  bool _isContactEditing = false;
  
  // Added for map functionality
  LatLng? shopLatLng;
  bool isUpdatingLocation = false;
  String? shopAddress;

  @override
  void initState() {
    super.initState();
    _shopIdController = TextEditingController(
      text: widget.shopData['id']?.toString() ?? ''
    );
    _shopNameController = TextEditingController(
      text: widget.shopData['shop_name'] ?? ''
    );
    _businessHoursController = TextEditingController(
      text: '${widget.shopData['opening_time'] ?? ''} - ${widget.shopData['closing_time'] ?? ''}'
    );
    _contactController = TextEditingController(
      text: widget.shopData['contact_number'] ?? ''
    );
    _zoneController = TextEditingController(
      text: widget.shopData['zone'] ?? ''
    );
    _streetController = TextEditingController(
      text: widget.shopData['street'] ?? ''
    );
    _barangayController = TextEditingController(
      text: widget.shopData['barangay'] ?? ''
    );
    _buildingController = TextEditingController(
      text: widget.shopData['building'] ?? ''
    );

    // Initialize map location
    shopLatLng = (widget.shopData['latitude'] != null && widget.shopData['longitude'] != null)
        ? LatLng(
            double.parse(widget.shopData['latitude'].toString()),
            double.parse(widget.shopData['longitude'].toString())
          )
        : null;
    shopAddress = widget.shopData['address'];
  }

  Future<void> _updateShopLocation(LatLng latlng) async {
    try {
      setState(() { isUpdatingLocation = true; });
      List<Placemark> placemarks = await placemarkFromCoordinates(latlng.latitude, latlng.longitude);
      String address = 'Unknown location';
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        address = [
          placemark.name,
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.subAdministrativeArea,
          placemark.administrativeArea,
          placemark.country
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
      await _saveShopLocationToBackend(latlng, address);
      setState(() {
        shopLatLng = latlng;
        shopAddress = address;
        isUpdatingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop location updated!')),
      );
    } catch (e) {
      setState(() { isUpdatingLocation = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update location: $e')),
      );
    }
  }

  Future<void> _saveShopLocationToBackend(LatLng latlng, String address) async {
    final response = await http.put(
      Uri.parse('https://backend-production-5974.up.railway.app/update_shop_location/${widget.shopData['id']}'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'latitude': latlng.latitude,
        'longitude': latlng.longitude,
        'address': address,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update shop location');
    }
  }

  Future<void> _saveAllChanges() async {
  try {
    // Validate business hours format
    final times = _businessHoursController.text.split(' - ');
    if (times.length != 2) {
      throw Exception('Invalid business hours format. Please use format: HH:MM - HH:MM');
    }

    final updateData = {
      'shop_name': _shopNameController.text,
      'contact_number': _contactController.text,
      'opening_time': times[0].trim(),
      'closing_time': times[1].trim(),
    };

    print('Sending update data: $updateData'); // Debug print

    final response = await http.put(
      Uri.parse('https://backend-production-5974.up.railway.app/update_shop/${widget.shopData['id']}'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updateData),
    );

    print('Response status: ${response.statusCode}'); // Debug print
    print('Response body: ${response.body}'); // Debug print

    final responseData = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      setState(() {
        widget.shopData['shop_name'] = _shopNameController.text;
        widget.shopData['contact_number'] = _contactController.text;
        widget.shopData['opening_time'] = times[0].trim();
        widget.shopData['closing_time'] = times[1].trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop details updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Return updated data to previous screen
      Navigator.pop(context, widget.shopData);
    } else {
      throw Exception(responseData['message'] ?? 'Failed to update shop details');
    }
  } catch (e) {
    print('Error saving changes: $e'); // Debug print
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Widget _buildEditableField(String label, TextEditingController controller, bool isEditing, Function() onEditPress, {bool isEditable = true}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A0066),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: isEditable,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (isEditable)
              GestureDetector(
                onTap: onEditPress,
                child: Icon(
                  Icons.edit,
                  color: isEditing ? const Color(0xFF1A0066) : Colors.grey[400],
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6E0FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A0066)),
          onPressed: () {
            // Return the updated shop data to the previous screen
            Navigator.pop(context, {
              ...widget.shopData,
              'shop_name': _shopNameController.text,
              'contact_number': _contactController.text,
              'opening_time': _businessHoursController.text.split(' - ')[0],
              'closing_time': _businessHoursController.text.split(' - ')[1],
            });
          },
        ),
        title: const Text(
          'Shop Details',
          style: TextStyle(
            color: Color(0xFF1A0066),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Existing map section
            const Text(
              'Shop Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A0066),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    center: shopLatLng ?? const LatLng(13.6248, 123.1875),
                    zoom: 16,
                    onTap: (tapPosition, latlng) => _updateShopLocation(latlng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.labaride',
                    ),
                    if (shopLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: shopLatLng!,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (isUpdatingLocation)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(color: Color(0xFF1A0066)),
              ),
            if (shopAddress != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Current Address: $shopAddress',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            // Shop Details Section
          _buildEditableField(
          'Shop ID',
          _shopIdController,
          false,
          () {},
          isEditable: false,
          ),
          const SizedBox(height: 16),
          _buildEditableField(
            'Shop Name',
            _shopNameController,
            _isShopNameEditing,
            () => setState(() => _isShopNameEditing = !_isShopNameEditing),
          ),
          const SizedBox(height: 16),
          _buildEditableField(
            'Business Hours',
            _businessHoursController,
            _isBusinessHoursEditing,
            () => setState(() => _isBusinessHoursEditing = !_isBusinessHoursEditing),
          ),
          const SizedBox(height: 16),
          _buildEditableField(
            'Contact',
            _contactController,
            _isContactEditing,
            () => setState(() => _isContactEditing = !_isContactEditing),
          ),
          // Read-only address fields
          const SizedBox(height: 16),
          _buildEditableField(
            'Zone',
            _zoneController,
            false,
            () {},
            isEditable: false,
          ),
          const SizedBox(height: 16),
          _buildEditableField(
            'Street',
            _streetController,
            false,
            () {},
            isEditable: false,
          ),
          const SizedBox(height: 16),
          _buildEditableField(
            'Barangay',
            _barangayController,
            false,
            () {},
            isEditable: false,
          ),
          const SizedBox(height: 16),
          _buildEditableField(
            'Building',
            _buildingController,
            false,
            () {},
            isEditable: false,
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _saveAllChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A0066),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save All Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  void dispose() {
    _shopIdController.dispose();
    _shopNameController.dispose();
    _businessHoursController.dispose();
    _contactController.dispose();
    _zoneController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _buildingController.dispose();
    super.dispose();
  }
}