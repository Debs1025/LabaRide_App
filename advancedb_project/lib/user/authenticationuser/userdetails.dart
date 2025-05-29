import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signupcomplete.dart';
import '../../shop/AuthenticationShop/registershop.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class UserDetailsScreen extends StatefulWidget {
  final int userId;
  final String token;

  const UserDetailsScreen({
    super.key,
    required this.userId,
    this.token = '', 
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  bool _isLoading = false;
  bool _wantToCreateShop = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  String? selectedGender;
  LatLng? selectedLatLng;
  MapController mapController = MapController();
  String? selectedAddress;
  bool isSelectingLocation = false;

  @override
  void initState() {
    super.initState();
    selectedLatLng = const LatLng(13.6217, 123.1948);
    _setDefaultAddress();
  }
  Widget _buildMapSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Pinpoint Your Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1F39),
              fontFamily: 'Inter',
            ),
          ),
          ElevatedButton.icon(
            onPressed: _useCurrentLocation,
            icon: Icon(
              isSelectingLocation ? Icons.location_on : Icons.edit_location,
              color: Colors.white,
            ),
            label: Text(
              isSelectingLocation ? 'Cancel Pinpoint' : 'Use Current Location',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF375DFB),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        height: 200,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: const LatLng(13.6217, 123.1948),
                  initialZoom: 15.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  onTap: isSelectingLocation ? _handleMapTap : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  if (selectedLatLng != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLatLng!,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (isSelectingLocation)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Tap on the map to select your location',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (selectedAddress != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF1A0066)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedAddress!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
  void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Future<void> _useCurrentLocation() async {
  if (isSelectingLocation) {
    setState(() {
      isSelectingLocation = false;
      _setDefaultAddress();
    });
    return;
  }

  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are required.');
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );

    setState(() {
      selectedLatLng = LatLng(position.latitude, position.longitude);
      isSelectingLocation = true;
    });
    
    mapController.move(selectedLatLng!, 15.0);
    await _getAddressFromCoordinates(selectedLatLng!);
    
  } catch (e) {
    print('Error getting location: $e');
    _handleGeolocationError();
  }
}

void _handleGeolocationError() {
  _showError('Could not get current location. Using default location.');
  setState(() {
    selectedLatLng = const LatLng(13.6217, 123.1948);
    isSelectingLocation = true;
  });
  mapController.move(selectedLatLng!, 15.0);
  _setDefaultAddress();
}

void _handleMapTap(TapPosition tapPosition, LatLng point) async {
  if (!isSelectingLocation) return;
  setState(() => selectedLatLng = point);
  await _getAddressFromCoordinates(point);
}
  Widget _buildShopOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF375DFB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.store_outlined,
                color: Color(0xFF375DFB),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Want to create a laundry shop?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF375DFB),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Switch(
                value: _wantToCreateShop,
                onChanged: (value) => setState(() => _wantToCreateShop = value),
                activeColor: const Color(0xFF375DFB),
              ),
            ],
          ),
          if (_wantToCreateShop) ...[
            const SizedBox(height: 8),
            const Text(
              'You\'ll be guided to set up your shop after registration',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
    // Add debug prints
    print('Debug - Token being sent: ${widget.token}');
    print('Debug - User ID: ${widget.userId}');

    final response = await http.put(
      Uri.parse('https://backend-production-5974.up.railway.app/update_user_details/${widget.userId}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json', 
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'phone': _phoneController.text.trim(),
        'birthdate': _birthdateController.text,
        'gender': selectedGender,
        'zone': _zoneController.text.trim(),
        'street': _streetController.text.trim(),
        'barangay': _barangayController.text.trim(),
        'building': _buildingController.text.trim(),
      }),
    );

    print('Debug - Response Status: ${response.statusCode}');
    print('Debug - Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        if (_wantToCreateShop) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterShop(
                userId: widget.userId,
                token: widget.token,
              ),
            ),
          );
        } else {
          // Navigate to SignUpCompleteScreen first
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SignUpCompleteScreen(),
            ),
          );
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update user details');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _setDefaultAddress() {
    final defaultAddress = {
      'zone': '1',
      'street': 'Magsaysay Avenue',
      'barangay': 'Peñafrancia',
      'building': '',
    };
    
    setState(() {
      selectedAddress = _formatAddress(defaultAddress);
      _zoneController.text = defaultAddress['zone']!;
      _streetController.text = defaultAddress['street']!;
      _barangayController.text = defaultAddress['barangay']!;
      _buildingController.text = defaultAddress['building']!;
    });
  }
  String _formatAddress(Map<String, dynamic> address) {
  List<String> parts = [];
  
  String zone = (address['zone']?.toString() ?? '1').trim();
  parts.add('Zone $zone');
  
  String street = (address['street']?.toString() ?? '').trim();
  if (street.isNotEmpty) {
    parts.add(street);
  }
  
  String barangay = (address['barangay']?.toString() ?? '').trim();
  if (barangay.isNotEmpty) {
    parts.add(barangay);
  }
  
  String? building = address['building']?.toString();
  if (building != null && building.trim().isNotEmpty) {
    parts.add(building.trim());
  }
  
  return parts.join(', ');
}

  Future<void> _getAddressFromCoordinates(LatLng coordinates) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${coordinates.latitude}&lon=${coordinates.longitude}&addressdetails=1&accept-language=en'
      ),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'LabaRide App'
      }
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final address = data['address'];

      String street = address['road'] ?? 
                     address['street'] ?? 
                     'Magsaysay Avenue';
      
      String barangay = address['suburb'] ?? 
                       address['village'] ?? 
                       'Peñafrancia';

      Map<String, dynamic> addressComponents = {
        'zone': '1',
        'street': street.trim(),
        'barangay': barangay.trim(),
        'building': '',
      };

      setState(() {
        selectedAddress = _formatAddress(addressComponents);
        _zoneController.text = addressComponents['zone']!;
        _streetController.text = addressComponents['street']!;
        _barangayController.text = addressComponents['barangay']!;
        _buildingController.text = addressComponents['building']!;
      });
    }
  } catch (e) {
    print('Error in _getAddressFromCoordinates: $e');
    _setDefaultAddress();
    _showError('Could not get address details.');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            'assets/blacklogo.png',
                            height: 60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Set up your details',
                          style: TextStyle(
                            fontSize: 33,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A0066),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F1F39),
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildLabeledField(
                        'Contact Number',
                        'Enter contact number',
                        controller: _phoneController,
                        prefix: '+63',
                      ),
                      
                      _buildLabeledField(
                        'Birthdate',
                        'MM/DD/YYYY',
                        controller: _birthdateController,
                        suffixIcon: Icons.calendar_today,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),

                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdownField(),
                      const SizedBox(height: 24),
                      const Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F1F39),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMapSection(),
                    const SizedBox(height: 16),

                    // Address fields
                    _buildLabeledField('Zone Name', 'Enter zone', controller: _zoneController),
                    _buildLabeledField('Street Name', 'Enter street name', controller: _streetController),
                    _buildLabeledField('Barangay Name', 'Enter barangay name', controller: _barangayController),
                    _buildLabeledField('Building Name', 'Enter building name', controller: _buildingController),
                      
                      const SizedBox(height: 24),
                      _buildShopOption(),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF375DFB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _wantToCreateShop ? 'Next: Shop Setup' : 'Complete Registration',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
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
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, {
    String? prefix,
    IconData? suffixIcon,
    TextEditingController? controller,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixText: prefix,
        prefixStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontFamily: 'Inter',
        ),
        suffixIcon: suffixIcon != null 
            ? Icon(suffixIcon, color: Colors.grey[400], size: 20)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedGender,
          hint: Text(
            'Select gender',
            style: TextStyle(color: Colors.grey[400]),
          ),
          items: ['Male', 'Female', 'Other']
              .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              })
              .toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedGender = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLabeledField(
    String label,
    String hint, {
    TextEditingController? controller,
    String? prefix,
    IconData? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          _buildInputField(
            hint,
            controller: controller,
            prefix: prefix,
            suffixIcon: suffixIcon,
            readOnly: readOnly,
            onTap: onTap,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _birthdateController.dispose();
    _zoneController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _buildingController.dispose();
    mapController.dispose(); // Add this line
    super.dispose();
  }
}