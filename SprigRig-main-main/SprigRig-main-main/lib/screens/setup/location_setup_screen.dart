// lib/screens/setup/location_setup_screen.dart
import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final PageController _pageController = PageController();
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _currentPage = 0;
  bool _isAutoDetecting = false;
  bool _hasLocationPermission = false;
  
  // Location data
  double? _latitude;
  double? _longitude;
  String? _timezone;
  String? _locationName;
  
  // Manual entry controllers
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  
  // Timezone options (simplified list - in production, use full timezone database)
  final List<Map<String, String>> _timezoneOptions = [
    {'name': 'Eastern Time', 'value': 'America/New_York'},
    {'name': 'Central Time', 'value': 'America/Chicago'},
    {'name': 'Mountain Time', 'value': 'America/Denver'},
    {'name': 'Pacific Time', 'value': 'America/Los_Angeles'},
    {'name': 'Alaska Time', 'value': 'America/Anchorage'},
    {'name': 'Hawaii Time', 'value': 'Pacific/Honolulu'},
    {'name': 'GMT', 'value': 'GMT'},
    {'name': 'Central European Time', 'value': 'Europe/Berlin'},
    {'name': 'Japan Time', 'value': 'Asia/Tokyo'},
    {'name': 'Australian Eastern Time', 'value': 'Australia/Sydney'},
  ];
  
  String? _selectedTimezone;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveLocationAndContinue();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _autoDetectLocation() async {
    setState(() {
      _isAutoDetecting = true;
    });

    try {
      // TODO: Implement actual GPS location detection
      // For now, simulate detection after delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock location data (San Francisco)
      setState(() {
        _latitude = 37.7749;
        _longitude = -122.4194;
        _timezone = 'America/Los_Angeles';
        _locationName = 'San Francisco, CA';
        _selectedTimezone = 'America/Los_Angeles';
        _hasLocationPermission = true;
        _isAutoDetecting = false;
      });

      // Auto-advance to review page
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _pageController.animateToPage(
            2,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });

    } catch (e) {
      setState(() {
        _isAutoDetecting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to detect location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _useManualEntry() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool get _isManualEntryValid {
    if (_latController.text.isEmpty || _lngController.text.isEmpty) {
      return false;
    }
    
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    
    if (lat == null || lng == null) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    if (_selectedTimezone == null) return false;
    
    return true;
  }

  void _validateManualEntry() {
    if (_isManualEntryValid) {
      setState(() {
        _latitude = double.parse(_latController.text);
        _longitude = double.parse(_lngController.text);
        _timezone = _selectedTimezone;
        _locationName = _locationNameController.text.isNotEmpty 
            ? _locationNameController.text 
            : 'Custom Location';
      });
      
      _pageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveLocationAndContinue() async {
    if (_latitude == null || _longitude == null || _timezone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure location first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Save location settings to database
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _db.database.then((db) => db.insert('location_settings', {
        'latitude': _latitude,
        'longitude': _longitude,
        'timezone': _timezone,
        'location_name': _locationName,
        'created_at': now,
        'updated_at': now,
      }));

      if (mounted) {
        // Navigate to grow method selection
        Navigator.pushNamed(context, '/setup/grow-method');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // slate-900
              Color(0xFF1E3A8A), // blue-900
              Color(0xFF1E293B), // slate-800
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildLocationMethodPage(),
                      _buildManualEntryPage(),
                      _buildReviewPage(),
                    ],
                  ),
                ),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                IconButton(
                  onPressed: _previousPage,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              const Expanded(
                child: Text(
                  'Location Setup',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Critical for astral scheduling and sunrise/sunset automation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade300,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index <= _currentPage ? Colors.green : Colors.grey.shade600,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMethodPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          
          // GPS Auto-detect option
          _buildLocationOption(
            icon: Icons.my_location,
            title: 'Auto-Detect Location',
            subtitle: 'Use GPS to automatically detect your coordinates',
            isRecommended: true,
            onTap: _autoDetectLocation,
            isLoading: _isAutoDetecting,
          ),
          
          const SizedBox(height: 20),
          
          // Manual entry option
          _buildLocationOption(
            icon: Icons.edit_location,
            title: 'Enter Manually',
            subtitle: 'Input coordinates and timezone manually',
            onTap: _useManualEntry,
          ),
          
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildLocationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isRecommended = false,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withValues(alpha:0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended ? Colors.green : Colors.grey.shade700,
            width: isRecommended ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isRecommended ? Colors.green.withValues(alpha:0.2) : Colors.grey.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading 
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  )
                : Icon(
                    icon, 
                    color: isRecommended ? Colors.green : Colors.grey.shade400,
                    size: 24,
                  ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Location Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Latitude input
          _buildLocationInput(
            controller: _latController,
            label: 'Latitude',
            hint: 'e.g., 37.7749',
            helperText: 'Range: -90 to 90',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Longitude input
          _buildLocationInput(
            controller: _lngController,
            label: 'Longitude',
            hint: 'e.g., -122.4194',
            helperText: 'Range: -180 to 180',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Timezone selection
          _buildTimezoneDropdown(),
          
          const SizedBox(height: 16),
          
          // Optional location name
          _buildLocationInput(
            controller: _locationNameController,
            label: 'Location Name (Optional)',
            hint: 'e.g., My Garden',
            helperText: 'For your reference',
          ),
          
          const Spacer(),
          
          // Validate button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isManualEntryValid ? _validateManualEntry : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Validate Location'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? helperText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        VirtualKeyboardTextField(
          controller: controller,
          label: label,
          keyboardType: keyboardType ?? TextInputType.text,
          hintText: hint,
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildTimezoneDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timezone',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withValues(alpha:0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedTimezone != null ? Colors.green : Colors.transparent,
              width: _selectedTimezone != null ? 2 : 0,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTimezone,
              hint: Text(
                'Select timezone',
                style: TextStyle(color: Colors.grey.shade500),
              ),
              isExpanded: true,
              dropdownColor: Colors.grey.shade800,
              style: const TextStyle(color: Colors.white),
              items: _timezoneOptions.map((timezone) {
                return DropdownMenuItem<String>(
                  value: timezone['value'],
                  child: Text(timezone['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTimezone = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Location summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withValues(alpha:0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      _locationName ?? 'Location Configured',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLocationDetail('Latitude', _latitude?.toStringAsFixed(4) ?? ''),
                _buildLocationDetail('Longitude', _longitude?.toStringAsFixed(4) ?? ''),
                _buildLocationDetail('Timezone', _timezone ?? ''),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Astral info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withValues(alpha:0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.orange, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Astral Scheduling Ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'SprigRig will now calculate sunrise and sunset times for your location to enable intelligent lighting schedules.',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLocationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentPage == 2 
                ? (_latitude != null ? _saveLocationAndContinue : null)
                : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_currentPage == 2 ? 'Continue Setup' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}