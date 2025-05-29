import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminAccountInfo extends StatefulWidget {
  final int userId;
  final String token;
  final Map<String, dynamic> userData;

  const AdminAccountInfo({
    super.key,
    required this.userId,
    required this.token,
    required this.userData,
  });

  @override
  State<AdminAccountInfo> createState() => _AccountInfoState();
}

class _AccountInfoState extends State<AdminAccountInfo> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthdateController;
  late TextEditingController _genderController;
  late TextEditingController _zoneController;
  late TextEditingController _streetController;
  late TextEditingController _barangayController;
  late TextEditingController _buildingController;
  late Map<String, String> userDetails;
  final Color navyBlue = const Color(0xFF1A0066);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    String birthdate = widget.userData['birthdate'] ?? '';
    if (birthdate.isNotEmpty) {
      try {
        String cleanDate = birthdate.split('T')[0];
        DateTime date = DateTime.parse(cleanDate);
        birthdate = DateFormat('MM/dd/yyyy').format(date);
      } catch (e) {
        print('Error formatting birthdate: $e');
        birthdate = '';
      }
    }

    userDetails = {
      'Name': widget.userData['name'] ?? '',
      'Email': widget.userData['email'] ?? '',
      'Contact Number': widget.userData['contact_number'] ?? widget.userData['phone'] ?? '',
      'Birthdate': birthdate,
      'Gender': widget.userData['gender'] ?? '',
      'Zone': widget.userData['zone'] ?? '',
      'Street': widget.userData['street'] ?? '',
      'Barangay': widget.userData['barangay'] ?? '',
      'Building': widget.userData['building'] ?? ''
    };

    _nameController = TextEditingController(text: userDetails['Name']);
    _emailController = TextEditingController(text: userDetails['Email']);
    _phoneController = TextEditingController(text: userDetails['Contact Number']);
    _birthdateController = TextEditingController(text: userDetails['Birthdate']);
    _genderController = TextEditingController(text: userDetails['Gender']);
    _zoneController = TextEditingController(text: userDetails['Zone']);
    _streetController = TextEditingController(text: userDetails['Street']);
    _barangayController = TextEditingController(text: userDetails['Barangay']);
    _buildingController = TextEditingController(text: userDetails['Building']);
  }

  Future<void> _updateProfile() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    String? backendFormattedDate;
    if (_birthdateController.text.isNotEmpty) {
      try {
        final date = DateFormat('MM/dd/yyyy').parse(_birthdateController.text);
        backendFormattedDate = DateFormat('yyyy-MM-dd').format(date);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid date format')),
          );
        }
        return;
      }
    }

    final response = await http.put(
      Uri.parse('https://backend-production-5974.up.railway.app/update_user_details/${widget.userId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'contact_number': _phoneController.text,
        'birthdate': backendFormattedDate,
        'gender': _genderController.text,
        'zone': _zoneController.text,
        'street': _streetController.text,
        'barangay': _barangayController.text,
        'building': _buildingController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        widget.userData['name'] = _nameController.text;
        widget.userData['email'] = _emailController.text;
        widget.userData['contact_number'] = _phoneController.text;
        widget.userData['phone'] = _phoneController.text;
        widget.userData['birthdate'] = backendFormattedDate;
        widget.userData['gender'] = _genderController.text;
        widget.userData['zone'] = _zoneController.text;
        widget.userData['street'] = _streetController.text;
        widget.userData['barangay'] = _barangayController.text;
        widget.userData['building'] = _buildingController.text;
      });
      
      // Update local userDetails map
      userDetails = {
        'Name': _nameController.text,
        'Email': _emailController.text,
        'Contact Number': _phoneController.text,
        'Birthdate': _birthdateController.text,
        'Gender': _genderController.text,
        'Zone': _zoneController.text,
        'Street': _streetController.text,
        'Barangay': _barangayController.text,
        'Building': _buildingController.text,
      };

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Return updated data to previous screen
      Navigator.pop(context, widget.userData);
    } else {
      throw Exception('Failed to update profile');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate;
    try {
      initialDate = _birthdateController.text.isNotEmpty 
        ? DateFormat('MM/dd/yyyy').parse(_birthdateController.text)
        : DateTime.now();
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: navyBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _birthdateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Widget _buildEditField(String label, TextEditingController controller, {bool isDate = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
                  readOnly: isDate,
                  onTap: isDate ? () => _selectDate(context) : null,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontFamily: 'Inter',
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: isDate ? Icon(Icons.calendar_today, color: navyBlue) : Icon(Icons.edit, color: navyBlue),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: navyBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account Information',
          style: TextStyle(
            color: navyBlue,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEditField('Name', _nameController),
              _buildEditField('Email', _emailController),
              _buildEditField('Contact Number', _phoneController),
              _buildEditField('Birthdate', _birthdateController, isDate: true),
              _buildEditField('Gender', _genderController),
              _buildEditField('Zone', _zoneController),
              _buildEditField('Street', _streetController),
              _buildEditField('Barangay', _barangayController),
              _buildEditField('Building', _buildingController),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
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
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    _genderController.dispose();
    _zoneController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _buildingController.dispose();
    super.dispose();
  }
}